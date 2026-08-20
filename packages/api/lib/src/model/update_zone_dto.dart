//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_zone_dto.g.dart';

/// UpdateZoneDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [isActive] 
/// * [baseDeliveryFeeOverride] 
/// * [minOrderAmountOverride] 
/// * [boundary] 
@BuiltValue()
abstract class UpdateZoneDto implements Built<UpdateZoneDto, UpdateZoneDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  @BuiltValueField(wireName: r'baseDeliveryFeeOverride')
  num? get baseDeliveryFeeOverride;

  @BuiltValueField(wireName: r'minOrderAmountOverride')
  num? get minOrderAmountOverride;

  @BuiltValueField(wireName: r'boundary')
  BuiltList<String>? get boundary;

  UpdateZoneDto._();

  factory UpdateZoneDto([void updates(UpdateZoneDtoBuilder b)]) = _$UpdateZoneDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateZoneDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateZoneDto> get serializer => _$UpdateZoneDtoSerializer();
}

class _$UpdateZoneDtoSerializer implements PrimitiveSerializer<UpdateZoneDto> {
  @override
  final Iterable<Type> types = const [UpdateZoneDto, _$UpdateZoneDto];

  @override
  final String wireName = r'UpdateZoneDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateZoneDto object, {
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
    if (object.boundary != null) {
      yield r'boundary';
      yield serializers.serialize(
        object.boundary,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateZoneDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateZoneDtoBuilder result,
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
  UpdateZoneDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateZoneDtoBuilder();
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

