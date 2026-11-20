//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/delivery_incident_responsibility.dart';
import 'package:api/src/model/delivery_incident_type.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_delivery_incident_dto.g.dart';

/// DriverDeliveryIncidentDto
///
/// Properties:
/// * [id] 
/// * [orderId] 
/// * [orderNumber] 
/// * [deliveryGroupId] 
/// * [driverId] 
/// * [driverName] 
/// * [incidentType] 
/// * [responsibility] 
/// * [reason] 
/// * [reportedByUserId] 
/// * [reviewedByUserId] 
/// * [reviewedAt] 
/// * [reviewNote] 
/// * [occurredAt] 
/// * [createdAt] 
@BuiltValue()
abstract class DriverDeliveryIncidentDto implements Built<DriverDeliveryIncidentDto, DriverDeliveryIncidentDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'orderId')
  String get orderId;

  @BuiltValueField(wireName: r'orderNumber')
  JsonObject? get orderNumber;

  @BuiltValueField(wireName: r'deliveryGroupId')
  String get deliveryGroupId;

  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'driverName')
  JsonObject? get driverName;

  @BuiltValueField(wireName: r'incidentType')
  DeliveryIncidentType get incidentType;
  // enum incidentTypeEnum {  ORDER_CANCELLED,  DRIVER_REASSIGNED,  DRIVER_UNASSIGNED,  DELIVERY_FAILURE,  };

  @BuiltValueField(wireName: r'responsibility')
  DeliveryIncidentResponsibility get responsibility;
  // enum responsibilityEnum {  DRIVER_AT_FAULT,  CUSTOMER,  VENDOR,  EXTERNAL_OR_SYSTEM,  UNDER_REVIEW,  };

  @BuiltValueField(wireName: r'reason')
  JsonObject? get reason;

  @BuiltValueField(wireName: r'reportedByUserId')
  JsonObject? get reportedByUserId;

  @BuiltValueField(wireName: r'reviewedByUserId')
  JsonObject? get reviewedByUserId;

  @BuiltValueField(wireName: r'reviewedAt')
  DateTime? get reviewedAt;

  @BuiltValueField(wireName: r'reviewNote')
  JsonObject? get reviewNote;

  @BuiltValueField(wireName: r'occurredAt')
  DateTime get occurredAt;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  DriverDeliveryIncidentDto._();

  factory DriverDeliveryIncidentDto([void updates(DriverDeliveryIncidentDtoBuilder b)]) = _$DriverDeliveryIncidentDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverDeliveryIncidentDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverDeliveryIncidentDto> get serializer => _$DriverDeliveryIncidentDtoSerializer();
}

class _$DriverDeliveryIncidentDtoSerializer implements PrimitiveSerializer<DriverDeliveryIncidentDto> {
  @override
  final Iterable<Type> types = const [DriverDeliveryIncidentDto, _$DriverDeliveryIncidentDto];

  @override
  final String wireName = r'DriverDeliveryIncidentDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverDeliveryIncidentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'orderId';
    yield serializers.serialize(
      object.orderId,
      specifiedType: const FullType(String),
    );
    if (object.orderNumber != null) {
      yield r'orderNumber';
      yield serializers.serialize(
        object.orderNumber,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    yield r'deliveryGroupId';
    yield serializers.serialize(
      object.deliveryGroupId,
      specifiedType: const FullType(String),
    );
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
    if (object.driverName != null) {
      yield r'driverName';
      yield serializers.serialize(
        object.driverName,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    yield r'incidentType';
    yield serializers.serialize(
      object.incidentType,
      specifiedType: const FullType(DeliveryIncidentType),
    );
    yield r'responsibility';
    yield serializers.serialize(
      object.responsibility,
      specifiedType: const FullType(DeliveryIncidentResponsibility),
    );
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    if (object.reportedByUserId != null) {
      yield r'reportedByUserId';
      yield serializers.serialize(
        object.reportedByUserId,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    if (object.reviewedByUserId != null) {
      yield r'reviewedByUserId';
      yield serializers.serialize(
        object.reviewedByUserId,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    if (object.reviewedAt != null) {
      yield r'reviewedAt';
      yield serializers.serialize(
        object.reviewedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.reviewNote != null) {
      yield r'reviewNote';
      yield serializers.serialize(
        object.reviewNote,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    yield r'occurredAt';
    yield serializers.serialize(
      object.occurredAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverDeliveryIncidentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverDeliveryIncidentDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        case r'orderNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.orderNumber = valueDes;
          break;
        case r'deliveryGroupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryGroupId = valueDes;
          break;
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverId = valueDes;
          break;
        case r'driverName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.driverName = valueDes;
          break;
        case r'incidentType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeliveryIncidentType),
          ) as DeliveryIncidentType;
          result.incidentType = valueDes;
          break;
        case r'responsibility':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeliveryIncidentResponsibility),
          ) as DeliveryIncidentResponsibility;
          result.responsibility = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.reason = valueDes;
          break;
        case r'reportedByUserId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.reportedByUserId = valueDes;
          break;
        case r'reviewedByUserId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.reviewedByUserId = valueDes;
          break;
        case r'reviewedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.reviewedAt = valueDes;
          break;
        case r'reviewNote':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.reviewNote = valueDes;
          break;
        case r'occurredAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.occurredAt = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverDeliveryIncidentDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverDeliveryIncidentDtoBuilder();
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

