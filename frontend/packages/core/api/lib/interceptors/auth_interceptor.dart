import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import 'package:core_auth/core_auth.dart';

/// 認証トークンを自動付与するインターセプター
///
/// 参考プロジェクトのBackendApiClientと同様に
/// アクセストークンをAuthorizationヘッダーに設定
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.ref);

  final Ref ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // アクセストークンを取得
    final accessToken = ref.read(accessTokenProvider);

    // トークンがあればAuthorizationヘッダーに設定
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401エラー（未認証）の場合、認証状態をリセット
    if (err.response?.statusCode == 401) {
      ref.read(authProvider.notifier).reset();
    }

    super.onError(err, handler);
  }
}
