// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const VendorStatus _$CLOSED = const VendorStatus._('CLOSED');
const VendorStatus _$OPEN = const VendorStatus._('OPEN');
const VendorStatus _$PAUSED = const VendorStatus._('PAUSED');
const VendorStatus _$SUSPENDED = const VendorStatus._('SUSPENDED');

VendorStatus _$valueOf(String name) {
  switch (name) {
    case 'CLOSED':
      return _$CLOSED;
    case 'OPEN':
      return _$OPEN;
    case 'PAUSED':
      return _$PAUSED;
    case 'SUSPENDED':
      return _$SUSPENDED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<VendorStatus> _$values = BuiltSet<VendorStatus>(
  const <VendorStatus>[_$CLOSED, _$OPEN, _$PAUSED, _$SUSPENDED],
);

class _$VendorStatusMeta {
  const _$VendorStatusMeta();
  VendorStatus get CLOSED => _$CLOSED;
  VendorStatus get OPEN => _$OPEN;
  VendorStatus get PAUSED => _$PAUSED;
  VendorStatus get SUSPENDED => _$SUSPENDED;
  VendorStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<VendorStatus> get values => _$values;
}

mixin _$VendorStatusMixin {
  // ignore: non_constant_identifier_names
  _$VendorStatusMeta get VendorStatus => const _$VendorStatusMeta();
}

Serializer<VendorStatus> _$vendorStatusSerializer = _$VendorStatusSerializer();

class _$VendorStatusSerializer implements PrimitiveSerializer<VendorStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CLOSED': 'CLOSED',
    'OPEN': 'OPEN',
    'PAUSED': 'PAUSED',
    'SUSPENDED': 'SUSPENDED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CLOSED': 'CLOSED',
    'OPEN': 'OPEN',
    'PAUSED': 'PAUSED',
    'SUSPENDED': 'SUSPENDED',
  };

  @override
  final Iterable<Type> types = const <Type>[VendorStatus];
  @override
  final String wireName = 'VendorStatus';

  @override
  Object serialize(
    Serializers serializers,
    VendorStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  VendorStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => VendorStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
