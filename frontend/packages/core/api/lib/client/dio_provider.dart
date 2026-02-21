import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/logging_interceptor.dart';

part 'dio_provider.g.dart';

/// Dio クライアントを提供するProvider
///
/// 認証トークンの自動付与とロギングを設定
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // 認証インターセプター
  dio.interceptors.add(AuthInterceptor(ref));

  // ロギングインターセプター（開発時のみ）
  dio.interceptors.add(LoggingInterceptor());

  return dio;
}

/// Edge Functions用のDioクライアント
@Riverpod(keepAlive: true)
Dio edgeFunctionsDio(Ref ref) {
  const baseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );

  final baseDio = ref.watch(dioProvider);

  return baseDio..options.baseUrl = '$baseUrl/functions/v1';
}

/// Python Backend用のDioクライアント
@Riverpod(keepAlive: true)
Dio backendDio(Ref ref) {
  const baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:4040',
  );

  final baseDio = ref.watch(dioProvider);

  return baseDio..options.baseUrl = baseUrl;
}
