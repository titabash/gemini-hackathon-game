// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductPrice {

 String get id; DateTime get createdAt; DateTime? get modifiedAt; ProductPriceType get type; int get priceAmount; String get priceCurrency; RecurringInterval? get recurringInterval;
/// Create a copy of ProductPrice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductPriceCopyWith<ProductPrice> get copyWith => _$ProductPriceCopyWithImpl<ProductPrice>(this as ProductPrice, _$identity);

  /// Serializes this ProductPrice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductPrice&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&(identical(other.type, type) || other.type == type)&&(identical(other.priceAmount, priceAmount) || other.priceAmount == priceAmount)&&(identical(other.priceCurrency, priceCurrency) || other.priceCurrency == priceCurrency)&&(identical(other.recurringInterval, recurringInterval) || other.recurringInterval == recurringInterval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,modifiedAt,type,priceAmount,priceCurrency,recurringInterval);

@override
String toString() {
  return 'ProductPrice(id: $id, createdAt: $createdAt, modifiedAt: $modifiedAt, type: $type, priceAmount: $priceAmount, priceCurrency: $priceCurrency, recurringInterval: $recurringInterval)';
}


}

/// @nodoc
abstract mixin class $ProductPriceCopyWith<$Res>  {
  factory $ProductPriceCopyWith(ProductPrice value, $Res Function(ProductPrice) _then) = _$ProductPriceCopyWithImpl;
@useResult
$Res call({
 String id, DateTime createdAt, DateTime? modifiedAt, ProductPriceType type, int priceAmount, String priceCurrency, RecurringInterval? recurringInterval
});




}
/// @nodoc
class _$ProductPriceCopyWithImpl<$Res>
    implements $ProductPriceCopyWith<$Res> {
  _$ProductPriceCopyWithImpl(this._self, this._then);

  final ProductPrice _self;
  final $Res Function(ProductPrice) _then;

/// Create a copy of ProductPrice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? modifiedAt = freezed,Object? type = null,Object? priceAmount = null,Object? priceCurrency = null,Object? recurringInterval = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProductPriceType,priceAmount: null == priceAmount ? _self.priceAmount : priceAmount // ignore: cast_nullable_to_non_nullable
as int,priceCurrency: null == priceCurrency ? _self.priceCurrency : priceCurrency // ignore: cast_nullable_to_non_nullable
as String,recurringInterval: freezed == recurringInterval ? _self.recurringInterval : recurringInterval // ignore: cast_nullable_to_non_nullable
as RecurringInterval?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductPrice].
extension ProductPricePatterns on ProductPrice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductPrice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductPrice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductPrice value)  $default,){
final _that = this;
switch (_that) {
case _ProductPrice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductPrice value)?  $default,){
final _that = this;
switch (_that) {
case _ProductPrice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  ProductPriceType type,  int priceAmount,  String priceCurrency,  RecurringInterval? recurringInterval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductPrice() when $default != null:
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.type,_that.priceAmount,_that.priceCurrency,_that.recurringInterval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  ProductPriceType type,  int priceAmount,  String priceCurrency,  RecurringInterval? recurringInterval)  $default,) {final _that = this;
switch (_that) {
case _ProductPrice():
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.type,_that.priceAmount,_that.priceCurrency,_that.recurringInterval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  ProductPriceType type,  int priceAmount,  String priceCurrency,  RecurringInterval? recurringInterval)?  $default,) {final _that = this;
switch (_that) {
case _ProductPrice() when $default != null:
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.type,_that.priceAmount,_that.priceCurrency,_that.recurringInterval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductPrice implements ProductPrice {
  const _ProductPrice({required this.id, required this.createdAt, this.modifiedAt, required this.type, required this.priceAmount, required this.priceCurrency, this.recurringInterval});
  factory _ProductPrice.fromJson(Map<String, dynamic> json) => _$ProductPriceFromJson(json);

@override final  String id;
@override final  DateTime createdAt;
@override final  DateTime? modifiedAt;
@override final  ProductPriceType type;
@override final  int priceAmount;
@override final  String priceCurrency;
@override final  RecurringInterval? recurringInterval;

/// Create a copy of ProductPrice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductPriceCopyWith<_ProductPrice> get copyWith => __$ProductPriceCopyWithImpl<_ProductPrice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductPriceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductPrice&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&(identical(other.type, type) || other.type == type)&&(identical(other.priceAmount, priceAmount) || other.priceAmount == priceAmount)&&(identical(other.priceCurrency, priceCurrency) || other.priceCurrency == priceCurrency)&&(identical(other.recurringInterval, recurringInterval) || other.recurringInterval == recurringInterval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,modifiedAt,type,priceAmount,priceCurrency,recurringInterval);

@override
String toString() {
  return 'ProductPrice(id: $id, createdAt: $createdAt, modifiedAt: $modifiedAt, type: $type, priceAmount: $priceAmount, priceCurrency: $priceCurrency, recurringInterval: $recurringInterval)';
}


}

/// @nodoc
abstract mixin class _$ProductPriceCopyWith<$Res> implements $ProductPriceCopyWith<$Res> {
  factory _$ProductPriceCopyWith(_ProductPrice value, $Res Function(_ProductPrice) _then) = __$ProductPriceCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime createdAt, DateTime? modifiedAt, ProductPriceType type, int priceAmount, String priceCurrency, RecurringInterval? recurringInterval
});




}
/// @nodoc
class __$ProductPriceCopyWithImpl<$Res>
    implements _$ProductPriceCopyWith<$Res> {
  __$ProductPriceCopyWithImpl(this._self, this._then);

  final _ProductPrice _self;
  final $Res Function(_ProductPrice) _then;

/// Create a copy of ProductPrice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? modifiedAt = freezed,Object? type = null,Object? priceAmount = null,Object? priceCurrency = null,Object? recurringInterval = freezed,}) {
  return _then(_ProductPrice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProductPriceType,priceAmount: null == priceAmount ? _self.priceAmount : priceAmount // ignore: cast_nullable_to_non_nullable
as int,priceCurrency: null == priceCurrency ? _self.priceCurrency : priceCurrency // ignore: cast_nullable_to_non_nullable
as String,recurringInterval: freezed == recurringInterval ? _self.recurringInterval : recurringInterval // ignore: cast_nullable_to_non_nullable
as RecurringInterval?,
  ));
}


}


/// @nodoc
mixin _$ProductBenefit {

 String get id; String get type;
/// Create a copy of ProductBenefit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductBenefitCopyWith<ProductBenefit> get copyWith => _$ProductBenefitCopyWithImpl<ProductBenefit>(this as ProductBenefit, _$identity);

  /// Serializes this ProductBenefit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductBenefit&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type);

@override
String toString() {
  return 'ProductBenefit(id: $id, type: $type)';
}


}

/// @nodoc
abstract mixin class $ProductBenefitCopyWith<$Res>  {
  factory $ProductBenefitCopyWith(ProductBenefit value, $Res Function(ProductBenefit) _then) = _$ProductBenefitCopyWithImpl;
@useResult
$Res call({
 String id, String type
});




}
/// @nodoc
class _$ProductBenefitCopyWithImpl<$Res>
    implements $ProductBenefitCopyWith<$Res> {
  _$ProductBenefitCopyWithImpl(this._self, this._then);

  final ProductBenefit _self;
  final $Res Function(ProductBenefit) _then;

/// Create a copy of ProductBenefit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductBenefit].
extension ProductBenefitPatterns on ProductBenefit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductBenefit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductBenefit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductBenefit value)  $default,){
final _that = this;
switch (_that) {
case _ProductBenefit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductBenefit value)?  $default,){
final _that = this;
switch (_that) {
case _ProductBenefit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductBenefit() when $default != null:
return $default(_that.id,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type)  $default,) {final _that = this;
switch (_that) {
case _ProductBenefit():
return $default(_that.id,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type)?  $default,) {final _that = this;
switch (_that) {
case _ProductBenefit() when $default != null:
return $default(_that.id,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductBenefit implements ProductBenefit {
  const _ProductBenefit({required this.id, required this.type});
  factory _ProductBenefit.fromJson(Map<String, dynamic> json) => _$ProductBenefitFromJson(json);

@override final  String id;
@override final  String type;

/// Create a copy of ProductBenefit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductBenefitCopyWith<_ProductBenefit> get copyWith => __$ProductBenefitCopyWithImpl<_ProductBenefit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductBenefitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductBenefit&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type);

@override
String toString() {
  return 'ProductBenefit(id: $id, type: $type)';
}


}

/// @nodoc
abstract mixin class _$ProductBenefitCopyWith<$Res> implements $ProductBenefitCopyWith<$Res> {
  factory _$ProductBenefitCopyWith(_ProductBenefit value, $Res Function(_ProductBenefit) _then) = __$ProductBenefitCopyWithImpl;
@override @useResult
$Res call({
 String id, String type
});




}
/// @nodoc
class __$ProductBenefitCopyWithImpl<$Res>
    implements _$ProductBenefitCopyWith<$Res> {
  __$ProductBenefitCopyWithImpl(this._self, this._then);

  final _ProductBenefit _self;
  final $Res Function(_ProductBenefit) _then;

/// Create a copy of ProductBenefit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,}) {
  return _then(_ProductBenefit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProductMedia {

 String get id; String get publicUrl;
/// Create a copy of ProductMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductMediaCopyWith<ProductMedia> get copyWith => _$ProductMediaCopyWithImpl<ProductMedia>(this as ProductMedia, _$identity);

  /// Serializes this ProductMedia to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.publicUrl, publicUrl) || other.publicUrl == publicUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,publicUrl);

@override
String toString() {
  return 'ProductMedia(id: $id, publicUrl: $publicUrl)';
}


}

/// @nodoc
abstract mixin class $ProductMediaCopyWith<$Res>  {
  factory $ProductMediaCopyWith(ProductMedia value, $Res Function(ProductMedia) _then) = _$ProductMediaCopyWithImpl;
@useResult
$Res call({
 String id, String publicUrl
});




}
/// @nodoc
class _$ProductMediaCopyWithImpl<$Res>
    implements $ProductMediaCopyWith<$Res> {
  _$ProductMediaCopyWithImpl(this._self, this._then);

  final ProductMedia _self;
  final $Res Function(ProductMedia) _then;

/// Create a copy of ProductMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? publicUrl = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,publicUrl: null == publicUrl ? _self.publicUrl : publicUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductMedia].
extension ProductMediaPatterns on ProductMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductMedia value)  $default,){
final _that = this;
switch (_that) {
case _ProductMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductMedia value)?  $default,){
final _that = this;
switch (_that) {
case _ProductMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String publicUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductMedia() when $default != null:
return $default(_that.id,_that.publicUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String publicUrl)  $default,) {final _that = this;
switch (_that) {
case _ProductMedia():
return $default(_that.id,_that.publicUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String publicUrl)?  $default,) {final _that = this;
switch (_that) {
case _ProductMedia() when $default != null:
return $default(_that.id,_that.publicUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductMedia implements ProductMedia {
  const _ProductMedia({required this.id, required this.publicUrl});
  factory _ProductMedia.fromJson(Map<String, dynamic> json) => _$ProductMediaFromJson(json);

@override final  String id;
@override final  String publicUrl;

/// Create a copy of ProductMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductMediaCopyWith<_ProductMedia> get copyWith => __$ProductMediaCopyWithImpl<_ProductMedia>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductMediaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.publicUrl, publicUrl) || other.publicUrl == publicUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,publicUrl);

@override
String toString() {
  return 'ProductMedia(id: $id, publicUrl: $publicUrl)';
}


}

/// @nodoc
abstract mixin class _$ProductMediaCopyWith<$Res> implements $ProductMediaCopyWith<$Res> {
  factory _$ProductMediaCopyWith(_ProductMedia value, $Res Function(_ProductMedia) _then) = __$ProductMediaCopyWithImpl;
@override @useResult
$Res call({
 String id, String publicUrl
});




}
/// @nodoc
class __$ProductMediaCopyWithImpl<$Res>
    implements _$ProductMediaCopyWith<$Res> {
  __$ProductMediaCopyWithImpl(this._self, this._then);

  final _ProductMedia _self;
  final $Res Function(_ProductMedia) _then;

/// Create a copy of ProductMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? publicUrl = null,}) {
  return _then(_ProductMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,publicUrl: null == publicUrl ? _self.publicUrl : publicUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Product {

 String get id; DateTime get createdAt; DateTime? get modifiedAt; String get name; String? get description; bool get isArchived; String get organizationId; List<ProductPrice> get prices; List<ProductBenefit> get benefits; List<ProductMedia> get medias;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&const DeepCollectionEquality().equals(other.prices, prices)&&const DeepCollectionEquality().equals(other.benefits, benefits)&&const DeepCollectionEquality().equals(other.medias, medias));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,modifiedAt,name,description,isArchived,organizationId,const DeepCollectionEquality().hash(prices),const DeepCollectionEquality().hash(benefits),const DeepCollectionEquality().hash(medias));

@override
String toString() {
  return 'Product(id: $id, createdAt: $createdAt, modifiedAt: $modifiedAt, name: $name, description: $description, isArchived: $isArchived, organizationId: $organizationId, prices: $prices, benefits: $benefits, medias: $medias)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String id, DateTime createdAt, DateTime? modifiedAt, String name, String? description, bool isArchived, String organizationId, List<ProductPrice> prices, List<ProductBenefit> benefits, List<ProductMedia> medias
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? modifiedAt = freezed,Object? name = null,Object? description = freezed,Object? isArchived = null,Object? organizationId = null,Object? prices = null,Object? benefits = null,Object? medias = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,prices: null == prices ? _self.prices : prices // ignore: cast_nullable_to_non_nullable
as List<ProductPrice>,benefits: null == benefits ? _self.benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<ProductBenefit>,medias: null == medias ? _self.medias : medias // ignore: cast_nullable_to_non_nullable
as List<ProductMedia>,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  String name,  String? description,  bool isArchived,  String organizationId,  List<ProductPrice> prices,  List<ProductBenefit> benefits,  List<ProductMedia> medias)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.name,_that.description,_that.isArchived,_that.organizationId,_that.prices,_that.benefits,_that.medias);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  String name,  String? description,  bool isArchived,  String organizationId,  List<ProductPrice> prices,  List<ProductBenefit> benefits,  List<ProductMedia> medias)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.name,_that.description,_that.isArchived,_that.organizationId,_that.prices,_that.benefits,_that.medias);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  String name,  String? description,  bool isArchived,  String organizationId,  List<ProductPrice> prices,  List<ProductBenefit> benefits,  List<ProductMedia> medias)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.name,_that.description,_that.isArchived,_that.organizationId,_that.prices,_that.benefits,_that.medias);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({required this.id, required this.createdAt, this.modifiedAt, required this.name, this.description, required this.isArchived, required this.organizationId, required final  List<ProductPrice> prices, required final  List<ProductBenefit> benefits, required final  List<ProductMedia> medias}): _prices = prices,_benefits = benefits,_medias = medias;
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  String id;
@override final  DateTime createdAt;
@override final  DateTime? modifiedAt;
@override final  String name;
@override final  String? description;
@override final  bool isArchived;
@override final  String organizationId;
 final  List<ProductPrice> _prices;
@override List<ProductPrice> get prices {
  if (_prices is EqualUnmodifiableListView) return _prices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_prices);
}

 final  List<ProductBenefit> _benefits;
@override List<ProductBenefit> get benefits {
  if (_benefits is EqualUnmodifiableListView) return _benefits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_benefits);
}

 final  List<ProductMedia> _medias;
@override List<ProductMedia> get medias {
  if (_medias is EqualUnmodifiableListView) return _medias;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_medias);
}


/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&const DeepCollectionEquality().equals(other._prices, _prices)&&const DeepCollectionEquality().equals(other._benefits, _benefits)&&const DeepCollectionEquality().equals(other._medias, _medias));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,modifiedAt,name,description,isArchived,organizationId,const DeepCollectionEquality().hash(_prices),const DeepCollectionEquality().hash(_benefits),const DeepCollectionEquality().hash(_medias));

@override
String toString() {
  return 'Product(id: $id, createdAt: $createdAt, modifiedAt: $modifiedAt, name: $name, description: $description, isArchived: $isArchived, organizationId: $organizationId, prices: $prices, benefits: $benefits, medias: $medias)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime createdAt, DateTime? modifiedAt, String name, String? description, bool isArchived, String organizationId, List<ProductPrice> prices, List<ProductBenefit> benefits, List<ProductMedia> medias
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? modifiedAt = freezed,Object? name = null,Object? description = freezed,Object? isArchived = null,Object? organizationId = null,Object? prices = null,Object? benefits = null,Object? medias = null,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,prices: null == prices ? _self._prices : prices // ignore: cast_nullable_to_non_nullable
as List<ProductPrice>,benefits: null == benefits ? _self._benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<ProductBenefit>,medias: null == medias ? _self._medias : medias // ignore: cast_nullable_to_non_nullable
as List<ProductMedia>,
  ));
}


}

// dart format on
