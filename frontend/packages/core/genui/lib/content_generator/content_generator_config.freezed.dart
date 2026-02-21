// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_generator_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContentGeneratorConfig {

/// The SSE endpoint URL for the genui chat API.
 String get serverUrl;/// Optional authorization token.
 String? get authToken;/// Additional headers to include in SSE requests.
 Map<String, String> get headers;
/// Create a copy of ContentGeneratorConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentGeneratorConfigCopyWith<ContentGeneratorConfig> get copyWith => _$ContentGeneratorConfigCopyWithImpl<ContentGeneratorConfig>(this as ContentGeneratorConfig, _$identity);

  /// Serializes this ContentGeneratorConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentGeneratorConfig&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.authToken, authToken) || other.authToken == authToken)&&const DeepCollectionEquality().equals(other.headers, headers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverUrl,authToken,const DeepCollectionEquality().hash(headers));

@override
String toString() {
  return 'ContentGeneratorConfig(serverUrl: $serverUrl, authToken: $authToken, headers: $headers)';
}


}

/// @nodoc
abstract mixin class $ContentGeneratorConfigCopyWith<$Res>  {
  factory $ContentGeneratorConfigCopyWith(ContentGeneratorConfig value, $Res Function(ContentGeneratorConfig) _then) = _$ContentGeneratorConfigCopyWithImpl;
@useResult
$Res call({
 String serverUrl, String? authToken, Map<String, String> headers
});




}
/// @nodoc
class _$ContentGeneratorConfigCopyWithImpl<$Res>
    implements $ContentGeneratorConfigCopyWith<$Res> {
  _$ContentGeneratorConfigCopyWithImpl(this._self, this._then);

  final ContentGeneratorConfig _self;
  final $Res Function(ContentGeneratorConfig) _then;

/// Create a copy of ContentGeneratorConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverUrl = null,Object? authToken = freezed,Object? headers = null,}) {
  return _then(_self.copyWith(
serverUrl: null == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String,authToken: freezed == authToken ? _self.authToken : authToken // ignore: cast_nullable_to_non_nullable
as String?,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentGeneratorConfig].
extension ContentGeneratorConfigPatterns on ContentGeneratorConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentGeneratorConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentGeneratorConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentGeneratorConfig value)  $default,){
final _that = this;
switch (_that) {
case _ContentGeneratorConfig():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentGeneratorConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ContentGeneratorConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serverUrl,  String? authToken,  Map<String, String> headers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentGeneratorConfig() when $default != null:
return $default(_that.serverUrl,_that.authToken,_that.headers);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serverUrl,  String? authToken,  Map<String, String> headers)  $default,) {final _that = this;
switch (_that) {
case _ContentGeneratorConfig():
return $default(_that.serverUrl,_that.authToken,_that.headers);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serverUrl,  String? authToken,  Map<String, String> headers)?  $default,) {final _that = this;
switch (_that) {
case _ContentGeneratorConfig() when $default != null:
return $default(_that.serverUrl,_that.authToken,_that.headers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContentGeneratorConfig implements ContentGeneratorConfig {
  const _ContentGeneratorConfig({required this.serverUrl, this.authToken, final  Map<String, String> headers = const {}}): _headers = headers;
  factory _ContentGeneratorConfig.fromJson(Map<String, dynamic> json) => _$ContentGeneratorConfigFromJson(json);

/// The SSE endpoint URL for the genui chat API.
@override final  String serverUrl;
/// Optional authorization token.
@override final  String? authToken;
/// Additional headers to include in SSE requests.
 final  Map<String, String> _headers;
/// Additional headers to include in SSE requests.
@override@JsonKey() Map<String, String> get headers {
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headers);
}


/// Create a copy of ContentGeneratorConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentGeneratorConfigCopyWith<_ContentGeneratorConfig> get copyWith => __$ContentGeneratorConfigCopyWithImpl<_ContentGeneratorConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContentGeneratorConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentGeneratorConfig&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.authToken, authToken) || other.authToken == authToken)&&const DeepCollectionEquality().equals(other._headers, _headers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverUrl,authToken,const DeepCollectionEquality().hash(_headers));

@override
String toString() {
  return 'ContentGeneratorConfig(serverUrl: $serverUrl, authToken: $authToken, headers: $headers)';
}


}

/// @nodoc
abstract mixin class _$ContentGeneratorConfigCopyWith<$Res> implements $ContentGeneratorConfigCopyWith<$Res> {
  factory _$ContentGeneratorConfigCopyWith(_ContentGeneratorConfig value, $Res Function(_ContentGeneratorConfig) _then) = __$ContentGeneratorConfigCopyWithImpl;
@override @useResult
$Res call({
 String serverUrl, String? authToken, Map<String, String> headers
});




}
/// @nodoc
class __$ContentGeneratorConfigCopyWithImpl<$Res>
    implements _$ContentGeneratorConfigCopyWith<$Res> {
  __$ContentGeneratorConfigCopyWithImpl(this._self, this._then);

  final _ContentGeneratorConfig _self;
  final $Res Function(_ContentGeneratorConfig) _then;

/// Create a copy of ContentGeneratorConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverUrl = null,Object? authToken = freezed,Object? headers = null,}) {
  return _then(_ContentGeneratorConfig(
serverUrl: null == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String,authToken: freezed == authToken ? _self.authToken : authToken // ignore: cast_nullable_to_non_nullable
as String?,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
