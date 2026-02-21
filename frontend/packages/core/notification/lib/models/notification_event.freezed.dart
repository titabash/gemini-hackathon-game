// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationEvent {

/// 通知ID
 String get notificationId;/// 通知タイトル
 String? get title;/// 通知本文
 String? get body;/// 追加データ
 Map<String, dynamic>? get additionalData;/// アクション可能か（タップされたか）
 bool get isAction;/// 受信時刻
 DateTime get receivedAt;
/// Create a copy of NotificationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationEventCopyWith<NotificationEvent> get copyWith => _$NotificationEventCopyWithImpl<NotificationEvent>(this as NotificationEvent, _$identity);

  /// Serializes this NotificationEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationEvent&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.additionalData, additionalData)&&(identical(other.isAction, isAction) || other.isAction == isAction)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notificationId,title,body,const DeepCollectionEquality().hash(additionalData),isAction,receivedAt);

@override
String toString() {
  return 'NotificationEvent(notificationId: $notificationId, title: $title, body: $body, additionalData: $additionalData, isAction: $isAction, receivedAt: $receivedAt)';
}


}

/// @nodoc
abstract mixin class $NotificationEventCopyWith<$Res>  {
  factory $NotificationEventCopyWith(NotificationEvent value, $Res Function(NotificationEvent) _then) = _$NotificationEventCopyWithImpl;
@useResult
$Res call({
 String notificationId, String? title, String? body, Map<String, dynamic>? additionalData, bool isAction, DateTime receivedAt
});




}
/// @nodoc
class _$NotificationEventCopyWithImpl<$Res>
    implements $NotificationEventCopyWith<$Res> {
  _$NotificationEventCopyWithImpl(this._self, this._then);

  final NotificationEvent _self;
  final $Res Function(NotificationEvent) _then;

/// Create a copy of NotificationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notificationId = null,Object? title = freezed,Object? body = freezed,Object? additionalData = freezed,Object? isAction = null,Object? receivedAt = null,}) {
  return _then(_self.copyWith(
notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,additionalData: freezed == additionalData ? _self.additionalData : additionalData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isAction: null == isAction ? _self.isAction : isAction // ignore: cast_nullable_to_non_nullable
as bool,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationEvent].
extension NotificationEventPatterns on NotificationEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationEvent value)  $default,){
final _that = this;
switch (_that) {
case _NotificationEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationEvent value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String notificationId,  String? title,  String? body,  Map<String, dynamic>? additionalData,  bool isAction,  DateTime receivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationEvent() when $default != null:
return $default(_that.notificationId,_that.title,_that.body,_that.additionalData,_that.isAction,_that.receivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String notificationId,  String? title,  String? body,  Map<String, dynamic>? additionalData,  bool isAction,  DateTime receivedAt)  $default,) {final _that = this;
switch (_that) {
case _NotificationEvent():
return $default(_that.notificationId,_that.title,_that.body,_that.additionalData,_that.isAction,_that.receivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String notificationId,  String? title,  String? body,  Map<String, dynamic>? additionalData,  bool isAction,  DateTime receivedAt)?  $default,) {final _that = this;
switch (_that) {
case _NotificationEvent() when $default != null:
return $default(_that.notificationId,_that.title,_that.body,_that.additionalData,_that.isAction,_that.receivedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationEvent implements NotificationEvent {
  const _NotificationEvent({required this.notificationId, this.title, this.body, final  Map<String, dynamic>? additionalData, required this.isAction, required this.receivedAt}): _additionalData = additionalData;
  factory _NotificationEvent.fromJson(Map<String, dynamic> json) => _$NotificationEventFromJson(json);

/// 通知ID
@override final  String notificationId;
/// 通知タイトル
@override final  String? title;
/// 通知本文
@override final  String? body;
/// 追加データ
 final  Map<String, dynamic>? _additionalData;
/// 追加データ
@override Map<String, dynamic>? get additionalData {
  final value = _additionalData;
  if (value == null) return null;
  if (_additionalData is EqualUnmodifiableMapView) return _additionalData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// アクション可能か（タップされたか）
@override final  bool isAction;
/// 受信時刻
@override final  DateTime receivedAt;

/// Create a copy of NotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationEventCopyWith<_NotificationEvent> get copyWith => __$NotificationEventCopyWithImpl<_NotificationEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationEvent&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other._additionalData, _additionalData)&&(identical(other.isAction, isAction) || other.isAction == isAction)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notificationId,title,body,const DeepCollectionEquality().hash(_additionalData),isAction,receivedAt);

@override
String toString() {
  return 'NotificationEvent(notificationId: $notificationId, title: $title, body: $body, additionalData: $additionalData, isAction: $isAction, receivedAt: $receivedAt)';
}


}

/// @nodoc
abstract mixin class _$NotificationEventCopyWith<$Res> implements $NotificationEventCopyWith<$Res> {
  factory _$NotificationEventCopyWith(_NotificationEvent value, $Res Function(_NotificationEvent) _then) = __$NotificationEventCopyWithImpl;
@override @useResult
$Res call({
 String notificationId, String? title, String? body, Map<String, dynamic>? additionalData, bool isAction, DateTime receivedAt
});




}
/// @nodoc
class __$NotificationEventCopyWithImpl<$Res>
    implements _$NotificationEventCopyWith<$Res> {
  __$NotificationEventCopyWithImpl(this._self, this._then);

  final _NotificationEvent _self;
  final $Res Function(_NotificationEvent) _then;

/// Create a copy of NotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notificationId = null,Object? title = freezed,Object? body = freezed,Object? additionalData = freezed,Object? isAction = null,Object? receivedAt = null,}) {
  return _then(_NotificationEvent(
notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,additionalData: freezed == additionalData ? _self._additionalData : additionalData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isAction: null == isAction ? _self.isAction : isAction // ignore: cast_nullable_to_non_nullable
as bool,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
