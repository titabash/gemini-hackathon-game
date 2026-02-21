// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversationState()';
}


}

/// @nodoc
class $ConversationStateCopyWith<$Res>  {
$ConversationStateCopyWith(ConversationState _, $Res Function(ConversationState) __);
}


/// Adds pattern-matching-related methods to [ConversationState].
extension ConversationStatePatterns on ConversationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ConversationStateIdle value)?  idle,TResult Function( ConversationStateProcessing value)?  processing,TResult Function( ConversationStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ConversationStateIdle() when idle != null:
return idle(_that);case ConversationStateProcessing() when processing != null:
return processing(_that);case ConversationStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ConversationStateIdle value)  idle,required TResult Function( ConversationStateProcessing value)  processing,required TResult Function( ConversationStateError value)  error,}){
final _that = this;
switch (_that) {
case ConversationStateIdle():
return idle(_that);case ConversationStateProcessing():
return processing(_that);case ConversationStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ConversationStateIdle value)?  idle,TResult? Function( ConversationStateProcessing value)?  processing,TResult? Function( ConversationStateError value)?  error,}){
final _that = this;
switch (_that) {
case ConversationStateIdle() when idle != null:
return idle(_that);case ConversationStateProcessing() when processing != null:
return processing(_that);case ConversationStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  processing,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ConversationStateIdle() when idle != null:
return idle();case ConversationStateProcessing() when processing != null:
return processing();case ConversationStateError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  processing,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ConversationStateIdle():
return idle();case ConversationStateProcessing():
return processing();case ConversationStateError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  processing,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ConversationStateIdle() when idle != null:
return idle();case ConversationStateProcessing() when processing != null:
return processing();case ConversationStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ConversationStateIdle implements ConversationState {
  const ConversationStateIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationStateIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversationState.idle()';
}


}




/// @nodoc


class ConversationStateProcessing implements ConversationState {
  const ConversationStateProcessing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationStateProcessing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversationState.processing()';
}


}




/// @nodoc


class ConversationStateError implements ConversationState {
  const ConversationStateError({required this.message});
  

 final  String message;

/// Create a copy of ConversationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationStateErrorCopyWith<ConversationStateError> get copyWith => _$ConversationStateErrorCopyWithImpl<ConversationStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ConversationState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ConversationStateErrorCopyWith<$Res> implements $ConversationStateCopyWith<$Res> {
  factory $ConversationStateErrorCopyWith(ConversationStateError value, $Res Function(ConversationStateError) _then) = _$ConversationStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ConversationStateErrorCopyWithImpl<$Res>
    implements $ConversationStateErrorCopyWith<$Res> {
  _$ConversationStateErrorCopyWithImpl(this._self, this._then);

  final ConversationStateError _self;
  final $Res Function(ConversationStateError) _then;

/// Create a copy of ConversationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ConversationStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
