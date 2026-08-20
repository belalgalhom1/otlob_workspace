// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatch_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DispatchStatus _$PENDING = const DispatchStatus._('PENDING');
const DispatchStatus _$ACCEPTED = const DispatchStatus._('ACCEPTED');
const DispatchStatus _$REJECTED = const DispatchStatus._('REJECTED');
const DispatchStatus _$EXPIRED = const DispatchStatus._('EXPIRED');
const DispatchStatus _$CANCELLED = const DispatchStatus._('CANCELLED');

DispatchStatus _$valueOf(String name) {
  switch (name) {
    case 'PENDING':
      return _$PENDING;
    case 'ACCEPTED':
      return _$ACCEPTED;
    case 'REJECTED':
      return _$REJECTED;
    case 'EXPIRED':
      return _$EXPIRED;
    case 'CANCELLED':
      return _$CANCELLED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DispatchStatus> _$values = BuiltSet<DispatchStatus>(
  const <DispatchStatus>[
    _$PENDING,
    _$ACCEPTED,
    _$REJECTED,
    _$EXPIRED,
    _$CANCELLED,
  ],
);

class _$DispatchStatusMeta {
  const _$DispatchStatusMeta();
  DispatchStatus get PENDING => _$PENDING;
  DispatchStatus get ACCEPTED => _$ACCEPTED;
  DispatchStatus get REJECTED => _$REJECTED;
  DispatchStatus get EXPIRED => _$EXPIRED;
  DispatchStatus get CANCELLED => _$CANCELLED;
  DispatchStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<DispatchStatus> get values => _$values;
}

mixin _$DispatchStatusMixin {
  // ignore: non_constant_identifier_names
  _$DispatchStatusMeta get DispatchStatus => const _$DispatchStatusMeta();
}

Serializer<DispatchStatus> _$dispatchStatusSerializer =
    _$DispatchStatusSerializer();

class _$DispatchStatusSerializer
    implements PrimitiveSerializer<DispatchStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
    'REJECTED': 'REJECTED',
    'EXPIRED': 'EXPIRED',
    'CANCELLED': 'CANCELLED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
    'REJECTED': 'REJECTED',
    'EXPIRED': 'EXPIRED',
    'CANCELLED': 'CANCELLED',
  };

  @override
  final Iterable<Type> types = const <Type>[DispatchStatus];
  @override
  final String wireName = 'DispatchStatus';

  @override
  Object serialize(
    Serializers serializers,
    DispatchStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DispatchStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DispatchStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
