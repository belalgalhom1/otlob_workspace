//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_ticket_dto.g.dart';

/// UpdateTicketDto
///
/// Properties:
/// * [status] 
/// * [priority] 
/// * [category] 
/// * [assigneeId] 
/// * [subject] 
/// * [description] 
/// * [subCategory] 
/// * [vendorId] 
/// * [metadata] 
@BuiltValue()
abstract class UpdateTicketDto implements Built<UpdateTicketDto, UpdateTicketDtoBuilder> {
  @BuiltValueField(wireName: r'status')
  UpdateTicketDtoStatusEnum? get status;
  // enum statusEnum {  OPEN,  IN_PROGRESS,  WAITING_ON_USER,  ESCALATED,  RESOLVED,  CLOSED,  };

  @BuiltValueField(wireName: r'priority')
  UpdateTicketDtoPriorityEnum? get priority;
  // enum priorityEnum {  LOW,  MEDIUM,  HIGH,  URGENT,  };

  @BuiltValueField(wireName: r'category')
  UpdateTicketDtoCategoryEnum? get category;
  // enum categoryEnum {  DELIVERY,  VENDOR,  PAYMENT,  ACCOUNT,  RETURN_COMPLAINT,  OTHER,  };

  @BuiltValueField(wireName: r'assigneeId')
  String? get assigneeId;

  @BuiltValueField(wireName: r'subject')
  String? get subject;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'subCategory')
  String? get subCategory;

  @BuiltValueField(wireName: r'vendorId')
  String? get vendorId;

  @BuiltValueField(wireName: r'metadata')
  JsonObject? get metadata;

  UpdateTicketDto._();

  factory UpdateTicketDto([void updates(UpdateTicketDtoBuilder b)]) = _$UpdateTicketDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTicketDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTicketDto> get serializer => _$UpdateTicketDtoSerializer();
}

class _$UpdateTicketDtoSerializer implements PrimitiveSerializer<UpdateTicketDto> {
  @override
  final Iterable<Type> types = const [UpdateTicketDto, _$UpdateTicketDto];

  @override
  final String wireName = r'UpdateTicketDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTicketDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(UpdateTicketDtoStatusEnum),
      );
    }
    if (object.priority != null) {
      yield r'priority';
      yield serializers.serialize(
        object.priority,
        specifiedType: const FullType(UpdateTicketDtoPriorityEnum),
      );
    }
    if (object.category != null) {
      yield r'category';
      yield serializers.serialize(
        object.category,
        specifiedType: const FullType(UpdateTicketDtoCategoryEnum),
      );
    }
    if (object.assigneeId != null) {
      yield r'assigneeId';
      yield serializers.serialize(
        object.assigneeId,
        specifiedType: const FullType(String),
      );
    }
    if (object.subject != null) {
      yield r'subject';
      yield serializers.serialize(
        object.subject,
        specifiedType: const FullType(String),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.subCategory != null) {
      yield r'subCategory';
      yield serializers.serialize(
        object.subCategory,
        specifiedType: const FullType(String),
      );
    }
    if (object.vendorId != null) {
      yield r'vendorId';
      yield serializers.serialize(
        object.vendorId,
        specifiedType: const FullType(String),
      );
    }
    if (object.metadata != null) {
      yield r'metadata';
      yield serializers.serialize(
        object.metadata,
        specifiedType: const FullType(JsonObject),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTicketDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateTicketDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdateTicketDtoStatusEnum),
          ) as UpdateTicketDtoStatusEnum;
          result.status = valueDes;
          break;
        case r'priority':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdateTicketDtoPriorityEnum),
          ) as UpdateTicketDtoPriorityEnum;
          result.priority = valueDes;
          break;
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdateTicketDtoCategoryEnum),
          ) as UpdateTicketDtoCategoryEnum;
          result.category = valueDes;
          break;
        case r'assigneeId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.assigneeId = valueDes;
          break;
        case r'subject':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subject = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.description = valueDes;
          break;
        case r'subCategory':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subCategory = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'metadata':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.metadata = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateTicketDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateTicketDtoBuilder();
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

class UpdateTicketDtoStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OPEN')
  static const UpdateTicketDtoStatusEnum OPEN = _$updateTicketDtoStatusEnum_OPEN;
  @BuiltValueEnumConst(wireName: r'IN_PROGRESS')
  static const UpdateTicketDtoStatusEnum IN_PROGRESS = _$updateTicketDtoStatusEnum_IN_PROGRESS;
  @BuiltValueEnumConst(wireName: r'WAITING_ON_USER')
  static const UpdateTicketDtoStatusEnum WAITING_ON_USER = _$updateTicketDtoStatusEnum_WAITING_ON_USER;
  @BuiltValueEnumConst(wireName: r'ESCALATED')
  static const UpdateTicketDtoStatusEnum ESCALATED = _$updateTicketDtoStatusEnum_ESCALATED;
  @BuiltValueEnumConst(wireName: r'RESOLVED')
  static const UpdateTicketDtoStatusEnum RESOLVED = _$updateTicketDtoStatusEnum_RESOLVED;
  @BuiltValueEnumConst(wireName: r'CLOSED')
  static const UpdateTicketDtoStatusEnum CLOSED = _$updateTicketDtoStatusEnum_CLOSED;

  static Serializer<UpdateTicketDtoStatusEnum> get serializer => _$updateTicketDtoStatusEnumSerializer;

  const UpdateTicketDtoStatusEnum._(String name): super(name);

  static BuiltSet<UpdateTicketDtoStatusEnum> get values => _$updateTicketDtoStatusEnumValues;
  static UpdateTicketDtoStatusEnum valueOf(String name) => _$updateTicketDtoStatusEnumValueOf(name);
}

class UpdateTicketDtoPriorityEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'LOW')
  static const UpdateTicketDtoPriorityEnum LOW = _$updateTicketDtoPriorityEnum_LOW;
  @BuiltValueEnumConst(wireName: r'MEDIUM')
  static const UpdateTicketDtoPriorityEnum MEDIUM = _$updateTicketDtoPriorityEnum_MEDIUM;
  @BuiltValueEnumConst(wireName: r'HIGH')
  static const UpdateTicketDtoPriorityEnum HIGH = _$updateTicketDtoPriorityEnum_HIGH;
  @BuiltValueEnumConst(wireName: r'URGENT')
  static const UpdateTicketDtoPriorityEnum URGENT = _$updateTicketDtoPriorityEnum_URGENT;

  static Serializer<UpdateTicketDtoPriorityEnum> get serializer => _$updateTicketDtoPriorityEnumSerializer;

  const UpdateTicketDtoPriorityEnum._(String name): super(name);

  static BuiltSet<UpdateTicketDtoPriorityEnum> get values => _$updateTicketDtoPriorityEnumValues;
  static UpdateTicketDtoPriorityEnum valueOf(String name) => _$updateTicketDtoPriorityEnumValueOf(name);
}

class UpdateTicketDtoCategoryEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'DELIVERY')
  static const UpdateTicketDtoCategoryEnum DELIVERY = _$updateTicketDtoCategoryEnum_DELIVERY;
  @BuiltValueEnumConst(wireName: r'VENDOR')
  static const UpdateTicketDtoCategoryEnum VENDOR = _$updateTicketDtoCategoryEnum_VENDOR;
  @BuiltValueEnumConst(wireName: r'PAYMENT')
  static const UpdateTicketDtoCategoryEnum PAYMENT = _$updateTicketDtoCategoryEnum_PAYMENT;
  @BuiltValueEnumConst(wireName: r'ACCOUNT')
  static const UpdateTicketDtoCategoryEnum ACCOUNT = _$updateTicketDtoCategoryEnum_ACCOUNT;
  @BuiltValueEnumConst(wireName: r'RETURN_COMPLAINT')
  static const UpdateTicketDtoCategoryEnum RETURN_COMPLAINT = _$updateTicketDtoCategoryEnum_RETURN_COMPLAINT;
  @BuiltValueEnumConst(wireName: r'OTHER')
  static const UpdateTicketDtoCategoryEnum OTHER = _$updateTicketDtoCategoryEnum_OTHER;

  static Serializer<UpdateTicketDtoCategoryEnum> get serializer => _$updateTicketDtoCategoryEnumSerializer;

  const UpdateTicketDtoCategoryEnum._(String name): super(name);

  static BuiltSet<UpdateTicketDtoCategoryEnum> get values => _$updateTicketDtoCategoryEnumValues;
  static UpdateTicketDtoCategoryEnum valueOf(String name) => _$updateTicketDtoCategoryEnumValueOf(name);
}

