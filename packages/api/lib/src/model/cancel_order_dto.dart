//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/delivery_incident_responsibility.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cancel_order_dto.g.dart';

/// CancelOrderDto
///
/// Properties:
/// * [reason] - Optional reason for cancelling the order
/// * [responsibility] - Optional admin/support responsibility classification when an order already had an assigned driver
/// * [responsibleDriverId] - Specific driverId attributed when responsibility is DRIVER_AT_FAULT on multi-group orders
@BuiltValue()
abstract class CancelOrderDto implements Built<CancelOrderDto, CancelOrderDtoBuilder> {
  /// Optional reason for cancelling the order
  @BuiltValueField(wireName: r'reason')
  String? get reason;

  /// Optional admin/support responsibility classification when an order already had an assigned driver
  @BuiltValueField(wireName: r'responsibility')
  DeliveryIncidentResponsibility? get responsibility;
  // enum responsibilityEnum {  DRIVER_AT_FAULT,  CUSTOMER,  VENDOR,  EXTERNAL_OR_SYSTEM,  UNDER_REVIEW,  };

  /// Specific driverId attributed when responsibility is DRIVER_AT_FAULT on multi-group orders
  @BuiltValueField(wireName: r'responsibleDriverId')
  String? get responsibleDriverId;

  CancelOrderDto._();

  factory CancelOrderDto([void updates(CancelOrderDtoBuilder b)]) = _$CancelOrderDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CancelOrderDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CancelOrderDto> get serializer => _$CancelOrderDtoSerializer();
}

class _$CancelOrderDtoSerializer implements PrimitiveSerializer<CancelOrderDto> {
  @override
  final Iterable<Type> types = const [CancelOrderDto, _$CancelOrderDto];

  @override
  final String wireName = r'CancelOrderDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CancelOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType(String),
      );
    }
    if (object.responsibility != null) {
      yield r'responsibility';
      yield serializers.serialize(
        object.responsibility,
        specifiedType: const FullType(DeliveryIncidentResponsibility),
      );
    }
    if (object.responsibleDriverId != null) {
      yield r'responsibleDriverId';
      yield serializers.serialize(
        object.responsibleDriverId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CancelOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CancelOrderDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        case r'responsibility':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeliveryIncidentResponsibility),
          ) as DeliveryIncidentResponsibility;
          result.responsibility = valueDes;
          break;
        case r'responsibleDriverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.responsibleDriverId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CancelOrderDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CancelOrderDtoBuilder();
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

