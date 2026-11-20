// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swap_request_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SwapRequestStatus _$PENDING = const SwapRequestStatus._('PENDING');
const SwapRequestStatus _$ACCEPTED = const SwapRequestStatus._('ACCEPTED');
const SwapRequestStatus _$CANCELLED = const SwapRequestStatus._('CANCELLED');

SwapRequestStatus _$valueOf(String name) {
  switch (name) {
    case 'PENDING':
      return _$PENDING;
    case 'ACCEPTED':
      return _$ACCEPTED;
    case 'CANCELLED':
      return _$CANCELLED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<SwapRequestStatus> _$values = BuiltSet<SwapRequestStatus>(
  const <SwapRequestStatus>[_$PENDING, _$ACCEPTED, _$CANCELLED],
);

class _$SwapRequestStatusMeta {
  const _$SwapRequestStatusMeta();
  SwapRequestStatus get PENDING => _$PENDING;
  SwapRequestStatus get ACCEPTED => _$ACCEPTED;
  SwapRequestStatus get CANCELLED => _$CANCELLED;
  SwapRequestStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<SwapRequestStatus> get values => _$values;
}

mixin _$SwapRequestStatusMixin {
  // ignore: non_constant_identifier_names
  _$SwapRequestStatusMeta get SwapRequestStatus =>
      const _$SwapRequestStatusMeta();
}

Serializer<SwapRequestStatus> _$swapRequestStatusSerializer =
    _$SwapRequestStatusSerializer();

class _$SwapRequestStatusSerializer
    implements PrimitiveSerializer<SwapRequestStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
    'CANCELLED': 'CANCELLED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
    'CANCELLED': 'CANCELLED',
  };

  @override
  final Iterable<Type> types = const <Type>[SwapRequestStatus];
  @override
  final String wireName = 'SwapRequestStatus';

  @override
  Object serialize(
    Serializers serializers,
    SwapRequestStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  SwapRequestStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => SwapRequestStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
