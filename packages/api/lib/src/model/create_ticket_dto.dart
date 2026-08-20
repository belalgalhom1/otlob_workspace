//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_ticket_dto.g.dart';

/// CreateTicketDto
///
/// Properties:
/// * [subject] 
/// * [description] 
/// * [category] 
/// * [subCategory] 
/// * [metadata] 
/// * [priority] 
/// * [orderId] 
/// * [vendorId] 
@BuiltValue()
abstract class CreateTicketDto implements Built<CreateTicketDto, CreateTicketDtoBuilder> {
  @BuiltValueField(wireName: r'subject')
  String get subject;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'category')
  CreateTicketDtoCategoryEnum? get category;
  // enum categoryEnum {  DELIVERY,  VENDOR,  PAYMENT,  ACCOUNT,  RETURN_COMPLAINT,  OTHER,  };

  @BuiltValueField(wireName: r'subCategory')
  String? get subCategory;

  @BuiltValueField(wireName: r'metadata')
  JsonObject? get metadata;

  @BuiltValueField(wireName: r'priority')
  CreateTicketDtoPriorityEnum? get priority;
  // enum priorityEnum {  LOW,  MEDIUM,  HIGH,  URGENT,  };

  @BuiltValueField(wireName: r'orderId')
  String? get orderId;

  @BuiltValueField(wireName: r'vendorId')
  String? get vendorId;

  CreateTicketDto._();

  factory CreateTicketDto([void updates(CreateTicketDtoBuilder b)]) = _$CreateTicketDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateTicketDtoBuilder b) => b
      ..category = CreateTicketDtoCategoryEnum.valueOf('OTHER')
      ..priority = CreateTicketDtoPriorityEnum.valueOf('MEDIUM');

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateTicketDto> get serializer => _$CreateTicketDtoSerializer();
}

class _$CreateTicketDtoSerializer implements PrimitiveSerializer<CreateTicketDto> {
  @override
  final Iterable<Type> types = const [CreateTicketDto, _$CreateTicketDto];

  @override
  final String wireName = r'CreateTicketDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateTicketDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'subject';
    yield serializers.serialize(
      object.subject,
      specifiedType: const FullType(String),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.category != null) {
      yield r'category';
      yield serializers.serialize(
        object.category,
        specifiedType: const FullType(CreateTicketDtoCategoryEnum),
      );
    }
    if (object.subCategory != null) {
      yield r'subCategory';
      yield serializers.serialize(
        object.subCategory,
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
    if (object.priority != null) {
      yield r'priority';
      yield serializers.serialize(
        object.priority,
        specifiedType: const FullType(CreateTicketDtoPriorityEnum),
      );
    }
    if (object.orderId != null) {
      yield r'orderId';
      yield serializers.serialize(
        object.orderId,
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
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateTicketDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateTicketDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CreateTicketDtoCategoryEnum),
          ) as CreateTicketDtoCategoryEnum;
          result.category = valueDes;
          break;
        case r'subCategory':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subCategory = valueDes;
          break;
        case r'metadata':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.metadata = valueDes;
          break;
        case r'priority':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CreateTicketDtoPriorityEnum),
          ) as CreateTicketDtoPriorityEnum;
          result.priority = valueDes;
          break;
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateTicketDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateTicketDtoBuilder();
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

class CreateTicketDtoCategoryEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'DELIVERY')
  static const CreateTicketDtoCategoryEnum DELIVERY = _$createTicketDtoCategoryEnum_DELIVERY;
  @BuiltValueEnumConst(wireName: r'VENDOR')
  static const CreateTicketDtoCategoryEnum VENDOR = _$createTicketDtoCategoryEnum_VENDOR;
  @BuiltValueEnumConst(wireName: r'PAYMENT')
  static const CreateTicketDtoCategoryEnum PAYMENT = _$createTicketDtoCategoryEnum_PAYMENT;
  @BuiltValueEnumConst(wireName: r'ACCOUNT')
  static const CreateTicketDtoCategoryEnum ACCOUNT = _$createTicketDtoCategoryEnum_ACCOUNT;
  @BuiltValueEnumConst(wireName: r'RETURN_COMPLAINT')
  static const CreateTicketDtoCategoryEnum RETURN_COMPLAINT = _$createTicketDtoCategoryEnum_RETURN_COMPLAINT;
  @BuiltValueEnumConst(wireName: r'OTHER')
  static const CreateTicketDtoCategoryEnum OTHER = _$createTicketDtoCategoryEnum_OTHER;

  static Serializer<CreateTicketDtoCategoryEnum> get serializer => _$createTicketDtoCategoryEnumSerializer;

  const CreateTicketDtoCategoryEnum._(String name): super(name);

  static BuiltSet<CreateTicketDtoCategoryEnum> get values => _$createTicketDtoCategoryEnumValues;
  static CreateTicketDtoCategoryEnum valueOf(String name) => _$createTicketDtoCategoryEnumValueOf(name);
}

class CreateTicketDtoPriorityEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'LOW')
  static const CreateTicketDtoPriorityEnum LOW = _$createTicketDtoPriorityEnum_LOW;
  @BuiltValueEnumConst(wireName: r'MEDIUM')
  static const CreateTicketDtoPriorityEnum MEDIUM = _$createTicketDtoPriorityEnum_MEDIUM;
  @BuiltValueEnumConst(wireName: r'HIGH')
  static const CreateTicketDtoPriorityEnum HIGH = _$createTicketDtoPriorityEnum_HIGH;
  @BuiltValueEnumConst(wireName: r'URGENT')
  static const CreateTicketDtoPriorityEnum URGENT = _$createTicketDtoPriorityEnum_URGENT;

  static Serializer<CreateTicketDtoPriorityEnum> get serializer => _$createTicketDtoPriorityEnumSerializer;

  const CreateTicketDtoPriorityEnum._(String name): super(name);

  static BuiltSet<CreateTicketDtoPriorityEnum> get values => _$createTicketDtoPriorityEnumValues;
  static CreateTicketDtoPriorityEnum valueOf(String name) => _$createTicketDtoPriorityEnumValueOf(name);
}

