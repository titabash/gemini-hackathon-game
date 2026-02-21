// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameSession {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'scenario_id') String get scenarioId; String get title;@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) SessionStatus get status;@JsonKey(name: 'current_state') Map<String, dynamic> get currentState;@JsonKey(name: 'current_turn_number') int get currentTurnNumber;@JsonKey(name: 'ending_summary') String? get endingSummary;@JsonKey(name: 'ending_type') String? get endingType;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameSessionCopyWith<GameSession> get copyWith => _$GameSessionCopyWithImpl<GameSession>(this as GameSession, _$identity);

  /// Serializes this GameSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.scenarioId, scenarioId) || other.scenarioId == scenarioId)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.currentState, currentState)&&(identical(other.currentTurnNumber, currentTurnNumber) || other.currentTurnNumber == currentTurnNumber)&&(identical(other.endingSummary, endingSummary) || other.endingSummary == endingSummary)&&(identical(other.endingType, endingType) || other.endingType == endingType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,scenarioId,title,status,const DeepCollectionEquality().hash(currentState),currentTurnNumber,endingSummary,endingType,createdAt,updatedAt);

@override
String toString() {
  return 'GameSession(id: $id, userId: $userId, scenarioId: $scenarioId, title: $title, status: $status, currentState: $currentState, currentTurnNumber: $currentTurnNumber, endingSummary: $endingSummary, endingType: $endingType, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GameSessionCopyWith<$Res>  {
  factory $GameSessionCopyWith(GameSession value, $Res Function(GameSession) _then) = _$GameSessionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'scenario_id') String scenarioId, String title,@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) SessionStatus status,@JsonKey(name: 'current_state') Map<String, dynamic> currentState,@JsonKey(name: 'current_turn_number') int currentTurnNumber,@JsonKey(name: 'ending_summary') String? endingSummary,@JsonKey(name: 'ending_type') String? endingType,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$GameSessionCopyWithImpl<$Res>
    implements $GameSessionCopyWith<$Res> {
  _$GameSessionCopyWithImpl(this._self, this._then);

  final GameSession _self;
  final $Res Function(GameSession) _then;

/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? scenarioId = null,Object? title = null,Object? status = null,Object? currentState = null,Object? currentTurnNumber = null,Object? endingSummary = freezed,Object? endingType = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,scenarioId: null == scenarioId ? _self.scenarioId : scenarioId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,currentState: null == currentState ? _self.currentState : currentState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,currentTurnNumber: null == currentTurnNumber ? _self.currentTurnNumber : currentTurnNumber // ignore: cast_nullable_to_non_nullable
as int,endingSummary: freezed == endingSummary ? _self.endingSummary : endingSummary // ignore: cast_nullable_to_non_nullable
as String?,endingType: freezed == endingType ? _self.endingType : endingType // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameSession].
extension GameSessionPatterns on GameSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameSession value)  $default,){
final _that = this;
switch (_that) {
case _GameSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameSession value)?  $default,){
final _that = this;
switch (_that) {
case _GameSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'scenario_id')  String scenarioId,  String title, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)  SessionStatus status, @JsonKey(name: 'current_state')  Map<String, dynamic> currentState, @JsonKey(name: 'current_turn_number')  int currentTurnNumber, @JsonKey(name: 'ending_summary')  String? endingSummary, @JsonKey(name: 'ending_type')  String? endingType, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameSession() when $default != null:
return $default(_that.id,_that.userId,_that.scenarioId,_that.title,_that.status,_that.currentState,_that.currentTurnNumber,_that.endingSummary,_that.endingType,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'scenario_id')  String scenarioId,  String title, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)  SessionStatus status, @JsonKey(name: 'current_state')  Map<String, dynamic> currentState, @JsonKey(name: 'current_turn_number')  int currentTurnNumber, @JsonKey(name: 'ending_summary')  String? endingSummary, @JsonKey(name: 'ending_type')  String? endingType, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _GameSession():
return $default(_that.id,_that.userId,_that.scenarioId,_that.title,_that.status,_that.currentState,_that.currentTurnNumber,_that.endingSummary,_that.endingType,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'scenario_id')  String scenarioId,  String title, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)  SessionStatus status, @JsonKey(name: 'current_state')  Map<String, dynamic> currentState, @JsonKey(name: 'current_turn_number')  int currentTurnNumber, @JsonKey(name: 'ending_summary')  String? endingSummary, @JsonKey(name: 'ending_type')  String? endingType, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _GameSession() when $default != null:
return $default(_that.id,_that.userId,_that.scenarioId,_that.title,_that.status,_that.currentState,_that.currentTurnNumber,_that.endingSummary,_that.endingType,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameSession implements GameSession {
  const _GameSession({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'scenario_id') required this.scenarioId, this.title = '', @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) this.status = SessionStatus.active, @JsonKey(name: 'current_state') required final  Map<String, dynamic> currentState, @JsonKey(name: 'current_turn_number') this.currentTurnNumber = 0, @JsonKey(name: 'ending_summary') this.endingSummary, @JsonKey(name: 'ending_type') this.endingType, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _currentState = currentState;
  factory _GameSession.fromJson(Map<String, dynamic> json) => _$GameSessionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'scenario_id') final  String scenarioId;
@override@JsonKey() final  String title;
@override@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) final  SessionStatus status;
 final  Map<String, dynamic> _currentState;
@override@JsonKey(name: 'current_state') Map<String, dynamic> get currentState {
  if (_currentState is EqualUnmodifiableMapView) return _currentState;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_currentState);
}

@override@JsonKey(name: 'current_turn_number') final  int currentTurnNumber;
@override@JsonKey(name: 'ending_summary') final  String? endingSummary;
@override@JsonKey(name: 'ending_type') final  String? endingType;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameSessionCopyWith<_GameSession> get copyWith => __$GameSessionCopyWithImpl<_GameSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.scenarioId, scenarioId) || other.scenarioId == scenarioId)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._currentState, _currentState)&&(identical(other.currentTurnNumber, currentTurnNumber) || other.currentTurnNumber == currentTurnNumber)&&(identical(other.endingSummary, endingSummary) || other.endingSummary == endingSummary)&&(identical(other.endingType, endingType) || other.endingType == endingType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,scenarioId,title,status,const DeepCollectionEquality().hash(_currentState),currentTurnNumber,endingSummary,endingType,createdAt,updatedAt);

@override
String toString() {
  return 'GameSession(id: $id, userId: $userId, scenarioId: $scenarioId, title: $title, status: $status, currentState: $currentState, currentTurnNumber: $currentTurnNumber, endingSummary: $endingSummary, endingType: $endingType, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GameSessionCopyWith<$Res> implements $GameSessionCopyWith<$Res> {
  factory _$GameSessionCopyWith(_GameSession value, $Res Function(_GameSession) _then) = __$GameSessionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'scenario_id') String scenarioId, String title,@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) SessionStatus status,@JsonKey(name: 'current_state') Map<String, dynamic> currentState,@JsonKey(name: 'current_turn_number') int currentTurnNumber,@JsonKey(name: 'ending_summary') String? endingSummary,@JsonKey(name: 'ending_type') String? endingType,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$GameSessionCopyWithImpl<$Res>
    implements _$GameSessionCopyWith<$Res> {
  __$GameSessionCopyWithImpl(this._self, this._then);

  final _GameSession _self;
  final $Res Function(_GameSession) _then;

/// Create a copy of GameSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? scenarioId = null,Object? title = null,Object? status = null,Object? currentState = null,Object? currentTurnNumber = null,Object? endingSummary = freezed,Object? endingType = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_GameSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,scenarioId: null == scenarioId ? _self.scenarioId : scenarioId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,currentState: null == currentState ? _self._currentState : currentState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,currentTurnNumber: null == currentTurnNumber ? _self.currentTurnNumber : currentTurnNumber // ignore: cast_nullable_to_non_nullable
as int,endingSummary: freezed == endingSummary ? _self.endingSummary : endingSummary // ignore: cast_nullable_to_non_nullable
as String?,endingType: freezed == endingType ? _self.endingType : endingType // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
