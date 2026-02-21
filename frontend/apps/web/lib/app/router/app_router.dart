import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../pages/auth/ui/login_page.dart';
import '../../pages/auth/ui/verify_otp_page.dart';
import '../../pages/game/ui/game_page.dart';
import '../../pages/game_detail/ui/game_detail_page.dart';
import '../../pages/game_list/ui/game_list_page.dart';
import '../../pages/onboarding/ui/onboarding_page.dart';
import 'auth_notifier.dart';

part 'app_router.g.dart';

/// GoRouterのProvider
///
/// 認証状態・オンボーディング状態に基づいてルーティングを制御
@riverpod
GoRouter appRouter(Ref ref) {
  final authNotifier = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authNotifier.isAuthenticated;
      final isOnboardingNeeded = authNotifier.needsOnboarding;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/verify-otp';
      final isOnboardingRoute = location == '/onboarding';

      // 未認証で保護されたルートにアクセスしようとしている場合
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // 認証済みでauth画面にいる場合
      if (isAuthenticated && isAuthRoute) {
        return isOnboardingNeeded ? '/onboarding' : '/';
      }

      // 認証済み + オンボーディング未完了 + オンボーディング画面以外
      if (isAuthenticated && isOnboardingNeeded && !isOnboardingRoute) {
        return '/onboarding';
      }

      // 認証済み + オンボーディング完了 + オンボーディング画面にいる場合
      if (isAuthenticated && !isOnboardingNeeded && isOnboardingRoute) {
        return '/';
      }

      return null; // リダイレクトなし
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const GameListPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verifyOtp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyOtpPage(email: email);
        },
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/scenarios/:id',
        name: 'scenarioDetail',
        builder: (context, state) {
          final scenarioId = state.pathParameters['id']!;
          return GameDetailPage(scenarioId: scenarioId);
        },
      ),
      GoRoute(
        path: '/game/:sessionId',
        name: 'game',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return GamePage(sessionId: sessionId);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
}
