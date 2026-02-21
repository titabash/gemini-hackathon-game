// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'genui_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
GenuiMessage _$GenuiMessageFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'user':
          return GenuiMessageUser.fromJson(
            json
          );
                case 'assistant':
          return GenuiMessageAssistant.fromJson(
            json
          );
                case 'system':
          return GenuiMessageSystem.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'GenuiMessage',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$GenuiMessage {

 String get text;
/// Create a copy of GenuiMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenuiMessageCopyWith<GenuiMessage> get copyWith => _$GenuiMessageCopyWithImpl<GenuiMessage>(this as GenuiMessage, _$identity);

  /// Serializes this GenuiMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenuiMessage&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'GenuiMessage(text: $text)';
}


}

/// @nodoc
abstract mixin class $GenuiMessageCopyWith<$Res>  {
  factory $GenuiMessageCopyWith(GenuiMessage value, $Res Function(GenuiMessage) _then) = _$GenuiMessageCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$GenuiMessageCopyWithImpl<$Res>
    implements $GenuiMessageCopyWith<$Res> {
  _$GenuiMessageCopyWithImpl(this._self, this._then);

  final GenuiMessage _self;
  final $Res Function(GenuiMessage) _then;

/// Create a copy of GenuiMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GenuiMessage].
extension GenuiMessagePatterns on GenuiMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GenuiMessageUser value)?  user,TResult Function( GenuiMessageAssistant value)?  assistant,TResult Function( GenuiMessageSystem value)?  system,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GenuiMessageUser() when user != null:
return user(_that);case GenuiMessageAssistant() when assistant != null:
return assistant(_that);case GenuiMessageSystem() when system != null:
return system(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GenuiMessageUser value)  user,required TResult Function( GenuiMessageAssistant value)  assistant,required TResult Function( GenuiMessageSystem value)  system,}){
final _that = this;
switch (_that) {
case GenuiMessageUser():
return user(_that);case GenuiMessageAssistant():
return assistant(_that);case GenuiMessageSystem():
return system(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GenuiMessageUser value)?  user,TResult? Function( GenuiMessageAssistant value)?  assistant,TResult? Function( GenuiMessageSystem value)?  system,}){
final _that = this;
switch (_that) {
case GenuiMessageUser() when user != null:
return user(_that);case GenuiMessageAssistant() when assistant != null:
return assistant(_that);case GenuiMessageSystem() when system != null:
return system(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  user,TResult Function( String text,  List<String>? surfaceIds)?  assistant,TResult Function( String text)?  system,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GenuiMessageUser() when user != null:
return user(_that.text);case GenuiMessageAssistant() when assistant != null:
return assistant(_that.text,_that.surfaceIds);case GenuiMessageSystem() when system != null:
return system(_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  user,required TResult Function( String text,  List<String>? surfaceIds)  assistant,required TResult Function( String text)  system,}) {final _that = this;
switch (_that) {
case GenuiMessageUser():
return user(_that.text);case GenuiMessageAssistant():
return assistant(_that.text,_that.surfaceIds);case GenuiMessageSystem():
return system(_that.text);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  user,TResult? Function( String text,  List<String>? surfaceIds)?  assistant,TResult? Function( String text)?  system,}) {final _that = this;
switch (_that) {
case GenuiMessageUser() when user != null:
return user(_that.text);case GenuiMessageAssistant() when assistant != null:
return assistant(_that.text,_that.surfaceIds);case GenuiMessageSystem() when system != null:
return system(_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class GenuiMessageUser implements GenuiMessage {
  const GenuiMessageUser({required this.text, final  String? $type}): $type = $type ?? 'user';
  factory GenuiMessageUser.fromJson(Map<String, dynamic> json) => _$GenuiMessageUserFromJson(json);

@override final  String text;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GenuiMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenuiMessageUserCopyWith<GenuiMessageUser> get copyWith => _$GenuiMessageUserCopyWithImpl<GenuiMessageUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenuiMessageUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenuiMessageUser&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'GenuiMessage.user(text: $text)';
}


}

/// @nodoc
abstract mixin class $GenuiMessageUserCopyWith<$Res> implements $GenuiMessageCopyWith<$Res> {
  factory $GenuiMessageUserCopyWith(GenuiMessageUser value, $Res Function(GenuiMessageUser) _then) = _$GenuiMessageUserCopyWithImpl;
@override @useResult
$Res call({
 String text
});




}
/// @nodoc
class _$GenuiMessageUserCopyWithImpl<$Res>
    implements $GenuiMessageUserCopyWith<$Res> {
  _$GenuiMessageUserCopyWithImpl(this._self, this._then);

  final GenuiMessageUser _self;
  final $Res Function(GenuiMessageUser) _then;

/// Create a copy of GenuiMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(GenuiMessageUser(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GenuiMessageAssistant implements GenuiMessage {
  const GenuiMessageAssistant({required this.text, final  List<String>? surfaceIds, final  String? $type}): _surfaceIds = surfaceIds,$type = $type ?? 'assistant';
  factory GenuiMessageAssistant.fromJson(Map<String, dynamic> json) => _$GenuiMessageAssistantFromJson(json);

@override final  String text;
 final  List<String>? _surfaceIds;
 List<String>? get surfaceIds {
  final value = _surfaceIds;
  if (value == null) return null;
  if (_surfaceIds is EqualUnmodifiableListView) return _surfaceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GenuiMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenuiMessageAssistantCopyWith<GenuiMessageAssistant> get copyWith => _$GenuiMessageAssistantCopyWithImpl<GenuiMessageAssistant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenuiMessageAssistantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenuiMessageAssistant&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._surfaceIds, _surfaceIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_surfaceIds));

@override
String toString() {
  return 'GenuiMessage.assistant(text: $text, surfaceIds: $surfaceIds)';
}


}

/// @nodoc
abstract mixin class $GenuiMessageAssistantCopyWith<$Res> implements $GenuiMessageCopyWith<$Res> {
  factory $GenuiMessageAssistantCopyWith(GenuiMessageAssistant value, $Res Function(GenuiMessageAssistant) _then) = _$GenuiMessageAssistantCopyWithImpl;
@override @useResult
$Res call({
 String text, List<String>? surfaceIds
});




}
/// @nodoc
class _$GenuiMessageAssistantCopyWithImpl<$Res>
    implements $GenuiMessageAssistantCopyWith<$Res> {
  _$GenuiMessageAssistantCopyWithImpl(this._self, this._then);

  final GenuiMessageAssistant _self;
  final $Res Function(GenuiMessageAssistant) _then;

/// Create a copy of GenuiMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? surfaceIds = freezed,}) {
  return _then(GenuiMessageAssistant(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,surfaceIds: freezed == surfaceIds ? _self._surfaceIds : surfaceIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GenuiMessageSystem implements GenuiMessage {
  const GenuiMessageSystem({required this.text, final  String? $type}): $type = $type ?? 'system';
  factory GenuiMessageSystem.fromJson(Map<String, dynamic> json) => _$GenuiMessageSystemFromJson(json);

@override final  String text;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GenuiMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenuiMessageSystemCopyWith<GenuiMessageSystem> get copyWith => _$GenuiMessageSystemCopyWithImpl<GenuiMessageSystem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenuiMessageSystemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenuiMessageSystem&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'GenuiMessage.system(text: $text)';
}


}

/// @nodoc
abstract mixin class $GenuiMessageSystemCopyWith<$Res> implements $GenuiMessageCopyWith<$Res> {
  factory $GenuiMessageSystemCopyWith(GenuiMessageSystem value, $Res Function(GenuiMessageSystem) _then) = _$GenuiMessageSystemCopyWithImpl;
@override @useResult
$Res call({
 String text
});




}
/// @nodoc
class _$GenuiMessageSystemCopyWithImpl<$Res>
    implements $GenuiMessageSystemCopyWith<$Res> {
  _$GenuiMessageSystemCopyWithImpl(this._self, this._then);

  final GenuiMessageSystem _self;
  final $Res Function(GenuiMessageSystem) _then;

/// Create a copy of GenuiMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(GenuiMessageSystem(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
