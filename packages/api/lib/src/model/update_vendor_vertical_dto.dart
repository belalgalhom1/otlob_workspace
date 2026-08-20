//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_vendor_vertical_dto.g.dart';

/// UpdateVendorVerticalDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [slug] 
/// * [iconUrl] 
/// * [isActive] 
/// * [sortOrder] 
@BuiltValue()
abstract class UpdateVendorVerticalDto implements Built<UpdateVendorVerticalDto, UpdateVendorVerticalDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'slug')
  String? get slug;

  @BuiltValueField(wireName: r'iconUrl')
  String? get iconUrl;

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  @BuiltValueField(wireName: r'sortOrder')
  num? get sortOrder;

  UpdateVendorVerticalDto._();

  factory UpdateVendorVerticalDto([void updates(UpdateVendorVerticalDtoBuilder b)]) = _$UpdateVendorVerticalDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateVendorVerticalDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateVendorVerticalDto> get serializer => _$UpdateVendorVerticalDtoSerializer();
}

class _$UpdateVendorVerticalDtoSerializer implements PrimitiveSerializer<UpdateVendorVerticalDto> {
  @override
  final Iterable<Type> types = const [UpdateVendorVerticalDto, _$UpdateVendorVerticalDto];

  @override
  final String wireName = r'UpdateVendorVerticalDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateVendorVerticalDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.nameAr != null) {
      yield r'nameAr';
      yield serializers.serialize(
        object.nameAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.slug != null) {
      yield r'slug';
      yield serializers.serialize(
        object.slug,
        specifiedType: const FullType(String),
      );
    }
    if (object.iconUrl != null) {
      yield r'iconUrl';
      yield serializers.serialize(
        object.iconUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.isActive != null) {
      yield r'isActive';
      yield serializers.serialize(
        object.isActive,
        specifiedType: const FullType(bool),
      );
    }
    if (object.sortOrder != null) {
      yield r'sortOrder';
      yield serializers.serialize(
        object.sortOrder,
        specifiedType: const FullType(num),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateVendorVerticalDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateVendorVerticalDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'nameAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nameAr = valueDes;
          break;
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'iconUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.iconUrl = valueDes;
          break;
        case r'isActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        case r'sortOrder':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.sortOrder = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateVendorVerticalDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateVendorVerticalDtoBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

