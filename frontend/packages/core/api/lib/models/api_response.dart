import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

/// 標準的なAPI レスポンス形式
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  const ApiResponse({this.data, this.error, this.message});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  final T? data;
  final String? error;
  final String? message;

  bool get isSuccess => error == null && data != null;
  bool get isFailure => error != null;
}
