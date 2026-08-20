//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'vendor_transaction_type.g.dart';

class VendorTransactionType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ORDER_REVENUE')
  static const VendorTransactionType ORDER_REVENUE = _$ORDER_REVENUE;
  @BuiltValueEnumConst(wireName: r'COMMISSION_DEDUCTION')
  static const VendorTransactionType COMMISSION_DEDUCTION = _$COMMISSION_DEDUCTION;
  @BuiltValueEnumConst(wireName: r'CASH_COLLECTED')
  static const VendorTransactionType CASH_COLLECTED = _$CASH_COLLECTED;
  @BuiltValueEnumConst(wireName: r'PAYOUT')
  static const VendorTransactionType PAYOUT = _$PAYOUT;
  @BuiltValueEnumConst(wireName: r'REFUND')
  static const VendorTransactionType REFUND = _$REFUND;
  @BuiltValueEnumConst(wireName: r'ADJUSTMENT')
  static const VendorTransactionType ADJUSTMENT = _$ADJUSTMENT;

  static Serializer<VendorTransactionType> get serializer => _$vendorTransactionTypeSerializer;

  const VendorTransactionType._(String name): super(name);

  static BuiltSet<VendorTransactionType> get values => _$values;
  static VendorTransactionType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class VendorTransactionTypeMixin = Object with _$VendorTransactionTypeMixin;

