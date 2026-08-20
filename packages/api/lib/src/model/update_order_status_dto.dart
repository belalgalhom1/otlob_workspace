//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_order_status_dto.g.dart';

/// UpdateOrderStatusDto
///
/// Properties:
/// * [status] 
/// * [note] 
/// * [estimatedPrepTime] - Estimated prep time in minutes (for ACCEPTED)
@BuiltValue()
abstract class UpdateOrderStatusDto implements Built<UpdateOrderStatusDto, UpdateOrderStatusDtoBuilder> {
  @BuiltValueField(wireName: r'status')
  UpdateOrderStatusDtoStatusEnum get status;
  // enum statusEnum {  PENDING,  CHANGES_REQUESTED,  ACCEPTED,  PREPARING,  LOOKING_FOR_DRIVER,  PENDING_CUSTOMER_APPROVAL,  DRIVER_ASSIGNED,  PENDING_PAYMENT,  READY_FOR_PICKUP,  PICKED_UP,  DELIVERED,  CANCELLED,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  /// Estimated prep time in minutes (for ACCEPTED)
  @BuiltValueField(wireName: r'estimatedPrepTime')
  num? get estimatedPrepTime;

  UpdateOrderStatusDto._();

  factory UpdateOrderStatusDto([void updates(UpdateOrderStatusDtoBuilder b)]) = _$UpdateOrderStatusDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateOrderStatusDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateOrderStatusDto> get serializer => _$UpdateOrderStatusDtoSerializer();
}

class _$UpdateOrderStatusDtoSerializer implements PrimitiveSerializer<UpdateOrderStatusDto> {
  @override
  final Iterable<Type> types = const [UpdateOrderStatusDto, _$UpdateOrderStatusDto];

  @override
  final String wireName = r'UpdateOrderStatusDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateOrderStatusDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(UpdateOrderStatusDtoStatusEnum),
    );
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType(String),
      );
    }
    if (object.estimatedPrepTime != null) {
      yield r'estimatedPrepTime';
      yield serializers.serialize(
        object.estimatedPrepTime,
        specifiedType: const FullType(num),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateOrderStatusDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateOrderStatusDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdateOrderStatusDtoStatusEnum),
          ) as UpdateOrderStatusDtoStatusEnum;
          result.status = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.note = valueDes;
          break;
        case r'estimatedPrepTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.estimatedPrepTime = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateOrderStatusDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateOrderStatusDtoBuilder();
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

class UpdateOrderStatusDtoStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PENDING')
  static const UpdateOrderStatusDtoStatusEnum PENDING = _$updateOrderStatusDtoStatusEnum_PENDING;
  @BuiltValueEnumConst(wireName: r'CHANGES_REQUESTED')
  static const UpdateOrderStatusDtoStatusEnum CHANGES_REQUESTED = _$updateOrderStatusDtoStatusEnum_CHANGES_REQUESTED;
  @BuiltValueEnumConst(wireName: r'ACCEPTED')
  static const UpdateOrderStatusDtoStatusEnum ACCEPTED = _$updateOrderStatusDtoStatusEnum_ACCEPTED;
  @BuiltValueEnumConst(wireName: r'PREPARING')
  static const UpdateOrderStatusDtoStatusEnum PREPARING = _$updateOrderStatusDtoStatusEnum_PREPARING;
  @BuiltValueEnumConst(wireName: r'LOOKING_FOR_DRIVER')
  static const UpdateOrderStatusDtoStatusEnum LOOKING_FOR_DRIVER = _$updateOrderStatusDtoStatusEnum_LOOKING_FOR_DRIVER;
  @BuiltValueEnumConst(wireName: r'PENDING_CUSTOMER_APPROVAL')
  static const UpdateOrderStatusDtoStatusEnum PENDING_CUSTOMER_APPROVAL = _$updateOrderStatusDtoStatusEnum_PENDING_CUSTOMER_APPROVAL;
  @BuiltValueEnumConst(wireName: r'DRIVER_ASSIGNED')
  static const UpdateOrderStatusDtoStatusEnum DRIVER_ASSIGNED = _$updateOrderStatusDtoStatusEnum_DRIVER_ASSIGNED;
  @BuiltValueEnumConst(wireName: r'PENDING_PAYMENT')
  static const UpdateOrderStatusDtoStatusEnum PENDING_PAYMENT = _$updateOrderStatusDtoStatusEnum_PENDING_PAYMENT;
  @BuiltValueEnumConst(wireName: r'READY_FOR_PICKUP')
  static const UpdateOrderStatusDtoStatusEnum READY_FOR_PICKUP = _$updateOrderStatusDtoStatusEnum_READY_FOR_PICKUP;
  @BuiltValueEnumConst(wireName: r'PICKED_UP')
  static const UpdateOrderStatusDtoStatusEnum PICKED_UP = _$updateOrderStatusDtoStatusEnum_PICKED_UP;
  @BuiltValueEnumConst(wireName: r'DELIVERED')
  static const UpdateOrderStatusDtoStatusEnum DELIVERED = _$updateOrderStatusDtoStatusEnum_DELIVERED;
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const UpdateOrderStatusDtoStatusEnum CANCELLED = _$updateOrderStatusDtoStatusEnum_CANCELLED;

  static Serializer<UpdateOrderStatusDtoStatusEnum> get serializer => _$updateOrderStatusDtoStatusEnumSerializer;

  const UpdateOrderStatusDtoStatusEnum._(String name): super(name);

  static BuiltSet<UpdateOrderStatusDtoStatusEnum> get values => _$updateOrderStatusDtoStatusEnumValues;
  static UpdateOrderStatusDtoStatusEnum valueOf(String name) => _$updateOrderStatusDtoStatusEnumValueOf(name);
}

