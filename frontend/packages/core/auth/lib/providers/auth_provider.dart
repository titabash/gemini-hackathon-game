import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../models/auth_state.dart';
import 'supabase_client_provider.dart';

part 'auth_provider.g.dart';

/// 認証状態を管理するNotifierProvider
///
/// 参考プロジェクトのZustandストアに相当
/// - セッション情報を保持
/// - 認証状態の更新
/// - リセット機能
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AuthState build() {
    // 初期状態は未認証
    return const AuthState.unauthenticated();
  }

  /// セッションから認証状態を設定
  ///
  /// 参考プロジェクトのsetAuth()に相当
  void setAuth(Session? session) {
    state = AuthState.fromSession(session);
  }

  /// 認証状態をリセット
  ///
  /// 参考プロジェクトのreset()に相当
  void reset() {
    state = const AuthState.unauthenticated();
  }

  /// ログアウト処理
  Future<void> signOut() async {
    try {
      final authClient = ref.read(authClientProvider);
      await authClient.signOut();
      reset();
    } catch (e) {
      // エラーが発生してもリセット
      reset();
      rethrow;
    }
  }
}

/// 認証状態の便利なアクセサProvider

/// ユーザー情報を取得
@riverpod
User? currentUser(Ref ref) {
  return ref.watch(authProvider).user;
}

/// 認証済みかどうか
@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(authProvider).isAuthenticated;
}

/// アクセストークンを取得
@riverpod
String? accessToken(Ref ref) {
  return ref.watch(authProvider).accessToken;
}
