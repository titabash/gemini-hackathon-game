import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core_auth/core_auth.dart';
import '../../features/onboarding/model/onboarding_status_provider.dart';

part 'auth_notifier.g.dart';

/// GoRouterのrefreshListenableとして使用するための
/// 認証状態変更・オンボーディング状態変更を通知するChangeNotifier
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier({
    required bool isAuthenticated,
    required bool needsOnboarding,
  }) : _isAuthenticated = isAuthenticated,
       _needsOnboarding = needsOnboarding;

  bool _isAuthenticated;
  bool _needsOnboarding;

  bool get isAuthenticated => _isAuthenticated;
  bool get needsOnboarding => _needsOnboarding;

  void updateAuthState(bool isAuthenticated) {
    if (_isAuthenticated != isAuthenticated) {
      _isAuthenticated = isAuthenticated;
      notifyListeners();
    }
  }

  void updateOnboardingState(bool needsOnboarding) {
    if (_needsOnboarding != needsOnboarding) {
      _needsOnboarding = needsOnboarding;
      notifyListeners();
    }
  }
}

/// AuthStateNotifierのProvider
@Riverpod(keepAlive: true)
AuthStateNotifier authState(Ref ref) {
  final authState = ref.watch(authProvider);
  final onboardingAsync = ref.watch(needsOnboardingProvider);
  final needsOnboarding = onboardingAsync.value ?? false;

  final notifier = AuthStateNotifier(
    isAuthenticated: authState.isAuthenticated,
    needsOnboarding: needsOnboarding,
  );

  // 認証状態の変更を監視
  ref.listen(authProvider, (previous, next) {
    notifier.updateAuthState(next.isAuthenticated);
  });

  // オンボーディング状態の変更を監視
  ref.listen(needsOnboardingProvider, (previous, next) {
    notifier.updateOnboardingState(next.value ?? false);
  });

  ref.onDispose(notifier.dispose);
  return notifier;
}
