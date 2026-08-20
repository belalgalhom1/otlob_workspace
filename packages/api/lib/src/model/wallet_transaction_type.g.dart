// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_transaction_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WalletTransactionType _$DELIVERY_FEE = const WalletTransactionType._(
  'DELIVERY_FEE',
);
const WalletTransactionType _$CASH_COLLECTED = const WalletTransactionType._(
  'CASH_COLLECTED',
);
const WalletTransactionType _$CASH_HANDED_TO_VENDOR =
    const WalletTransactionType._('CASH_HANDED_TO_VENDOR');
const WalletTransactionType _$PAYOUT = const WalletTransactionType._('PAYOUT');
const WalletTransactionType _$PENALTY = const WalletTransactionType._(
  'PENALTY',
);
const WalletTransactionType _$BONUS = const WalletTransactionType._('BONUS');
const WalletTransactionType _$ADJUSTMENT = const WalletTransactionType._(
  'ADJUSTMENT',
);

WalletTransactionType _$valueOf(String name) {
  switch (name) {
    case 'DELIVERY_FEE':
      return _$DELIVERY_FEE;
    case 'CASH_COLLECTED':
      return _$CASH_COLLECTED;
    case 'CASH_HANDED_TO_VENDOR':
      return _$CASH_HANDED_TO_VENDOR;
    case 'PAYOUT':
      return _$PAYOUT;
    case 'PENALTY':
      return _$PENALTY;
    case 'BONUS':
      return _$BONUS;
    case 'ADJUSTMENT':
      return _$ADJUSTMENT;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WalletTransactionType> _$values =
    BuiltSet<WalletTransactionType>(const <WalletTransactionType>[
      _$DELIVERY_FEE,
      _$CASH_COLLECTED,
      _$CASH_HANDED_TO_VENDOR,
      _$PAYOUT,
      _$PENALTY,
      _$BONUS,
      _$ADJUSTMENT,
    ]);

class _$WalletTransactionTypeMeta {
  const _$WalletTransactionTypeMeta();
  WalletTransactionType get DELIVERY_FEE => _$DELIVERY_FEE;
  WalletTransactionType get CASH_COLLECTED => _$CASH_COLLECTED;
  WalletTransactionType get CASH_HANDED_TO_VENDOR => _$CASH_HANDED_TO_VENDOR;
  WalletTransactionType get PAYOUT => _$PAYOUT;
  WalletTransactionType get PENALTY => _$PENALTY;
  WalletTransactionType get BONUS => _$BONUS;
  WalletTransactionType get ADJUSTMENT => _$ADJUSTMENT;
  WalletTransactionType valueOf(String name) => _$valueOf(name);
  BuiltSet<WalletTransactionType> get values => _$values;
}

mixin _$WalletTransactionTypeMixin {
  // ignore: non_constant_identifier_names
  _$WalletTransactionTypeMeta get WalletTransactionType =>
      const _$WalletTransactionTypeMeta();
}

Serializer<WalletTransactionType> _$walletTransactionTypeSerializer =
    _$WalletTransactionTypeSerializer();

class _$WalletTransactionTypeSerializer
    implements PrimitiveSerializer<WalletTransactionType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'DELIVERY_FEE': 'DELIVERY_FEE',
    'CASH_COLLECTED': 'CASH_COLLECTED',
    'CASH_HANDED_TO_VENDOR': 'CASH_HANDED_TO_VENDOR',
    'PAYOUT': 'PAYOUT',
    'PENALTY': 'PENALTY',
    'BONUS': 'BONUS',
    'ADJUSTMENT': 'ADJUSTMENT',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'DELIVERY_FEE': 'DELIVERY_FEE',
    'CASH_COLLECTED': 'CASH_COLLECTED',
    'CASH_HANDED_TO_VENDOR': 'CASH_HANDED_TO_VENDOR',
    'PAYOUT': 'PAYOUT',
    'PENALTY': 'PENALTY',
    'BONUS': 'BONUS',
    'ADJUSTMENT': 'ADJUSTMENT',
  };

  @override
  final Iterable<Type> types = const <Type>[WalletTransactionType];
  @override
  final String wireName = 'WalletTransactionType';

  @override
  Object serialize(
    Serializers serializers,
    WalletTransactionType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WalletTransactionType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WalletTransactionType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
