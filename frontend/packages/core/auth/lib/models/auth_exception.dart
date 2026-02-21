/// 認証関連の例外クラス
class AuthException implements Exception {
  const AuthException({
    required this.message,
    this.code,
    this.originalException,
  });

  /// Supabase AuthExceptionから変換
  factory AuthException.fromSupabaseAuth(dynamic error) {
    return AuthException(
      message: error.message ?? 'Unknown authentication error',
      code: error.statusCode?.toString(),
      originalException: error,
    );
  }

  /// 一般的なエラーから変換
  factory AuthException.fromError(dynamic error) {
    if (error is AuthException) {
      return error;
    }
    return AuthException(message: error.toString(), originalException: error);
  }

  final String message;
  final String? code;
  final dynamic originalException;

  @override
  String toString() {
    if (code != null) {
      return 'AuthException[$code]: $message';
    }
    return 'AuthException: $message';
  }
}

/// 事前定義された認証例外

class InvalidEmailException extends AuthException {
  const InvalidEmailException()
    : super(message: 'Invalid email address', code: 'invalid_email');
}

class InvalidOtpException extends AuthException {
  const InvalidOtpException()
    : super(message: 'Invalid or expired OTP code', code: 'invalid_otp');
}

class SessionExpiredException extends AuthException {
  const SessionExpiredException()
    : super(message: 'Session has expired', code: 'session_expired');
}

class NetworkException extends AuthException {
  const NetworkException()
    : super(
        message: 'Network error occurred. Please check your connection',
        code: 'network_error',
      );
}

class UnknownAuthException extends AuthException {
  const UnknownAuthException()
    : super(message: 'An unknown error occurred', code: 'unknown');
}
