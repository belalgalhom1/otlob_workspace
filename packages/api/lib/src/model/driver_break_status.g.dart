// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_break_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DriverBreakStatus _$PENDING = const DriverBreakStatus._('PENDING');
const DriverBreakStatus _$APPROVED = const DriverBreakStatus._('APPROVED');
const DriverBreakStatus _$REJECTED = const DriverBreakStatus._('REJECTED');
const DriverBreakStatus _$CANCELLED = const DriverBreakStatus._('CANCELLED');
const DriverBreakStatus _$ENDED = const DriverBreakStatus._('ENDED');

DriverBreakStatus _$valueOf(String name) {
  switch (name) {
    case 'PENDING':
      return _$PENDING;
    case 'APPROVED':
      return _$APPROVED;
    case 'REJECTED':
      return _$REJECTED;
    case 'CANCELLED':
      return _$CANCELLED;
    case 'ENDED':
      return _$ENDED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DriverBreakStatus> _$values = BuiltSet<DriverBreakStatus>(
  const <DriverBreakStatus>[
    _$PENDING,
    _$APPROVED,
    _$REJECTED,
    _$CANCELLED,
    _$ENDED,
  ],
);

class _$DriverBreakStatusMeta {
  const _$DriverBreakStatusMeta();
  DriverBreakStatus get PENDING => _$PENDING;
  DriverBreakStatus get APPROVED => _$APPROVED;
  DriverBreakStatus get REJECTED => _$REJECTED;
  DriverBreakStatus get CANCELLED => _$CANCELLED;
  DriverBreakStatus get ENDED => _$ENDED;
  DriverBreakStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<DriverBreakStatus> get values => _$values;
}

mixin _$DriverBreakStatusMixin {
  // ignore: non_constant_identifier_names
  _$DriverBreakStatusMeta get DriverBreakStatus =>
      const _$DriverBreakStatusMeta();
}

Serializer<DriverBreakStatus> _$driverBreakStatusSerializer =
    _$DriverBreakStatusSerializer();

class _$DriverBreakStatusSerializer
    implements PrimitiveSerializer<DriverBreakStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PENDING': 'PENDING',
    'APPROVED': 'APPROVED',
    'REJECTED': 'REJECTED',
    'CANCELLED': 'CANCELLED',
    'ENDED': 'ENDED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PENDING': 'PENDING',
    'APPROVED': 'APPROVED',
    'REJECTED': 'REJECTED',
    'CANCELLED': 'CANCELLED',
    'ENDED': 'ENDED',
  };

  @override
  final Iterable<Type> types = const <Type>[DriverBreakStatus];
  @override
  final String wireName = 'DriverBreakStatus';

  @override
  Object serialize(
    Serializers serializers,
    DriverBreakStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DriverBreakStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DriverBreakStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
