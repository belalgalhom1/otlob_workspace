// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_tier.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DriverTier _$BRONZE = const DriverTier._('BRONZE');
const DriverTier _$SILVER = const DriverTier._('SILVER');
const DriverTier _$GOLD = const DriverTier._('GOLD');

DriverTier _$valueOf(String name) {
  switch (name) {
    case 'BRONZE':
      return _$BRONZE;
    case 'SILVER':
      return _$SILVER;
    case 'GOLD':
      return _$GOLD;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DriverTier> _$values = BuiltSet<DriverTier>(const <DriverTier>[
  _$BRONZE,
  _$SILVER,
  _$GOLD,
]);

class _$DriverTierMeta {
  const _$DriverTierMeta();
  DriverTier get BRONZE => _$BRONZE;
  DriverTier get SILVER => _$SILVER;
  DriverTier get GOLD => _$GOLD;
  DriverTier valueOf(String name) => _$valueOf(name);
  BuiltSet<DriverTier> get values => _$values;
}

mixin _$DriverTierMixin {
  // ignore: non_constant_identifier_names
  _$DriverTierMeta get DriverTier => const _$DriverTierMeta();
}

Serializer<DriverTier> _$driverTierSerializer = _$DriverTierSerializer();

class _$DriverTierSerializer implements PrimitiveSerializer<DriverTier> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'BRONZE': 'BRONZE',
    'SILVER': 'SILVER',
    'GOLD': 'GOLD',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'BRONZE': 'BRONZE',
    'SILVER': 'SILVER',
    'GOLD': 'GOLD',
  };

  @override
  final Iterable<Type> types = const <Type>[DriverTier];
  @override
  final String wireName = 'DriverTier';

  @override
  Object serialize(
    Serializers serializers,
    DriverTier object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DriverTier deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DriverTier.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
