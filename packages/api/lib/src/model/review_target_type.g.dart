// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_target_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ReviewTargetType _$VENDOR_FULFILLMENT = const ReviewTargetType._(
  'VENDOR_FULFILLMENT',
);
const ReviewTargetType _$DELIVERY_GROUP = const ReviewTargetType._(
  'DELIVERY_GROUP',
);

ReviewTargetType _$valueOf(String name) {
  switch (name) {
    case 'VENDOR_FULFILLMENT':
      return _$VENDOR_FULFILLMENT;
    case 'DELIVERY_GROUP':
      return _$DELIVERY_GROUP;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ReviewTargetType> _$values = BuiltSet<ReviewTargetType>(
  const <ReviewTargetType>[_$VENDOR_FULFILLMENT, _$DELIVERY_GROUP],
);

class _$ReviewTargetTypeMeta {
  const _$ReviewTargetTypeMeta();
  ReviewTargetType get VENDOR_FULFILLMENT => _$VENDOR_FULFILLMENT;
  ReviewTargetType get DELIVERY_GROUP => _$DELIVERY_GROUP;
  ReviewTargetType valueOf(String name) => _$valueOf(name);
  BuiltSet<ReviewTargetType> get values => _$values;
}

mixin _$ReviewTargetTypeMixin {
  // ignore: non_constant_identifier_names
  _$ReviewTargetTypeMeta get ReviewTargetType => const _$ReviewTargetTypeMeta();
}

Serializer<ReviewTargetType> _$reviewTargetTypeSerializer =
    _$ReviewTargetTypeSerializer();

class _$ReviewTargetTypeSerializer
    implements PrimitiveSerializer<ReviewTargetType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'VENDOR_FULFILLMENT': 'VENDOR_FULFILLMENT',
    'DELIVERY_GROUP': 'DELIVERY_GROUP',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'VENDOR_FULFILLMENT': 'VENDOR_FULFILLMENT',
    'DELIVERY_GROUP': 'DELIVERY_GROUP',
  };

  @override
  final Iterable<Type> types = const <Type>[ReviewTargetType];
  @override
  final String wireName = 'ReviewTargetType';

  @override
  Object serialize(
    Serializers serializers,
    ReviewTargetType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ReviewTargetType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ReviewTargetType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
