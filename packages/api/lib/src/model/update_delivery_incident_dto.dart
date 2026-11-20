//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/delivery_incident_responsibility.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_delivery_incident_dto.g.dart';

/// UpdateDeliveryIncidentDto
///
/// Properties:
/// * [responsibility] 
/// * [reviewNote] 
@BuiltValue()
abstract class UpdateDeliveryIncidentDto implements Built<UpdateDeliveryIncidentDto, UpdateDeliveryIncidentDtoBuilder> {
  @BuiltValueField(wireName: r'responsibility')
  DeliveryIncidentResponsibility get responsibility;
  // enum responsibilityEnum {  DRIVER_AT_FAULT,  CUSTOMER,  VENDOR,  EXTERNAL_OR_SYSTEM,  UNDER_REVIEW,  };

  @BuiltValueField(wireName: r'reviewNote')
  String? get reviewNote;

  UpdateDeliveryIncidentDto._();

  factory UpdateDeliveryIncidentDto([void updates(UpdateDeliveryIncidentDtoBuilder b)]) = _$UpdateDeliveryIncidentDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateDeliveryIncidentDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateDeliveryIncidentDto> get serializer => _$UpdateDeliveryIncidentDtoSerializer();
}

class _$UpdateDeliveryIncidentDtoSerializer implements PrimitiveSerializer<UpdateDeliveryIncidentDto> {
  @override
  final Iterable<Type> types = const [UpdateDeliveryIncidentDto, _$UpdateDeliveryIncidentDto];

  @override
  final String wireName = r'UpdateDeliveryIncidentDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateDeliveryIncidentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'responsibility';
    yield serializers.serialize(
      object.responsibility,
      specifiedType: const FullType(DeliveryIncidentResponsibility),
    );
    if (object.reviewNote != null) {
      yield r'reviewNote';
      yield serializers.serialize(
        object.reviewNote,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateDeliveryIncidentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateDeliveryIncidentDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'responsibility':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeliveryIncidentResponsibility),
          ) as DeliveryIncidentResponsibility;
          result.responsibility = valueDes;
          break;
        case r'reviewNote':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reviewNote = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateDeliveryIncidentDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateDeliveryIncidentDtoBuilder();
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

