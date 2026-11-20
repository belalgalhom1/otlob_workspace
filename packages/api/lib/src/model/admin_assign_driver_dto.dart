//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/delivery_incident_responsibility.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_assign_driver_dto.g.dart';

/// AdminAssignDriverDto
///
/// Properties:
/// * [driverId] 
/// * [deliveryGroupId] - Optional delivery group ID when assigning a driver to a specific delivery trip
/// * [previousDriverResponsibility] - Responsibility classification when replacing an already-assigned driver (for weekly ranking)
/// * [reassignmentReason] - Reason for driver reassignment
@BuiltValue()
abstract class AdminAssignDriverDto implements Built<AdminAssignDriverDto, AdminAssignDriverDtoBuilder> {
  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  /// Optional delivery group ID when assigning a driver to a specific delivery trip
  @BuiltValueField(wireName: r'deliveryGroupId')
  String? get deliveryGroupId;

  /// Responsibility classification when replacing an already-assigned driver (for weekly ranking)
  @BuiltValueField(wireName: r'previousDriverResponsibility')
  DeliveryIncidentResponsibility? get previousDriverResponsibility;
  // enum previousDriverResponsibilityEnum {  DRIVER_AT_FAULT,  CUSTOMER,  VENDOR,  EXTERNAL_OR_SYSTEM,  UNDER_REVIEW,  };

  /// Reason for driver reassignment
  @BuiltValueField(wireName: r'reassignmentReason')
  String? get reassignmentReason;

  AdminAssignDriverDto._();

  factory AdminAssignDriverDto([void updates(AdminAssignDriverDtoBuilder b)]) = _$AdminAssignDriverDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminAssignDriverDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminAssignDriverDto> get serializer => _$AdminAssignDriverDtoSerializer();
}

class _$AdminAssignDriverDtoSerializer implements PrimitiveSerializer<AdminAssignDriverDto> {
  @override
  final Iterable<Type> types = const [AdminAssignDriverDto, _$AdminAssignDriverDto];

  @override
  final String wireName = r'AdminAssignDriverDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminAssignDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
    if (object.deliveryGroupId != null) {
      yield r'deliveryGroupId';
      yield serializers.serialize(
        object.deliveryGroupId,
        specifiedType: const FullType(String),
      );
    }
    if (object.previousDriverResponsibility != null) {
      yield r'previousDriverResponsibility';
      yield serializers.serialize(
        object.previousDriverResponsibility,
        specifiedType: const FullType(DeliveryIncidentResponsibility),
      );
    }
    if (object.reassignmentReason != null) {
      yield r'reassignmentReason';
      yield serializers.serialize(
        object.reassignmentReason,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AdminAssignDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminAssignDriverDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverId = valueDes;
          break;
        case r'deliveryGroupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryGroupId = valueDes;
          break;
        case r'previousDriverResponsibility':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeliveryIncidentResponsibility),
          ) as DeliveryIncidentResponsibility;
          result.previousDriverResponsibility = valueDes;
          break;
        case r'reassignmentReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reassignmentReason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AdminAssignDriverDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminAssignDriverDtoBuilder();
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

