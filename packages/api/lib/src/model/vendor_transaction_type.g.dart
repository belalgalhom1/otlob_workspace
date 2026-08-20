// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_transaction_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const VendorTransactionType _$ORDER_REVENUE = const VendorTransactionType._(
  'ORDER_REVENUE',
);
const VendorTransactionType _$COMMISSION_DEDUCTION =
    const VendorTransactionType._('COMMISSION_DEDUCTION');
const VendorTransactionType _$CASH_COLLECTED = const VendorTransactionType._(
  'CASH_COLLECTED',
);
const VendorTransactionType _$PAYOUT = const VendorTransactionType._('PAYOUT');
const VendorTransactionType _$REFUND = const VendorTransactionType._('REFUND');
const VendorTransactionType _$ADJUSTMENT = const VendorTransactionType._(
  'ADJUSTMENT',
);

VendorTransactionType _$valueOf(String name) {
  switch (name) {
    case 'ORDER_REVENUE':
      return _$ORDER_REVENUE;
    case 'COMMISSION_DEDUCTION':
      return _$COMMISSION_DEDUCTION;
    case 'CASH_COLLECTED':
      return _$CASH_COLLECTED;
    case 'PAYOUT':
      return _$PAYOUT;
    case 'REFUND':
      return _$REFUND;
    case 'ADJUSTMENT':
      return _$ADJUSTMENT;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<VendorTransactionType> _$values =
    BuiltSet<VendorTransactionType>(const <VendorTransactionType>[
      _$ORDER_REVENUE,
      _$COMMISSION_DEDUCTION,
      _$CASH_COLLECTED,
      _$PAYOUT,
      _$REFUND,
      _$ADJUSTMENT,
    ]);

class _$VendorTransactionTypeMeta {
  const _$VendorTransactionTypeMeta();
  VendorTransactionType get ORDER_REVENUE => _$ORDER_REVENUE;
  VendorTransactionType get COMMISSION_DEDUCTION => _$COMMISSION_DEDUCTION;
  VendorTransactionType get CASH_COLLECTED => _$CASH_COLLECTED;
  VendorTransactionType get PAYOUT => _$PAYOUT;
  VendorTransactionType get REFUND => _$REFUND;
  VendorTransactionType get ADJUSTMENT => _$ADJUSTMENT;
  VendorTransactionType valueOf(String name) => _$valueOf(name);
  BuiltSet<VendorTransactionType> get values => _$values;
}

mixin _$VendorTransactionTypeMixin {
  // ignore: non_constant_identifier_names
  _$VendorTransactionTypeMeta get VendorTransactionType =>
      const _$VendorTransactionTypeMeta();
}

Serializer<VendorTransactionType> _$vendorTransactionTypeSerializer =
    _$VendorTransactionTypeSerializer();

class _$VendorTransactionTypeSerializer
    implements PrimitiveSerializer<VendorTransactionType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ORDER_REVENUE': 'ORDER_REVENUE',
    'COMMISSION_DEDUCTION': 'COMMISSION_DEDUCTION',
    'CASH_COLLECTED': 'CASH_COLLECTED',
    'PAYOUT': 'PAYOUT',
    'REFUND': 'REFUND',
    'ADJUSTMENT': 'ADJUSTMENT',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ORDER_REVENUE': 'ORDER_REVENUE',
    'COMMISSION_DEDUCTION': 'COMMISSION_DEDUCTION',
    'CASH_COLLECTED': 'CASH_COLLECTED',
    'PAYOUT': 'PAYOUT',
    'REFUND': 'REFUND',
    'ADJUSTMENT': 'ADJUSTMENT',
  };

  @override
  final Iterable<Type> types = const <Type>[VendorTransactionType];
  @override
  final String wireName = 'VendorTransactionType';

  @override
  Object serialize(
    Serializers serializers,
    VendorTransactionType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  VendorTransactionType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => VendorTransactionType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
