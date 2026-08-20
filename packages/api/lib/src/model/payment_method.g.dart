// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PaymentMethod _$CASH_ON_DELIVERY = const PaymentMethod._(
  'CASH_ON_DELIVERY',
);
const PaymentMethod _$MOBILE_WALLET = const PaymentMethod._('MOBILE_WALLET');

PaymentMethod _$valueOf(String name) {
  switch (name) {
    case 'CASH_ON_DELIVERY':
      return _$CASH_ON_DELIVERY;
    case 'MOBILE_WALLET':
      return _$MOBILE_WALLET;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PaymentMethod> _$values = BuiltSet<PaymentMethod>(
  const <PaymentMethod>[_$CASH_ON_DELIVERY, _$MOBILE_WALLET],
);

class _$PaymentMethodMeta {
  const _$PaymentMethodMeta();
  PaymentMethod get CASH_ON_DELIVERY => _$CASH_ON_DELIVERY;
  PaymentMethod get MOBILE_WALLET => _$MOBILE_WALLET;
  PaymentMethod valueOf(String name) => _$valueOf(name);
  BuiltSet<PaymentMethod> get values => _$values;
}

mixin _$PaymentMethodMixin {
  // ignore: non_constant_identifier_names
  _$PaymentMethodMeta get PaymentMethod => const _$PaymentMethodMeta();
}

Serializer<PaymentMethod> _$paymentMethodSerializer =
    _$PaymentMethodSerializer();

class _$PaymentMethodSerializer implements PrimitiveSerializer<PaymentMethod> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CASH_ON_DELIVERY': 'CASH_ON_DELIVERY',
    'MOBILE_WALLET': 'MOBILE_WALLET',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CASH_ON_DELIVERY': 'CASH_ON_DELIVERY',
    'MOBILE_WALLET': 'MOBILE_WALLET',
  };

  @override
  final Iterable<Type> types = const <Type>[PaymentMethod];
  @override
  final String wireName = 'PaymentMethod';

  @override
  Object serialize(
    Serializers serializers,
    PaymentMethod object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PaymentMethod deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PaymentMethod.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
