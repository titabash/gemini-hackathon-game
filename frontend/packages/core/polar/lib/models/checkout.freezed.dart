// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Checkout {

 String get id; DateTime get createdAt; DateTime? get modifiedAt; CheckoutStatus get status; String get clientSecret; String get url; DateTime get expiresAt; String get successUrl; int? get amount; String? get currency; String get productId; String get productPriceId; String? get customerId; String? get customerEmail; String? get customerName; Map<String, dynamic>? get metadata;
/// Create a copy of Checkout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutCopyWith<Checkout> get copyWith => _$CheckoutCopyWithImpl<Checkout>(this as Checkout, _$identity);

  /// Serializes this Checkout to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Checkout&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.clientSecret, clientSecret) || other.clientSecret == clientSecret)&&(identical(other.url, url) || other.url == url)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.successUrl, successUrl) || other.successUrl == successUrl)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productPriceId, productPriceId) || other.productPriceId == productPriceId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerEmail, customerEmail) || other.customerEmail == customerEmail)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,modifiedAt,status,clientSecret,url,expiresAt,successUrl,amount,currency,productId,productPriceId,customerId,customerEmail,customerName,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'Checkout(id: $id, createdAt: $createdAt, modifiedAt: $modifiedAt, status: $status, clientSecret: $clientSecret, url: $url, expiresAt: $expiresAt, successUrl: $successUrl, amount: $amount, currency: $currency, productId: $productId, productPriceId: $productPriceId, customerId: $customerId, customerEmail: $customerEmail, customerName: $customerName, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $CheckoutCopyWith<$Res>  {
  factory $CheckoutCopyWith(Checkout value, $Res Function(Checkout) _then) = _$CheckoutCopyWithImpl;
@useResult
$Res call({
 String id, DateTime createdAt, DateTime? modifiedAt, CheckoutStatus status, String clientSecret, String url, DateTime expiresAt, String successUrl, int? amount, String? currency, String productId, String productPriceId, String? customerId, String? customerEmail, String? customerName, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$CheckoutCopyWithImpl<$Res>
    implements $CheckoutCopyWith<$Res> {
  _$CheckoutCopyWithImpl(this._self, this._then);

  final Checkout _self;
  final $Res Function(Checkout) _then;

/// Create a copy of Checkout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? modifiedAt = freezed,Object? status = null,Object? clientSecret = null,Object? url = null,Object? expiresAt = null,Object? successUrl = null,Object? amount = freezed,Object? currency = freezed,Object? productId = null,Object? productPriceId = null,Object? customerId = freezed,Object? customerEmail = freezed,Object? customerName = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CheckoutStatus,clientSecret: null == clientSecret ? _self.clientSecret : clientSecret // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,successUrl: null == successUrl ? _self.successUrl : successUrl // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productPriceId: null == productPriceId ? _self.productPriceId : productPriceId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,customerEmail: freezed == customerEmail ? _self.customerEmail : customerEmail // ignore: cast_nullable_to_non_nullable
as String?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Checkout].
extension CheckoutPatterns on Checkout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Checkout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Checkout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Checkout value)  $default,){
final _that = this;
switch (_that) {
case _Checkout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Checkout value)?  $default,){
final _that = this;
switch (_that) {
case _Checkout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  CheckoutStatus status,  String clientSecret,  String url,  DateTime expiresAt,  String successUrl,  int? amount,  String? currency,  String productId,  String productPriceId,  String? customerId,  String? customerEmail,  String? customerName,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Checkout() when $default != null:
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.status,_that.clientSecret,_that.url,_that.expiresAt,_that.successUrl,_that.amount,_that.currency,_that.productId,_that.productPriceId,_that.customerId,_that.customerEmail,_that.customerName,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  CheckoutStatus status,  String clientSecret,  String url,  DateTime expiresAt,  String successUrl,  int? amount,  String? currency,  String productId,  String productPriceId,  String? customerId,  String? customerEmail,  String? customerName,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _Checkout():
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.status,_that.clientSecret,_that.url,_that.expiresAt,_that.successUrl,_that.amount,_that.currency,_that.productId,_that.productPriceId,_that.customerId,_that.customerEmail,_that.customerName,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  CheckoutStatus status,  String clientSecret,  String url,  DateTime expiresAt,  String successUrl,  int? amount,  String? currency,  String productId,  String productPriceId,  String? customerId,  String? customerEmail,  String? customerName,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _Checkout() when $default != null:
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.status,_that.clientSecret,_that.url,_that.expiresAt,_that.successUrl,_that.amount,_that.currency,_that.productId,_that.productPriceId,_that.customerId,_that.customerEmail,_that.customerName,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Checkout implements Checkout {
  const _Checkout({required this.id, required this.createdAt, this.modifiedAt, required this.status, required this.clientSecret, required this.url, required this.expiresAt, required this.successUrl, this.amount, this.currency, required this.productId, required this.productPriceId, this.customerId, this.customerEmail, this.customerName, final  Map<String, dynamic>? metadata}): _metadata = metadata;
  factory _Checkout.fromJson(Map<String, dynamic> json) => _$CheckoutFromJson(json);

@override final  String id;
@override final  DateTime createdAt;
@override final  DateTime? modifiedAt;
@override final  CheckoutStatus status;
@override final  String clientSecret;
@override final  String url;
@override final  DateTime expiresAt;
@override final  String successUrl;
@override final  int? amount;
@override final  String? currency;
@override final  String productId;
@override final  String productPriceId;
@override final  String? customerId;
@override final  String? customerEmail;
@override final  String? customerName;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Checkout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutCopyWith<_Checkout> get copyWith => __$CheckoutCopyWithImpl<_Checkout>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Checkout&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.clientSecret, clientSecret) || other.clientSecret == clientSecret)&&(identical(other.url, url) || other.url == url)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.successUrl, successUrl) || other.successUrl == successUrl)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productPriceId, productPriceId) || other.productPriceId == productPriceId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerEmail, customerEmail) || other.customerEmail == customerEmail)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,modifiedAt,status,clientSecret,url,expiresAt,successUrl,amount,currency,productId,productPriceId,customerId,customerEmail,customerName,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'Checkout(id: $id, createdAt: $createdAt, modifiedAt: $modifiedAt, status: $status, clientSecret: $clientSecret, url: $url, expiresAt: $expiresAt, successUrl: $successUrl, amount: $amount, currency: $currency, productId: $productId, productPriceId: $productPriceId, customerId: $customerId, customerEmail: $customerEmail, customerName: $customerName, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$CheckoutCopyWith<$Res> implements $CheckoutCopyWith<$Res> {
  factory _$CheckoutCopyWith(_Checkout value, $Res Function(_Checkout) _then) = __$CheckoutCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime createdAt, DateTime? modifiedAt, CheckoutStatus status, String clientSecret, String url, DateTime expiresAt, String successUrl, int? amount, String? currency, String productId, String productPriceId, String? customerId, String? customerEmail, String? customerName, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$CheckoutCopyWithImpl<$Res>
    implements _$CheckoutCopyWith<$Res> {
  __$CheckoutCopyWithImpl(this._self, this._then);

  final _Checkout _self;
  final $Res Function(_Checkout) _then;

/// Create a copy of Checkout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? modifiedAt = freezed,Object? status = null,Object? clientSecret = null,Object? url = null,Object? expiresAt = null,Object? successUrl = null,Object? amount = freezed,Object? currency = freezed,Object? productId = null,Object? productPriceId = null,Object? customerId = freezed,Object? customerEmail = freezed,Object? customerName = freezed,Object? metadata = freezed,}) {
  return _then(_Checkout(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CheckoutStatus,clientSecret: null == clientSecret ? _self.clientSecret : clientSecret // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,successUrl: null == successUrl ? _self.successUrl : successUrl // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productPriceId: null == productPriceId ? _self.productPriceId : productPriceId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,customerEmail: freezed == customerEmail ? _self.customerEmail : customerEmail // ignore: cast_nullable_to_non_nullable
as String?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
