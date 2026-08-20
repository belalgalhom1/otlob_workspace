//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_zone_dto.g.dart';

/// CreateZoneDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [isActive] 
/// * [baseDeliveryFeeOverride] 
/// * [minOrderAmountOverride] 
/// * [boundary] - GeoJSON Polygon coordinates: array of linear rings (arrays of [lng, lat])
@BuiltValue()
abstract class CreateZoneDto implements Built<CreateZoneDto, CreateZoneDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  @BuiltValueField(wireName: r'baseDeliveryFeeOverride')
  num? get baseDeliveryFeeOverride;

  @BuiltValueField(wireName: r'minOrderAmountOverride')
  num? get minOrderAmountOverride;

  /// GeoJSON Polygon coordinates: array of linear rings (arrays of [lng, lat])
  @BuiltValueField(wireName: r'boundary')
  BuiltList<String> get boundary;

  CreateZoneDto._();

  factory CreateZoneDto([void updates(CreateZoneDtoBuilder b)]) = _$CreateZoneDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateZoneDtoBuilder b) => b
      ..isActive = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateZoneDto> get serializer => _$CreateZoneDtoSerializer();
}

class _$CreateZoneDtoSerializer implements PrimitiveSerializer<CreateZoneDto> {
  @override
  final Iterable<Type> types = const [CreateZoneDto, _$CreateZoneDto];

  @override
  final String wireName = r'CreateZoneDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateZoneDto object, {
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
    if (object.isActive != null) {
      yield r'isActive';
      yield serializers.serialize(
        object.isActive,
        specifiedType: const FullType(bool),
      );
    }
    if (object.baseDeliveryFeeOverride != null) {
      yield r'baseDeliveryFeeOverride';
      yield serializers.serialize(
        object.baseDeliveryFeeOverride,
        specifiedType: const FullType(num),
      );
    }
    if (object.minOrderAmountOverride != null) {
      yield r'minOrderAmountOverride';
      yield serializers.serialize(
        object.minOrderAmountOverride,
        specifiedType: const FullType(num),
      );
    }
    yield r'boundary';
    yield serializers.serialize(
      object.boundary,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateZoneDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateZoneDtoBuilder result,
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
        case r'isActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        case r'baseDeliveryFeeOverride':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.baseDeliveryFeeOverride = valueDes;
          break;
        case r'minOrderAmountOverride':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minOrderAmountOverride = valueDes;
          break;
        case r'boundary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.boundary.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateZoneDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateZoneDtoBuilder();
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

