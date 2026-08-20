// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WalletType _$VODAFONE = const WalletType._('VODAFONE');
const WalletType _$ORANGE = const WalletType._('ORANGE');
const WalletType _$WE = const WalletType._('WE');
const WalletType _$ETISALAT = const WalletType._('ETISALAT');
const WalletType _$INSTAPAY = const WalletType._('INSTAPAY');

WalletType _$valueOf(String name) {
  switch (name) {
    case 'VODAFONE':
      return _$VODAFONE;
    case 'ORANGE':
      return _$ORANGE;
    case 'WE':
      return _$WE;
    case 'ETISALAT':
      return _$ETISALAT;
    case 'INSTAPAY':
      return _$INSTAPAY;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WalletType> _$values = BuiltSet<WalletType>(const <WalletType>[
  _$VODAFONE,
  _$ORANGE,
  _$WE,
  _$ETISALAT,
  _$INSTAPAY,
]);

class _$WalletTypeMeta {
  const _$WalletTypeMeta();
  WalletType get VODAFONE => _$VODAFONE;
  WalletType get ORANGE => _$ORANGE;
  WalletType get WE => _$WE;
  WalletType get ETISALAT => _$ETISALAT;
  WalletType get INSTAPAY => _$INSTAPAY;
  WalletType valueOf(String name) => _$valueOf(name);
  BuiltSet<WalletType> get values => _$values;
}

mixin _$WalletTypeMixin {
  // ignore: non_constant_identifier_names
  _$WalletTypeMeta get WalletType => const _$WalletTypeMeta();
}

Serializer<WalletType> _$walletTypeSerializer = _$WalletTypeSerializer();

class _$WalletTypeSerializer implements PrimitiveSerializer<WalletType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'VODAFONE': 'VODAFONE',
    'ORANGE': 'ORANGE',
    'WE': 'WE',
    'ETISALAT': 'ETISALAT',
    'INSTAPAY': 'INSTAPAY',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'VODAFONE': 'VODAFONE',
    'ORANGE': 'ORANGE',
    'WE': 'WE',
    'ETISALAT': 'ETISALAT',
    'INSTAPAY': 'INSTAPAY',
  };

  @override
  final Iterable<Type> types = const <Type>[WalletType];
  @override
  final String wireName = 'WalletType';

  @override
  Object serialize(
    Serializers serializers,
    WalletType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WalletType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WalletType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
