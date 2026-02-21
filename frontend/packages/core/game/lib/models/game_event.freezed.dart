// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
GameEvent _$GameEventFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'started':
          return GameEventStarted.fromJson(
            json
          );
                case 'paused':
          return GameEventPaused.fromJson(
            json
          );
                case 'resumed':
          return GameEventResumed.fromJson(
            json
          );
                case 'scored':
          return GameEventScored.fromJson(
            json
          );
                case 'ended':
          return GameEventEnded.fromJson(
            json
          );
                case 'custom':
          return GameEventCustom.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'GameEvent',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$GameEvent {



  /// Serializes this GameEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEvent);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameEvent()';
}


}

/// @nodoc
class $GameEventCopyWith<$Res>  {
$GameEventCopyWith(GameEvent _, $Res Function(GameEvent) __);
}


/// Adds pattern-matching-related methods to [GameEvent].
extension GameEventPatterns on GameEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GameEventStarted value)?  started,TResult Function( GameEventPaused value)?  paused,TResult Function( GameEventResumed value)?  resumed,TResult Function( GameEventScored value)?  scored,TResult Function( GameEventEnded value)?  ended,TResult Function( GameEventCustom value)?  custom,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GameEventStarted() when started != null:
return started(_that);case GameEventPaused() when paused != null:
return paused(_that);case GameEventResumed() when resumed != null:
return resumed(_that);case GameEventScored() when scored != null:
return scored(_that);case GameEventEnded() when ended != null:
return ended(_that);case GameEventCustom() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GameEventStarted value)  started,required TResult Function( GameEventPaused value)  paused,required TResult Function( GameEventResumed value)  resumed,required TResult Function( GameEventScored value)  scored,required TResult Function( GameEventEnded value)  ended,required TResult Function( GameEventCustom value)  custom,}){
final _that = this;
switch (_that) {
case GameEventStarted():
return started(_that);case GameEventPaused():
return paused(_that);case GameEventResumed():
return resumed(_that);case GameEventScored():
return scored(_that);case GameEventEnded():
return ended(_that);case GameEventCustom():
return custom(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GameEventStarted value)?  started,TResult? Function( GameEventPaused value)?  paused,TResult? Function( GameEventResumed value)?  resumed,TResult? Function( GameEventScored value)?  scored,TResult? Function( GameEventEnded value)?  ended,TResult? Function( GameEventCustom value)?  custom,}){
final _that = this;
switch (_that) {
case GameEventStarted() when started != null:
return started(_that);case GameEventPaused() when paused != null:
return paused(_that);case GameEventResumed() when resumed != null:
return resumed(_that);case GameEventScored() when scored != null:
return scored(_that);case GameEventEnded() when ended != null:
return ended(_that);case GameEventCustom() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  paused,TResult Function()?  resumed,TResult Function( int points)?  scored,TResult Function( int finalScore,  Map<String, dynamic>? metadata)?  ended,TResult Function( String name,  Map<String, dynamic>? data)?  custom,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GameEventStarted() when started != null:
return started();case GameEventPaused() when paused != null:
return paused();case GameEventResumed() when resumed != null:
return resumed();case GameEventScored() when scored != null:
return scored(_that.points);case GameEventEnded() when ended != null:
return ended(_that.finalScore,_that.metadata);case GameEventCustom() when custom != null:
return custom(_that.name,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  paused,required TResult Function()  resumed,required TResult Function( int points)  scored,required TResult Function( int finalScore,  Map<String, dynamic>? metadata)  ended,required TResult Function( String name,  Map<String, dynamic>? data)  custom,}) {final _that = this;
switch (_that) {
case GameEventStarted():
return started();case GameEventPaused():
return paused();case GameEventResumed():
return resumed();case GameEventScored():
return scored(_that.points);case GameEventEnded():
return ended(_that.finalScore,_that.metadata);case GameEventCustom():
return custom(_that.name,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  paused,TResult? Function()?  resumed,TResult? Function( int points)?  scored,TResult? Function( int finalScore,  Map<String, dynamic>? metadata)?  ended,TResult? Function( String name,  Map<String, dynamic>? data)?  custom,}) {final _that = this;
switch (_that) {
case GameEventStarted() when started != null:
return started();case GameEventPaused() when paused != null:
return paused();case GameEventResumed() when resumed != null:
return resumed();case GameEventScored() when scored != null:
return scored(_that.points);case GameEventEnded() when ended != null:
return ended(_that.finalScore,_that.metadata);case GameEventCustom() when custom != null:
return custom(_that.name,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class GameEventStarted implements GameEvent {
  const GameEventStarted({final  String? $type}): $type = $type ?? 'started';
  factory GameEventStarted.fromJson(Map<String, dynamic> json) => _$GameEventStartedFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$GameEventStartedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEventStarted);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameEvent.started()';
}


}




/// @nodoc
@JsonSerializable()

class GameEventPaused implements GameEvent {
  const GameEventPaused({final  String? $type}): $type = $type ?? 'paused';
  factory GameEventPaused.fromJson(Map<String, dynamic> json) => _$GameEventPausedFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$GameEventPausedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEventPaused);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameEvent.paused()';
}


}




/// @nodoc
@JsonSerializable()

class GameEventResumed implements GameEvent {
  const GameEventResumed({final  String? $type}): $type = $type ?? 'resumed';
  factory GameEventResumed.fromJson(Map<String, dynamic> json) => _$GameEventResumedFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$GameEventResumedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEventResumed);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameEvent.resumed()';
}


}




/// @nodoc
@JsonSerializable()

class GameEventScored implements GameEvent {
  const GameEventScored({required this.points, final  String? $type}): $type = $type ?? 'scored';
  factory GameEventScored.fromJson(Map<String, dynamic> json) => _$GameEventScoredFromJson(json);

 final  int points;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameEventScoredCopyWith<GameEventScored> get copyWith => _$GameEventScoredCopyWithImpl<GameEventScored>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameEventScoredToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEventScored&&(identical(other.points, points) || other.points == points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,points);

@override
String toString() {
  return 'GameEvent.scored(points: $points)';
}


}

/// @nodoc
abstract mixin class $GameEventScoredCopyWith<$Res> implements $GameEventCopyWith<$Res> {
  factory $GameEventScoredCopyWith(GameEventScored value, $Res Function(GameEventScored) _then) = _$GameEventScoredCopyWithImpl;
@useResult
$Res call({
 int points
});




}
/// @nodoc
class _$GameEventScoredCopyWithImpl<$Res>
    implements $GameEventScoredCopyWith<$Res> {
  _$GameEventScoredCopyWithImpl(this._self, this._then);

  final GameEventScored _self;
  final $Res Function(GameEventScored) _then;

/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? points = null,}) {
  return _then(GameEventScored(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GameEventEnded implements GameEvent {
  const GameEventEnded({required this.finalScore, final  Map<String, dynamic>? metadata, final  String? $type}): _metadata = metadata,$type = $type ?? 'ended';
  factory GameEventEnded.fromJson(Map<String, dynamic> json) => _$GameEventEndedFromJson(json);

 final  int finalScore;
 final  Map<String, dynamic>? _metadata;
 Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameEventEndedCopyWith<GameEventEnded> get copyWith => _$GameEventEndedCopyWithImpl<GameEventEnded>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameEventEndedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEventEnded&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,finalScore,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'GameEvent.ended(finalScore: $finalScore, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $GameEventEndedCopyWith<$Res> implements $GameEventCopyWith<$Res> {
  factory $GameEventEndedCopyWith(GameEventEnded value, $Res Function(GameEventEnded) _then) = _$GameEventEndedCopyWithImpl;
@useResult
$Res call({
 int finalScore, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$GameEventEndedCopyWithImpl<$Res>
    implements $GameEventEndedCopyWith<$Res> {
  _$GameEventEndedCopyWithImpl(this._self, this._then);

  final GameEventEnded _self;
  final $Res Function(GameEventEnded) _then;

/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? finalScore = null,Object? metadata = freezed,}) {
  return _then(GameEventEnded(
finalScore: null == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as int,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GameEventCustom implements GameEvent {
  const GameEventCustom({required this.name, final  Map<String, dynamic>? data, final  String? $type}): _data = data,$type = $type ?? 'custom';
  factory GameEventCustom.fromJson(Map<String, dynamic> json) => _$GameEventCustomFromJson(json);

 final  String name;
 final  Map<String, dynamic>? _data;
 Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameEventCustomCopyWith<GameEventCustom> get copyWith => _$GameEventCustomCopyWithImpl<GameEventCustom>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameEventCustomToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEventCustom&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'GameEvent.custom(name: $name, data: $data)';
}


}

/// @nodoc
abstract mixin class $GameEventCustomCopyWith<$Res> implements $GameEventCopyWith<$Res> {
  factory $GameEventCustomCopyWith(GameEventCustom value, $Res Function(GameEventCustom) _then) = _$GameEventCustomCopyWithImpl;
@useResult
$Res call({
 String name, Map<String, dynamic>? data
});




}
/// @nodoc
class _$GameEventCustomCopyWithImpl<$Res>
    implements $GameEventCustomCopyWith<$Res> {
  _$GameEventCustomCopyWithImpl(this._self, this._then);

  final GameEventCustom _self;
  final $Res Function(GameEventCustom) _then;

/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? data = freezed,}) {
  return _then(GameEventCustom(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
