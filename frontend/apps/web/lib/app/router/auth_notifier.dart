import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core_auth/core_auth.dart';

part 'auth_notifier.g.dart';

/// GoRouterのrefreshListenableとして使用するための
/// 認証状態変更を通知するChangeNotifier
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(this._isAuthenticated);

  bool _isAuthenticated;

  bool get isAuthenticated => _isAuthenticated;

  void updateAuthState(bool isAuthenticated) {
    if (_isAuthenticated != isAuthenticated) {
      _isAuthenticated = isAuthenticated;
      notifyListeners();
    }
  }
}

/// AuthStateNotifierのProvider
@Riverpod(keepAlive: true)
AuthStateNotifier authStateNotifier(Ref ref) {
  final authState = ref.watch(authProvider);
  final notifier = AuthStateNotifier(authState.isAuthenticated);

  // 認証状態の変更を監視
  ref.listen(authProvider, (previous, next) {
    notifier.updateAuthState(next.isAuthenticated);
  });

  ref.onDispose(notifier.dispose);
  return notifier;
}
