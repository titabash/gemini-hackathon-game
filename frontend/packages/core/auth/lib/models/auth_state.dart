import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.freezed.dart';

/// 認証状態を表すモデル
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.authenticated({
    required User user,
    required Session session,
  }) = _Authenticated;

  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// セッションから認証状態を作成
  factory AuthState.fromSession(Session? session) {
    if (session == null) {
      return const AuthState.unauthenticated();
    }
    return AuthState.authenticated(user: session.user, session: session);
  }

  const AuthState._();

  /// 認証済みかどうか
  bool get isAuthenticated => this is _Authenticated;

  /// ユーザー情報を取得
  User? get user => switch (this) {
    _Authenticated(user: final user) => user,
    _Unauthenticated() => null,
  };

  /// セッション情報を取得
  Session? get session => switch (this) {
    _Authenticated(session: final session) => session,
    _Unauthenticated() => null,
  };

  /// アクセストークンを取得
  String? get accessToken => session?.accessToken;

  /// リフレッシュトークンを取得
  String? get refreshToken => session?.refreshToken;
}
