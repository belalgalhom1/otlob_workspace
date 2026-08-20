// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_transaction_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CoinTransactionType _$EARNED = const CoinTransactionType._('EARNED');
const CoinTransactionType _$SPENT = const CoinTransactionType._('SPENT');
const CoinTransactionType _$REFUNDED = const CoinTransactionType._('REFUNDED');

CoinTransactionType _$valueOf(String name) {
  switch (name) {
    case 'EARNED':
      return _$EARNED;
    case 'SPENT':
      return _$SPENT;
    case 'REFUNDED':
      return _$REFUNDED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CoinTransactionType> _$values = BuiltSet<CoinTransactionType>(
  const <CoinTransactionType>[_$EARNED, _$SPENT, _$REFUNDED],
);

class _$CoinTransactionTypeMeta {
  const _$CoinTransactionTypeMeta();
  CoinTransactionType get EARNED => _$EARNED;
  CoinTransactionType get SPENT => _$SPENT;
  CoinTransactionType get REFUNDED => _$REFUNDED;
  CoinTransactionType valueOf(String name) => _$valueOf(name);
  BuiltSet<CoinTransactionType> get values => _$values;
}

mixin _$CoinTransactionTypeMixin {
  // ignore: non_constant_identifier_names
  _$CoinTransactionTypeMeta get CoinTransactionType =>
      const _$CoinTransactionTypeMeta();
}

Serializer<CoinTransactionType> _$coinTransactionTypeSerializer =
    _$CoinTransactionTypeSerializer();

class _$CoinTransactionTypeSerializer
    implements PrimitiveSerializer<CoinTransactionType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'EARNED': 'EARNED',
    'SPENT': 'SPENT',
    'REFUNDED': 'REFUNDED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'EARNED': 'EARNED',
    'SPENT': 'SPENT',
    'REFUNDED': 'REFUNDED',
  };

  @override
  final Iterable<Type> types = const <Type>[CoinTransactionType];
  @override
  final String wireName = 'CoinTransactionType';

  @override
  Object serialize(
    Serializers serializers,
    CoinTransactionType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CoinTransactionType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CoinTransactionType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
