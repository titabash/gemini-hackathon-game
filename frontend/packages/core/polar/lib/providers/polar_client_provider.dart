import 'package:core_utils/core_utils.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core_polar/clients/polar_api_client.dart';

part 'polar_client_provider.g.dart';

/// Backend API base URL provider
///
/// Override this provider in your app's initialization to set the correct backend URL.
///
/// @example
/// ```dart
/// ProviderScope(
///   overrides: [
///     backendBaseUrlProvider.overrideWithValue('https://api.example.com'),
///   ],
///   child: MyApp(),
/// )
/// ```
@riverpod
String backendBaseUrl(BackendBaseUrlRef ref) {
  // Default to Supabase Edge Functions for local development
  // Override this provider or use --dart-define for production:
  // flutter run --dart-define=POLAR_API_BASE_URL=https://your-project.supabase.co/functions/v1
  const envBaseUrl = String.fromEnvironment('POLAR_API_BASE_URL');
  if (envBaseUrl.isNotEmpty) {
    return envBaseUrl;
  }
  return 'http://localhost:54321/functions/v1';
}

/// Dio instance provider for Polar API client
@riverpod
Dio polarDio(PolarDioRef ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors for logging, authentication, etc.
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) {
        Logger.debug('[Polar API] $obj');
      },
    ),
  );

  return dio;
}

/// Polar API client provider
///
/// Provides a configured instance of [PolarApiClient] for making API requests.
@riverpod
PolarApiClient polarApiClient(PolarApiClientRef ref) {
  final dio = ref.watch(polarDioProvider);
  final baseUrl = ref.watch(backendBaseUrlProvider);

  return PolarApiClient(dio, baseUrl: baseUrl);
}
