// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scenario.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Scenario {

 String get id; String get title; String get description;@JsonKey(name: 'initial_state') Map<String, dynamic> get initialState;@JsonKey(name: 'win_conditions') List<dynamic> get winConditions;@JsonKey(name: 'fail_conditions') List<dynamic> get failConditions;@JsonKey(name: 'thumbnail_path') String? get thumbnailPath;@JsonKey(name: 'created_by') String? get createdBy;@JsonKey(name: 'is_public') bool get isPublic;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioCopyWith<Scenario> get copyWith => _$ScenarioCopyWithImpl<Scenario>(this as Scenario, _$identity);

  /// Serializes this Scenario to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Scenario&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.initialState, initialState)&&const DeepCollectionEquality().equals(other.winConditions, winConditions)&&const DeepCollectionEquality().equals(other.failConditions, failConditions)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,const DeepCollectionEquality().hash(initialState),const DeepCollectionEquality().hash(winConditions),const DeepCollectionEquality().hash(failConditions),thumbnailPath,createdBy,isPublic,createdAt,updatedAt);

@override
String toString() {
  return 'Scenario(id: $id, title: $title, description: $description, initialState: $initialState, winConditions: $winConditions, failConditions: $failConditions, thumbnailPath: $thumbnailPath, createdBy: $createdBy, isPublic: $isPublic, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ScenarioCopyWith<$Res>  {
  factory $ScenarioCopyWith(Scenario value, $Res Function(Scenario) _then) = _$ScenarioCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description,@JsonKey(name: 'initial_state') Map<String, dynamic> initialState,@JsonKey(name: 'win_conditions') List<dynamic> winConditions,@JsonKey(name: 'fail_conditions') List<dynamic> failConditions,@JsonKey(name: 'thumbnail_path') String? thumbnailPath,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'is_public') bool isPublic,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$ScenarioCopyWithImpl<$Res>
    implements $ScenarioCopyWith<$Res> {
  _$ScenarioCopyWithImpl(this._self, this._then);

  final Scenario _self;
  final $Res Function(Scenario) _then;

/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? initialState = null,Object? winConditions = null,Object? failConditions = null,Object? thumbnailPath = freezed,Object? createdBy = freezed,Object? isPublic = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,initialState: null == initialState ? _self.initialState : initialState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,winConditions: null == winConditions ? _self.winConditions : winConditions // ignore: cast_nullable_to_non_nullable
as List<dynamic>,failConditions: null == failConditions ? _self.failConditions : failConditions // ignore: cast_nullable_to_non_nullable
as List<dynamic>,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Scenario].
extension ScenarioPatterns on Scenario {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Scenario value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Scenario() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Scenario value)  $default,){
final _that = this;
switch (_that) {
case _Scenario():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Scenario value)?  $default,){
final _that = this;
switch (_that) {
case _Scenario() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description, @JsonKey(name: 'initial_state')  Map<String, dynamic> initialState, @JsonKey(name: 'win_conditions')  List<dynamic> winConditions, @JsonKey(name: 'fail_conditions')  List<dynamic> failConditions, @JsonKey(name: 'thumbnail_path')  String? thumbnailPath, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Scenario() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.initialState,_that.winConditions,_that.failConditions,_that.thumbnailPath,_that.createdBy,_that.isPublic,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description, @JsonKey(name: 'initial_state')  Map<String, dynamic> initialState, @JsonKey(name: 'win_conditions')  List<dynamic> winConditions, @JsonKey(name: 'fail_conditions')  List<dynamic> failConditions, @JsonKey(name: 'thumbnail_path')  String? thumbnailPath, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Scenario():
return $default(_that.id,_that.title,_that.description,_that.initialState,_that.winConditions,_that.failConditions,_that.thumbnailPath,_that.createdBy,_that.isPublic,_that.createdAt,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description, @JsonKey(name: 'initial_state')  Map<String, dynamic> initialState, @JsonKey(name: 'win_conditions')  List<dynamic> winConditions, @JsonKey(name: 'fail_conditions')  List<dynamic> failConditions, @JsonKey(name: 'thumbnail_path')  String? thumbnailPath, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'is_public')  bool isPublic, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Scenario() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.initialState,_that.winConditions,_that.failConditions,_that.thumbnailPath,_that.createdBy,_that.isPublic,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Scenario implements Scenario {
  const _Scenario({required this.id, required this.title, this.description = '', @JsonKey(name: 'initial_state') required final  Map<String, dynamic> initialState, @JsonKey(name: 'win_conditions') required final  List<dynamic> winConditions, @JsonKey(name: 'fail_conditions') required final  List<dynamic> failConditions, @JsonKey(name: 'thumbnail_path') this.thumbnailPath, @JsonKey(name: 'created_by') this.createdBy, @JsonKey(name: 'is_public') this.isPublic = true, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _initialState = initialState,_winConditions = winConditions,_failConditions = failConditions;
  factory _Scenario.fromJson(Map<String, dynamic> json) => _$ScenarioFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey() final  String description;
 final  Map<String, dynamic> _initialState;
@override@JsonKey(name: 'initial_state') Map<String, dynamic> get initialState {
  if (_initialState is EqualUnmodifiableMapView) return _initialState;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_initialState);
}

 final  List<dynamic> _winConditions;
@override@JsonKey(name: 'win_conditions') List<dynamic> get winConditions {
  if (_winConditions is EqualUnmodifiableListView) return _winConditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_winConditions);
}

 final  List<dynamic> _failConditions;
@override@JsonKey(name: 'fail_conditions') List<dynamic> get failConditions {
  if (_failConditions is EqualUnmodifiableListView) return _failConditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_failConditions);
}

@override@JsonKey(name: 'thumbnail_path') final  String? thumbnailPath;
@override@JsonKey(name: 'created_by') final  String? createdBy;
@override@JsonKey(name: 'is_public') final  bool isPublic;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioCopyWith<_Scenario> get copyWith => __$ScenarioCopyWithImpl<_Scenario>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Scenario&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._initialState, _initialState)&&const DeepCollectionEquality().equals(other._winConditions, _winConditions)&&const DeepCollectionEquality().equals(other._failConditions, _failConditions)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,const DeepCollectionEquality().hash(_initialState),const DeepCollectionEquality().hash(_winConditions),const DeepCollectionEquality().hash(_failConditions),thumbnailPath,createdBy,isPublic,createdAt,updatedAt);

@override
String toString() {
  return 'Scenario(id: $id, title: $title, description: $description, initialState: $initialState, winConditions: $winConditions, failConditions: $failConditions, thumbnailPath: $thumbnailPath, createdBy: $createdBy, isPublic: $isPublic, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ScenarioCopyWith<$Res> implements $ScenarioCopyWith<$Res> {
  factory _$ScenarioCopyWith(_Scenario value, $Res Function(_Scenario) _then) = __$ScenarioCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description,@JsonKey(name: 'initial_state') Map<String, dynamic> initialState,@JsonKey(name: 'win_conditions') List<dynamic> winConditions,@JsonKey(name: 'fail_conditions') List<dynamic> failConditions,@JsonKey(name: 'thumbnail_path') String? thumbnailPath,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'is_public') bool isPublic,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$ScenarioCopyWithImpl<$Res>
    implements _$ScenarioCopyWith<$Res> {
  __$ScenarioCopyWithImpl(this._self, this._then);

  final _Scenario _self;
  final $Res Function(_Scenario) _then;

/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? initialState = null,Object? winConditions = null,Object? failConditions = null,Object? thumbnailPath = freezed,Object? createdBy = freezed,Object? isPublic = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Scenario(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,initialState: null == initialState ? _self._initialState : initialState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,winConditions: null == winConditions ? _self._winConditions : winConditions // ignore: cast_nullable_to_non_nullable
as List<dynamic>,failConditions: null == failConditions ? _self._failConditions : failConditions // ignore: cast_nullable_to_non_nullable
as List<dynamic>,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
