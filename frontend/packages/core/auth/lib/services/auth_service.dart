import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthState, AuthException;
import 'package:supabase_flutter/supabase_flutter.dart'
    as supabase
    show AuthException;
import '../models/auth_exception.dart';
import '../models/auth_result.dart';

/// 認証サービスクラス
///
/// Supabase Authの操作を抽象化
class AuthService {
  const AuthService(this._authClient);

  final GoTrueClient _authClient;

  /// OTPをメールで送信
  ///
  /// [email] 送信先のメールアドレス
  /// [shouldCreateUser] ユーザーが存在しない場合に作成するか（デフォルト: true）
  Future<AuthResult<void>> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {
    try {
      await _authClient.signInWithOtp(
        email: email,
        shouldCreateUser: shouldCreateUser,
      );
      return const AuthResult.success(null);
    } on supabase.AuthException catch (e) {
      return AuthResult.failure(AuthException.fromSupabaseAuth(e));
    } catch (e) {
      return AuthResult.failure(AuthException.fromError(e));
    }
  }

  /// OTPコードを検証してログイン
  ///
  /// [email] メールアドレス
  /// [token] 6桁のOTPコード
  Future<AuthResult<Session>> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _authClient.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      if (response.session == null) {
        return const AuthResult.failure(
          AuthException(
            message: 'Failed to create session',
            code: 'session_creation_failed',
          ),
        );
      }

      return AuthResult.success(response.session!);
    } on supabase.AuthException catch (e) {
      return AuthResult.failure(AuthException.fromSupabaseAuth(e));
    } catch (e) {
      return AuthResult.failure(AuthException.fromError(e));
    }
  }

  /// OTPを再送信
  ///
  /// [email] 送信先のメールアドレス
  Future<AuthResult<void>> resendOtp({required String email}) async {
    try {
      await _authClient.resend(type: OtpType.email, email: email);
      return const AuthResult.success(null);
    } on supabase.AuthException catch (e) {
      return AuthResult.failure(AuthException.fromSupabaseAuth(e));
    } catch (e) {
      return AuthResult.failure(AuthException.fromError(e));
    }
  }

  /// ログアウト
  Future<AuthResult<void>> signOut() async {
    try {
      await _authClient.signOut();
      return const AuthResult.success(null);
    } on supabase.AuthException catch (e) {
      return AuthResult.failure(AuthException.fromSupabaseAuth(e));
    } catch (e) {
      return AuthResult.failure(AuthException.fromError(e));
    }
  }

  /// 現在のセッションを取得
  Future<AuthResult<Session>> getSession() async {
    try {
      final response = _authClient.currentSession;

      if (response == null) {
        return const AuthResult.failure(
          AuthException(message: 'No active session', code: 'no_session'),
        );
      }

      return AuthResult.success(response);
    } on supabase.AuthException catch (e) {
      return AuthResult.failure(AuthException.fromSupabaseAuth(e));
    } catch (e) {
      return AuthResult.failure(AuthException.fromError(e));
    }
  }

  /// セッションをリフレッシュ
  Future<AuthResult<Session>> refreshSession() async {
    try {
      final response = await _authClient.refreshSession();

      if (response.session == null) {
        return const AuthResult.failure(
          AuthException(
            message: 'Failed to refresh session',
            code: 'refresh_failed',
          ),
        );
      }

      return AuthResult.success(response.session!);
    } on supabase.AuthException catch (e) {
      return AuthResult.failure(AuthException.fromSupabaseAuth(e));
    } catch (e) {
      return AuthResult.failure(AuthException.fromError(e));
    }
  }
}
