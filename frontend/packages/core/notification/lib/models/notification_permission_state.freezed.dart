// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_permission_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationPermissionState {

/// パーミッションが許可されているか
 bool get areNotificationsEnabled;/// プッシュ通知が許可されているか
 bool get isPushDisabled;/// プッシュトークン（デバイストークン）
 String? get pushToken;/// OneSignal Player ID (Subscription ID)
 String? get subscriptionId;
/// Create a copy of NotificationPermissionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPermissionStateCopyWith<NotificationPermissionState> get copyWith => _$NotificationPermissionStateCopyWithImpl<NotificationPermissionState>(this as NotificationPermissionState, _$identity);

  /// Serializes this NotificationPermissionState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPermissionState&&(identical(other.areNotificationsEnabled, areNotificationsEnabled) || other.areNotificationsEnabled == areNotificationsEnabled)&&(identical(other.isPushDisabled, isPushDisabled) || other.isPushDisabled == isPushDisabled)&&(identical(other.pushToken, pushToken) || other.pushToken == pushToken)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,areNotificationsEnabled,isPushDisabled,pushToken,subscriptionId);

@override
String toString() {
  return 'NotificationPermissionState(areNotificationsEnabled: $areNotificationsEnabled, isPushDisabled: $isPushDisabled, pushToken: $pushToken, subscriptionId: $subscriptionId)';
}


}

/// @nodoc
abstract mixin class $NotificationPermissionStateCopyWith<$Res>  {
  factory $NotificationPermissionStateCopyWith(NotificationPermissionState value, $Res Function(NotificationPermissionState) _then) = _$NotificationPermissionStateCopyWithImpl;
@useResult
$Res call({
 bool areNotificationsEnabled, bool isPushDisabled, String? pushToken, String? subscriptionId
});




}
/// @nodoc
class _$NotificationPermissionStateCopyWithImpl<$Res>
    implements $NotificationPermissionStateCopyWith<$Res> {
  _$NotificationPermissionStateCopyWithImpl(this._self, this._then);

  final NotificationPermissionState _self;
  final $Res Function(NotificationPermissionState) _then;

/// Create a copy of NotificationPermissionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? areNotificationsEnabled = null,Object? isPushDisabled = null,Object? pushToken = freezed,Object? subscriptionId = freezed,}) {
  return _then(_self.copyWith(
areNotificationsEnabled: null == areNotificationsEnabled ? _self.areNotificationsEnabled : areNotificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,isPushDisabled: null == isPushDisabled ? _self.isPushDisabled : isPushDisabled // ignore: cast_nullable_to_non_nullable
as bool,pushToken: freezed == pushToken ? _self.pushToken : pushToken // ignore: cast_nullable_to_non_nullable
as String?,subscriptionId: freezed == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPermissionState].
extension NotificationPermissionStatePatterns on NotificationPermissionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPermissionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPermissionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPermissionState value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPermissionState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPermissionState value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPermissionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool areNotificationsEnabled,  bool isPushDisabled,  String? pushToken,  String? subscriptionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPermissionState() when $default != null:
return $default(_that.areNotificationsEnabled,_that.isPushDisabled,_that.pushToken,_that.subscriptionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool areNotificationsEnabled,  bool isPushDisabled,  String? pushToken,  String? subscriptionId)  $default,) {final _that = this;
switch (_that) {
case _NotificationPermissionState():
return $default(_that.areNotificationsEnabled,_that.isPushDisabled,_that.pushToken,_that.subscriptionId);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool areNotificationsEnabled,  bool isPushDisabled,  String? pushToken,  String? subscriptionId)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPermissionState() when $default != null:
return $default(_that.areNotificationsEnabled,_that.isPushDisabled,_that.pushToken,_that.subscriptionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPermissionState implements NotificationPermissionState {
  const _NotificationPermissionState({required this.areNotificationsEnabled, required this.isPushDisabled, this.pushToken, this.subscriptionId});
  factory _NotificationPermissionState.fromJson(Map<String, dynamic> json) => _$NotificationPermissionStateFromJson(json);

/// パーミッションが許可されているか
@override final  bool areNotificationsEnabled;
/// プッシュ通知が許可されているか
@override final  bool isPushDisabled;
/// プッシュトークン（デバイストークン）
@override final  String? pushToken;
/// OneSignal Player ID (Subscription ID)
@override final  String? subscriptionId;

/// Create a copy of NotificationPermissionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPermissionStateCopyWith<_NotificationPermissionState> get copyWith => __$NotificationPermissionStateCopyWithImpl<_NotificationPermissionState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPermissionStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPermissionState&&(identical(other.areNotificationsEnabled, areNotificationsEnabled) || other.areNotificationsEnabled == areNotificationsEnabled)&&(identical(other.isPushDisabled, isPushDisabled) || other.isPushDisabled == isPushDisabled)&&(identical(other.pushToken, pushToken) || other.pushToken == pushToken)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,areNotificationsEnabled,isPushDisabled,pushToken,subscriptionId);

@override
String toString() {
  return 'NotificationPermissionState(areNotificationsEnabled: $areNotificationsEnabled, isPushDisabled: $isPushDisabled, pushToken: $pushToken, subscriptionId: $subscriptionId)';
}


}

/// @nodoc
abstract mixin class _$NotificationPermissionStateCopyWith<$Res> implements $NotificationPermissionStateCopyWith<$Res> {
  factory _$NotificationPermissionStateCopyWith(_NotificationPermissionState value, $Res Function(_NotificationPermissionState) _then) = __$NotificationPermissionStateCopyWithImpl;
@override @useResult
$Res call({
 bool areNotificationsEnabled, bool isPushDisabled, String? pushToken, String? subscriptionId
});




}
/// @nodoc
class __$NotificationPermissionStateCopyWithImpl<$Res>
    implements _$NotificationPermissionStateCopyWith<$Res> {
  __$NotificationPermissionStateCopyWithImpl(this._self, this._then);

  final _NotificationPermissionState _self;
  final $Res Function(_NotificationPermissionState) _then;

/// Create a copy of NotificationPermissionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? areNotificationsEnabled = null,Object? isPushDisabled = null,Object? pushToken = freezed,Object? subscriptionId = freezed,}) {
  return _then(_NotificationPermissionState(
areNotificationsEnabled: null == areNotificationsEnabled ? _self.areNotificationsEnabled : areNotificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,isPushDisabled: null == isPushDisabled ? _self.isPushDisabled : isPushDisabled // ignore: cast_nullable_to_non_nullable
as bool,pushToken: freezed == pushToken ? _self.pushToken : pushToken // ignore: cast_nullable_to_non_nullable
as String?,subscriptionId: freezed == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
