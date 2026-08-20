// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_up_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TopUpStatus _$PENDING = const TopUpStatus._('PENDING');
const TopUpStatus _$APPROVED = const TopUpStatus._('APPROVED');
const TopUpStatus _$REJECTED = const TopUpStatus._('REJECTED');

TopUpStatus _$valueOf(String name) {
  switch (name) {
    case 'PENDING':
      return _$PENDING;
    case 'APPROVED':
      return _$APPROVED;
    case 'REJECTED':
      return _$REJECTED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TopUpStatus> _$values = BuiltSet<TopUpStatus>(
  const <TopUpStatus>[_$PENDING, _$APPROVED, _$REJECTED],
);

class _$TopUpStatusMeta {
  const _$TopUpStatusMeta();
  TopUpStatus get PENDING => _$PENDING;
  TopUpStatus get APPROVED => _$APPROVED;
  TopUpStatus get REJECTED => _$REJECTED;
  TopUpStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<TopUpStatus> get values => _$values;
}

mixin _$TopUpStatusMixin {
  // ignore: non_constant_identifier_names
  _$TopUpStatusMeta get TopUpStatus => const _$TopUpStatusMeta();
}

Serializer<TopUpStatus> _$topUpStatusSerializer = _$TopUpStatusSerializer();

class _$TopUpStatusSerializer implements PrimitiveSerializer<TopUpStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PENDING': 'PENDING',
    'APPROVED': 'APPROVED',
    'REJECTED': 'REJECTED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PENDING': 'PENDING',
    'APPROVED': 'APPROVED',
    'REJECTED': 'REJECTED',
  };

  @override
  final Iterable<Type> types = const <Type>[TopUpStatus];
  @override
  final String wireName = 'TopUpStatus';

  @override
  Object serialize(
    Serializers serializers,
    TopUpStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  TopUpStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => TopUpStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
