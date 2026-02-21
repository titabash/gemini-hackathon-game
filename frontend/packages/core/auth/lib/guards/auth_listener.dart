import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthState, AuthException;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../providers/auth_provider.dart';
import '../providers/supabase_client_provider.dart';

/// 認証状態の変更をリアルタイムで監視するWidget
///
/// 参考プロジェクトのAuthProviderに相当
/// - アプリのルートに配置
/// - Supabaseの認証状態変更を監視
/// - 認証状態をRiverpod Providerに反映
class AuthListener extends ConsumerStatefulWidget {
  const AuthListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AuthListener> createState() => _AuthListenerState();
}

class _AuthListenerState extends ConsumerState<AuthListener> {
  StreamSubscription<supabase.AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authClient = ref.read(authClientProvider);

    // ビルド完了後に初回セッションを設定
    Future(() {
      final session = authClient.currentSession;
      ref.read(authProvider.notifier).setAuth(session);
    });

    // 認証状態変更の監視
    _authSubscription = authClient.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedOut) {
        ref.read(authProvider.notifier).reset();
      } else if (event == AuthChangeEvent.tokenRefreshed && session == null) {
        ref.read(authProvider.notifier).reset();
      } else if (session != null) {
        ref.read(authProvider.notifier).setAuth(session);
      } else {
        ref.read(authProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
