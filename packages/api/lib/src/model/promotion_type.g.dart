// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PromotionType _$BANNER = const PromotionType._('BANNER');
const PromotionType _$VENDOR = const PromotionType._('VENDOR');
const PromotionType _$PRODUCT = const PromotionType._('PRODUCT');
const PromotionType _$EXTERNAL_LINK = const PromotionType._('EXTERNAL_LINK');
const PromotionType _$POPUP = const PromotionType._('POPUP');
const PromotionType _$NOTIFICATION = const PromotionType._('NOTIFICATION');

PromotionType _$valueOf(String name) {
  switch (name) {
    case 'BANNER':
      return _$BANNER;
    case 'VENDOR':
      return _$VENDOR;
    case 'PRODUCT':
      return _$PRODUCT;
    case 'EXTERNAL_LINK':
      return _$EXTERNAL_LINK;
    case 'POPUP':
      return _$POPUP;
    case 'NOTIFICATION':
      return _$NOTIFICATION;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PromotionType> _$values = BuiltSet<PromotionType>(
  const <PromotionType>[
    _$BANNER,
    _$VENDOR,
    _$PRODUCT,
    _$EXTERNAL_LINK,
    _$POPUP,
    _$NOTIFICATION,
  ],
);

class _$PromotionTypeMeta {
  const _$PromotionTypeMeta();
  PromotionType get BANNER => _$BANNER;
  PromotionType get VENDOR => _$VENDOR;
  PromotionType get PRODUCT => _$PRODUCT;
  PromotionType get EXTERNAL_LINK => _$EXTERNAL_LINK;
  PromotionType get POPUP => _$POPUP;
  PromotionType get NOTIFICATION => _$NOTIFICATION;
  PromotionType valueOf(String name) => _$valueOf(name);
  BuiltSet<PromotionType> get values => _$values;
}

mixin _$PromotionTypeMixin {
  // ignore: non_constant_identifier_names
  _$PromotionTypeMeta get PromotionType => const _$PromotionTypeMeta();
}

Serializer<PromotionType> _$promotionTypeSerializer =
    _$PromotionTypeSerializer();

class _$PromotionTypeSerializer implements PrimitiveSerializer<PromotionType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'BANNER': 'BANNER',
    'VENDOR': 'VENDOR',
    'PRODUCT': 'PRODUCT',
    'EXTERNAL_LINK': 'EXTERNAL_LINK',
    'POPUP': 'POPUP',
    'NOTIFICATION': 'NOTIFICATION',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'BANNER': 'BANNER',
    'VENDOR': 'VENDOR',
    'PRODUCT': 'PRODUCT',
    'EXTERNAL_LINK': 'EXTERNAL_LINK',
    'POPUP': 'POPUP',
    'NOTIFICATION': 'NOTIFICATION',
  };

  @override
  final Iterable<Type> types = const <Type>[PromotionType];
  @override
  final String wireName = 'PromotionType';

  @override
  Object serialize(
    Serializers serializers,
    PromotionType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PromotionType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PromotionType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
