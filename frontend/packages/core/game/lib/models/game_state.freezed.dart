// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
GameState _$GameStateFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'initial':
          return GameStateInitial.fromJson(
            json
          );
                case 'loading':
          return GameStateLoading.fromJson(
            json
          );
                case 'playing':
          return GameStatePlaying.fromJson(
            json
          );
                case 'paused':
          return GameStatePaused.fromJson(
            json
          );
                case 'gameOver':
          return GameStateGameOver.fromJson(
            json
          );
                case 'error':
          return GameStateError.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'GameState',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$GameState {



  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameState);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameState()';
}


}

/// @nodoc
class $GameStateCopyWith<$Res>  {
$GameStateCopyWith(GameState _, $Res Function(GameState) __);
}


/// Adds pattern-matching-related methods to [GameState].
extension GameStatePatterns on GameState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GameStateInitial value)?  initial,TResult Function( GameStateLoading value)?  loading,TResult Function( GameStatePlaying value)?  playing,TResult Function( GameStatePaused value)?  paused,TResult Function( GameStateGameOver value)?  gameOver,TResult Function( GameStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GameStateInitial() when initial != null:
return initial(_that);case GameStateLoading() when loading != null:
return loading(_that);case GameStatePlaying() when playing != null:
return playing(_that);case GameStatePaused() when paused != null:
return paused(_that);case GameStateGameOver() when gameOver != null:
return gameOver(_that);case GameStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GameStateInitial value)  initial,required TResult Function( GameStateLoading value)  loading,required TResult Function( GameStatePlaying value)  playing,required TResult Function( GameStatePaused value)  paused,required TResult Function( GameStateGameOver value)  gameOver,required TResult Function( GameStateError value)  error,}){
final _that = this;
switch (_that) {
case GameStateInitial():
return initial(_that);case GameStateLoading():
return loading(_that);case GameStatePlaying():
return playing(_that);case GameStatePaused():
return paused(_that);case GameStateGameOver():
return gameOver(_that);case GameStateError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GameStateInitial value)?  initial,TResult? Function( GameStateLoading value)?  loading,TResult? Function( GameStatePlaying value)?  playing,TResult? Function( GameStatePaused value)?  paused,TResult? Function( GameStateGameOver value)?  gameOver,TResult? Function( GameStateError value)?  error,}){
final _that = this;
switch (_that) {
case GameStateInitial() when initial != null:
return initial(_that);case GameStateLoading() when loading != null:
return loading(_that);case GameStatePlaying() when playing != null:
return playing(_that);case GameStatePaused() when paused != null:
return paused(_that);case GameStateGameOver() when gameOver != null:
return gameOver(_that);case GameStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String? message)?  loading,TResult Function()?  playing,TResult Function()?  paused,TResult Function( int score,  Map<String, dynamic>? metadata)?  gameOver,TResult Function( String message,  Object? error)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GameStateInitial() when initial != null:
return initial();case GameStateLoading() when loading != null:
return loading(_that.message);case GameStatePlaying() when playing != null:
return playing();case GameStatePaused() when paused != null:
return paused();case GameStateGameOver() when gameOver != null:
return gameOver(_that.score,_that.metadata);case GameStateError() when error != null:
return error(_that.message,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String? message)  loading,required TResult Function()  playing,required TResult Function()  paused,required TResult Function( int score,  Map<String, dynamic>? metadata)  gameOver,required TResult Function( String message,  Object? error)  error,}) {final _that = this;
switch (_that) {
case GameStateInitial():
return initial();case GameStateLoading():
return loading(_that.message);case GameStatePlaying():
return playing();case GameStatePaused():
return paused();case GameStateGameOver():
return gameOver(_that.score,_that.metadata);case GameStateError():
return error(_that.message,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String? message)?  loading,TResult? Function()?  playing,TResult? Function()?  paused,TResult? Function( int score,  Map<String, dynamic>? metadata)?  gameOver,TResult? Function( String message,  Object? error)?  error,}) {final _that = this;
switch (_that) {
case GameStateInitial() when initial != null:
return initial();case GameStateLoading() when loading != null:
return loading(_that.message);case GameStatePlaying() when playing != null:
return playing();case GameStatePaused() when paused != null:
return paused();case GameStateGameOver() when gameOver != null:
return gameOver(_that.score,_that.metadata);case GameStateError() when error != null:
return error(_that.message,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class GameStateInitial implements GameState {
  const GameStateInitial({final  String? $type}): $type = $type ?? 'initial';
  factory GameStateInitial.fromJson(Map<String, dynamic> json) => _$GameStateInitialFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$GameStateInitialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameStateInitial);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameState.initial()';
}


}




/// @nodoc
@JsonSerializable()

class GameStateLoading implements GameState {
  const GameStateLoading({this.message, final  String? $type}): $type = $type ?? 'loading';
  factory GameStateLoading.fromJson(Map<String, dynamic> json) => _$GameStateLoadingFromJson(json);

 final  String? message;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStateLoadingCopyWith<GameStateLoading> get copyWith => _$GameStateLoadingCopyWithImpl<GameStateLoading>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameStateLoadingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameStateLoading&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'GameState.loading(message: $message)';
}


}

/// @nodoc
abstract mixin class $GameStateLoadingCopyWith<$Res> implements $GameStateCopyWith<$Res> {
  factory $GameStateLoadingCopyWith(GameStateLoading value, $Res Function(GameStateLoading) _then) = _$GameStateLoadingCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$GameStateLoadingCopyWithImpl<$Res>
    implements $GameStateLoadingCopyWith<$Res> {
  _$GameStateLoadingCopyWithImpl(this._self, this._then);

  final GameStateLoading _self;
  final $Res Function(GameStateLoading) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(GameStateLoading(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GameStatePlaying implements GameState {
  const GameStatePlaying({final  String? $type}): $type = $type ?? 'playing';
  factory GameStatePlaying.fromJson(Map<String, dynamic> json) => _$GameStatePlayingFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$GameStatePlayingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameStatePlaying);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameState.playing()';
}


}




/// @nodoc
@JsonSerializable()

class GameStatePaused implements GameState {
  const GameStatePaused({final  String? $type}): $type = $type ?? 'paused';
  factory GameStatePaused.fromJson(Map<String, dynamic> json) => _$GameStatePausedFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$GameStatePausedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameStatePaused);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameState.paused()';
}


}




/// @nodoc
@JsonSerializable()

class GameStateGameOver implements GameState {
  const GameStateGameOver({this.score = 0, final  Map<String, dynamic>? metadata, final  String? $type}): _metadata = metadata,$type = $type ?? 'gameOver';
  factory GameStateGameOver.fromJson(Map<String, dynamic> json) => _$GameStateGameOverFromJson(json);

@JsonKey() final  int score;
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


/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStateGameOverCopyWith<GameStateGameOver> get copyWith => _$GameStateGameOverCopyWithImpl<GameStateGameOver>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameStateGameOverToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameStateGameOver&&(identical(other.score, score) || other.score == score)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,score,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'GameState.gameOver(score: $score, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $GameStateGameOverCopyWith<$Res> implements $GameStateCopyWith<$Res> {
  factory $GameStateGameOverCopyWith(GameStateGameOver value, $Res Function(GameStateGameOver) _then) = _$GameStateGameOverCopyWithImpl;
@useResult
$Res call({
 int score, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$GameStateGameOverCopyWithImpl<$Res>
    implements $GameStateGameOverCopyWith<$Res> {
  _$GameStateGameOverCopyWithImpl(this._self, this._then);

  final GameStateGameOver _self;
  final $Res Function(GameStateGameOver) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? score = null,Object? metadata = freezed,}) {
  return _then(GameStateGameOver(
score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GameStateError implements GameState {
  const GameStateError({required this.message, this.error, final  String? $type}): $type = $type ?? 'error';
  factory GameStateError.fromJson(Map<String, dynamic> json) => _$GameStateErrorFromJson(json);

 final  String message;
 final  Object? error;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStateErrorCopyWith<GameStateError> get copyWith => _$GameStateErrorCopyWithImpl<GameStateError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameStateErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameStateError&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.error, error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'GameState.error(message: $message, error: $error)';
}


}

/// @nodoc
abstract mixin class $GameStateErrorCopyWith<$Res> implements $GameStateCopyWith<$Res> {
  factory $GameStateErrorCopyWith(GameStateError value, $Res Function(GameStateError) _then) = _$GameStateErrorCopyWithImpl;
@useResult
$Res call({
 String message, Object? error
});




}
/// @nodoc
class _$GameStateErrorCopyWithImpl<$Res>
    implements $GameStateErrorCopyWith<$Res> {
  _$GameStateErrorCopyWithImpl(this._self, this._then);

  final GameStateError _self;
  final $Res Function(GameStateError) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? error = freezed,}) {
  return _then(GameStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
