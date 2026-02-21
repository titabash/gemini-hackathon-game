import 'package:freezed_annotation/freezed_annotation.dart';
import 'auth_exception.dart';

part 'auth_result.freezed.dart';

/// 認証処理の結果を表すResult型
@freezed
class AuthResult<T> with _$AuthResult<T> {
  const factory AuthResult.success(T data) = _Success<T>;
  const factory AuthResult.failure(AuthException exception) = _Failure<T>;

  const AuthResult._();

  /// 成功かどうか
  bool get isSuccess => this is _Success<T>;

  /// 失敗かどうか
  bool get isFailure => this is _Failure<T>;

  /// データを取得（失敗時はnull）
  T? get dataOrNull => when(success: (data) => data, failure: (_) => null);

  /// エラーを取得（成功時はnull）
  AuthException? get exceptionOrNull =>
      when(success: (_) => null, failure: (exception) => exception);

  /// データを取得（失敗時は例外をスロー）
  T get data =>
      when(success: (data) => data, failure: (exception) => throw exception);
}
