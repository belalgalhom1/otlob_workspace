//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_vendor_vertical_dto.g.dart';

/// CreateVendorVerticalDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [slug] 
/// * [iconUrl] 
/// * [isActive] 
/// * [sortOrder] 
@BuiltValue()
abstract class CreateVendorVerticalDto implements Built<CreateVendorVerticalDto, CreateVendorVerticalDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'iconUrl')
  String? get iconUrl;

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  @BuiltValueField(wireName: r'sortOrder')
  num? get sortOrder;

  CreateVendorVerticalDto._();

  factory CreateVendorVerticalDto([void updates(CreateVendorVerticalDtoBuilder b)]) = _$CreateVendorVerticalDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateVendorVerticalDtoBuilder b) => b
      ..isActive = true
      ..sortOrder = 0;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateVendorVerticalDto> get serializer => _$CreateVendorVerticalDtoSerializer();
}

class _$CreateVendorVerticalDtoSerializer implements PrimitiveSerializer<CreateVendorVerticalDto> {
  @override
  final Iterable<Type> types = const [CreateVendorVerticalDto, _$CreateVendorVerticalDto];

  @override
  final String wireName = r'CreateVendorVerticalDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateVendorVerticalDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.nameAr != null) {
      yield r'nameAr';
      yield serializers.serialize(
        object.nameAr,
        specifiedType: const FullType(String),
      );
    }
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
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
    CreateVendorVerticalDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateVendorVerticalDtoBuilder result,
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
  CreateVendorVerticalDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateVendorVerticalDtoBuilder();
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

