import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../pages/home/ui/home_page.dart';
import '../../pages/auth/ui/login_page.dart';
import '../../pages/auth/ui/verify_otp_page.dart';
import '../../pages/dashboard/ui/dashboard_page.dart';
import '../../pages/game/ui/game_page.dart';
import 'auth_notifier.dart';

part 'app_router.g.dart';

/// GoRouterのProvider
///
/// 認証状態に基づいてルーティングを制御
@riverpod
GoRouter appRouter(Ref ref) {
  final authNotifier = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authNotifier.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isVerifyRoute = state.matchedLocation == '/verify-otp';

      // 認証済みでログイン画面にいる場合はホームにリダイレクト
      if (isAuthenticated && (isLoginRoute || isVerifyRoute)) {
        return '/';
      }

      // 未認証で保護されたルートにアクセスしようとしている場合
      if (!isAuthenticated && state.matchedLocation.startsWith('/dashboard')) {
        return '/login';
      }

      return null; // リダイレクトなし
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
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
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/game',
        name: 'game',
        builder: (context, state) => const GamePage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
}
