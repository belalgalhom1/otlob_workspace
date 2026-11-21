// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_order_preview_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CustomOrderPreviewType _$CUSTOM_DELIVERY = const CustomOrderPreviewType._(
  'CUSTOM_DELIVERY',
);
const CustomOrderPreviewType _$RIDE = const CustomOrderPreviewType._('RIDE');

CustomOrderPreviewType _$valueOf(String name) {
  switch (name) {
    case 'CUSTOM_DELIVERY':
      return _$CUSTOM_DELIVERY;
    case 'RIDE':
      return _$RIDE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CustomOrderPreviewType> _$values =
    BuiltSet<CustomOrderPreviewType>(const <CustomOrderPreviewType>[
      _$CUSTOM_DELIVERY,
      _$RIDE,
    ]);

class _$CustomOrderPreviewTypeMeta {
  const _$CustomOrderPreviewTypeMeta();
  CustomOrderPreviewType get CUSTOM_DELIVERY => _$CUSTOM_DELIVERY;
  CustomOrderPreviewType get RIDE => _$RIDE;
  CustomOrderPreviewType valueOf(String name) => _$valueOf(name);
  BuiltSet<CustomOrderPreviewType> get values => _$values;
}

mixin _$CustomOrderPreviewTypeMixin {
  // ignore: non_constant_identifier_names
  _$CustomOrderPreviewTypeMeta get CustomOrderPreviewType =>
      const _$CustomOrderPreviewTypeMeta();
}

Serializer<CustomOrderPreviewType> _$customOrderPreviewTypeSerializer =
    _$CustomOrderPreviewTypeSerializer();

class _$CustomOrderPreviewTypeSerializer
    implements PrimitiveSerializer<CustomOrderPreviewType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CUSTOM_DELIVERY': 'CUSTOM_DELIVERY',
    'RIDE': 'RIDE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CUSTOM_DELIVERY': 'CUSTOM_DELIVERY',
    'RIDE': 'RIDE',
  };

  @override
  final Iterable<Type> types = const <Type>[CustomOrderPreviewType];
  @override
  final String wireName = 'CustomOrderPreviewType';

  @override
  Object serialize(
    Serializers serializers,
    CustomOrderPreviewType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CustomOrderPreviewType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CustomOrderPreviewType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
