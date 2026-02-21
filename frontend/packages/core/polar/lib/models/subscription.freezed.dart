// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Subscription {

 String get id; DateTime get createdAt; DateTime? get modifiedAt; SubscriptionStatus get status; int get amount; String get currency; RecurringInterval get recurringInterval; DateTime get currentPeriodStart; DateTime? get currentPeriodEnd; bool get cancelAtPeriodEnd; DateTime? get canceledAt; DateTime? get startedAt; DateTime? get endsAt; DateTime? get endedAt; String get productId; String get priceId; String get customerId; Map<String, dynamic>? get metadata;
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<Subscription> get copyWith => _$SubscriptionCopyWithImpl<Subscription>(this as Subscription, _$identity);

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.recurringInterval, recurringInterval) || other.recurringInterval == recurringInterval)&&(identical(other.currentPeriodStart, currentPeriodStart) || other.currentPeriodStart == currentPeriodStart)&&(identical(other.currentPeriodEnd, currentPeriodEnd) || other.currentPeriodEnd == currentPeriodEnd)&&(identical(other.cancelAtPeriodEnd, cancelAtPeriodEnd) || other.cancelAtPeriodEnd == cancelAtPeriodEnd)&&(identical(other.canceledAt, canceledAt) || other.canceledAt == canceledAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.priceId, priceId) || other.priceId == priceId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,modifiedAt,status,amount,currency,recurringInterval,currentPeriodStart,currentPeriodEnd,cancelAtPeriodEnd,canceledAt,startedAt,endsAt,endedAt,productId,priceId,customerId,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'Subscription(id: $id, createdAt: $createdAt, modifiedAt: $modifiedAt, status: $status, amount: $amount, currency: $currency, recurringInterval: $recurringInterval, currentPeriodStart: $currentPeriodStart, currentPeriodEnd: $currentPeriodEnd, cancelAtPeriodEnd: $cancelAtPeriodEnd, canceledAt: $canceledAt, startedAt: $startedAt, endsAt: $endsAt, endedAt: $endedAt, productId: $productId, priceId: $priceId, customerId: $customerId, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $SubscriptionCopyWith<$Res>  {
  factory $SubscriptionCopyWith(Subscription value, $Res Function(Subscription) _then) = _$SubscriptionCopyWithImpl;
@useResult
$Res call({
 String id, DateTime createdAt, DateTime? modifiedAt, SubscriptionStatus status, int amount, String currency, RecurringInterval recurringInterval, DateTime currentPeriodStart, DateTime? currentPeriodEnd, bool cancelAtPeriodEnd, DateTime? canceledAt, DateTime? startedAt, DateTime? endsAt, DateTime? endedAt, String productId, String priceId, String customerId, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$SubscriptionCopyWithImpl<$Res>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._self, this._then);

  final Subscription _self;
  final $Res Function(Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? modifiedAt = freezed,Object? status = null,Object? amount = null,Object? currency = null,Object? recurringInterval = null,Object? currentPeriodStart = null,Object? currentPeriodEnd = freezed,Object? cancelAtPeriodEnd = null,Object? canceledAt = freezed,Object? startedAt = freezed,Object? endsAt = freezed,Object? endedAt = freezed,Object? productId = null,Object? priceId = null,Object? customerId = null,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,recurringInterval: null == recurringInterval ? _self.recurringInterval : recurringInterval // ignore: cast_nullable_to_non_nullable
as RecurringInterval,currentPeriodStart: null == currentPeriodStart ? _self.currentPeriodStart : currentPeriodStart // ignore: cast_nullable_to_non_nullable
as DateTime,currentPeriodEnd: freezed == currentPeriodEnd ? _self.currentPeriodEnd : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelAtPeriodEnd: null == cancelAtPeriodEnd ? _self.cancelAtPeriodEnd : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
as bool,canceledAt: freezed == canceledAt ? _self.canceledAt : canceledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,priceId: null == priceId ? _self.priceId : priceId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Subscription].
extension SubscriptionPatterns on Subscription {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subscription value)  $default,){
final _that = this;
switch (_that) {
case _Subscription():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subscription value)?  $default,){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  SubscriptionStatus status,  int amount,  String currency,  RecurringInterval recurringInterval,  DateTime currentPeriodStart,  DateTime? currentPeriodEnd,  bool cancelAtPeriodEnd,  DateTime? canceledAt,  DateTime? startedAt,  DateTime? endsAt,  DateTime? endedAt,  String productId,  String priceId,  String customerId,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.status,_that.amount,_that.currency,_that.recurringInterval,_that.currentPeriodStart,_that.currentPeriodEnd,_that.cancelAtPeriodEnd,_that.canceledAt,_that.startedAt,_that.endsAt,_that.endedAt,_that.productId,_that.priceId,_that.customerId,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  SubscriptionStatus status,  int amount,  String currency,  RecurringInterval recurringInterval,  DateTime currentPeriodStart,  DateTime? currentPeriodEnd,  bool cancelAtPeriodEnd,  DateTime? canceledAt,  DateTime? startedAt,  DateTime? endsAt,  DateTime? endedAt,  String productId,  String priceId,  String customerId,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _Subscription():
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.status,_that.amount,_that.currency,_that.recurringInterval,_that.currentPeriodStart,_that.currentPeriodEnd,_that.cancelAtPeriodEnd,_that.canceledAt,_that.startedAt,_that.endsAt,_that.endedAt,_that.productId,_that.priceId,_that.customerId,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime createdAt,  DateTime? modifiedAt,  SubscriptionStatus status,  int amount,  String currency,  RecurringInterval recurringInterval,  DateTime currentPeriodStart,  DateTime? currentPeriodEnd,  bool cancelAtPeriodEnd,  DateTime? canceledAt,  DateTime? startedAt,  DateTime? endsAt,  DateTime? endedAt,  String productId,  String priceId,  String customerId,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.createdAt,_that.modifiedAt,_that.status,_that.amount,_that.currency,_that.recurringInterval,_that.currentPeriodStart,_that.currentPeriodEnd,_that.cancelAtPeriodEnd,_that.canceledAt,_that.startedAt,_that.endsAt,_that.endedAt,_that.productId,_that.priceId,_that.customerId,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subscription implements Subscription {
  const _Subscription({required this.id, required this.createdAt, this.modifiedAt, required this.status, required this.amount, required this.currency, required this.recurringInterval, required this.currentPeriodStart, this.currentPeriodEnd, required this.cancelAtPeriodEnd, this.canceledAt, this.startedAt, this.endsAt, this.endedAt, required this.productId, required this.priceId, required this.customerId, final  Map<String, dynamic>? metadata}): _metadata = metadata;
  factory _Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

@override final  String id;
@override final  DateTime createdAt;
@override final  DateTime? modifiedAt;
@override final  SubscriptionStatus status;
@override final  int amount;
@override final  String currency;
@override final  RecurringInterval recurringInterval;
@override final  DateTime currentPeriodStart;
@override final  DateTime? currentPeriodEnd;
@override final  bool cancelAtPeriodEnd;
@override final  DateTime? canceledAt;
@override final  DateTime? startedAt;
@override final  DateTime? endsAt;
@override final  DateTime? endedAt;
@override final  String productId;
@override final  String priceId;
@override final  String customerId;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionCopyWith<_Subscription> get copyWith => __$SubscriptionCopyWithImpl<_Subscription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.recurringInterval, recurringInterval) || other.recurringInterval == recurringInterval)&&(identical(other.currentPeriodStart, currentPeriodStart) || other.currentPeriodStart == currentPeriodStart)&&(identical(other.currentPeriodEnd, currentPeriodEnd) || other.currentPeriodEnd == currentPeriodEnd)&&(identical(other.cancelAtPeriodEnd, cancelAtPeriodEnd) || other.cancelAtPeriodEnd == cancelAtPeriodEnd)&&(identical(other.canceledAt, canceledAt) || other.canceledAt == canceledAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.priceId, priceId) || other.priceId == priceId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,modifiedAt,status,amount,currency,recurringInterval,currentPeriodStart,currentPeriodEnd,cancelAtPeriodEnd,canceledAt,startedAt,endsAt,endedAt,productId,priceId,customerId,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'Subscription(id: $id, createdAt: $createdAt, modifiedAt: $modifiedAt, status: $status, amount: $amount, currency: $currency, recurringInterval: $recurringInterval, currentPeriodStart: $currentPeriodStart, currentPeriodEnd: $currentPeriodEnd, cancelAtPeriodEnd: $cancelAtPeriodEnd, canceledAt: $canceledAt, startedAt: $startedAt, endsAt: $endsAt, endedAt: $endedAt, productId: $productId, priceId: $priceId, customerId: $customerId, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionCopyWith<$Res> implements $SubscriptionCopyWith<$Res> {
  factory _$SubscriptionCopyWith(_Subscription value, $Res Function(_Subscription) _then) = __$SubscriptionCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime createdAt, DateTime? modifiedAt, SubscriptionStatus status, int amount, String currency, RecurringInterval recurringInterval, DateTime currentPeriodStart, DateTime? currentPeriodEnd, bool cancelAtPeriodEnd, DateTime? canceledAt, DateTime? startedAt, DateTime? endsAt, DateTime? endedAt, String productId, String priceId, String customerId, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$SubscriptionCopyWithImpl<$Res>
    implements _$SubscriptionCopyWith<$Res> {
  __$SubscriptionCopyWithImpl(this._self, this._then);

  final _Subscription _self;
  final $Res Function(_Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? modifiedAt = freezed,Object? status = null,Object? amount = null,Object? currency = null,Object? recurringInterval = null,Object? currentPeriodStart = null,Object? currentPeriodEnd = freezed,Object? cancelAtPeriodEnd = null,Object? canceledAt = freezed,Object? startedAt = freezed,Object? endsAt = freezed,Object? endedAt = freezed,Object? productId = null,Object? priceId = null,Object? customerId = null,Object? metadata = freezed,}) {
  return _then(_Subscription(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,recurringInterval: null == recurringInterval ? _self.recurringInterval : recurringInterval // ignore: cast_nullable_to_non_nullable
as RecurringInterval,currentPeriodStart: null == currentPeriodStart ? _self.currentPeriodStart : currentPeriodStart // ignore: cast_nullable_to_non_nullable
as DateTime,currentPeriodEnd: freezed == currentPeriodEnd ? _self.currentPeriodEnd : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelAtPeriodEnd: null == cancelAtPeriodEnd ? _self.cancelAtPeriodEnd : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
as bool,canceledAt: freezed == canceledAt ? _self.canceledAt : canceledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,priceId: null == priceId ? _self.priceId : priceId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
