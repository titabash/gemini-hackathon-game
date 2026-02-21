import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

/// Customer
///
/// Represents a Polar.sh customer account.
@freezed
class Customer with _$Customer {
  const factory Customer({
    required String id,
    required DateTime createdAt,
    DateTime? modifiedAt,
    required String email,
    String? name,
    Map<String, dynamic>? metadata,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
