//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/vendor.dart';
import 'package:api/src/model/audit_action_type.dart';
import 'package:api/src/model/session.dart';
import 'package:built_value/json_object.dart';
import 'package:api/src/model/user.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'audit_log_response_dto.g.dart';

/// AuditLogResponseDto
///
/// Properties:
/// * [id] 
/// * [userId] 
/// * [vendorId] 
/// * [actionType] 
/// * [action] 
/// * [entityType] 
/// * [entityId] 
/// * [oldValues] 
/// * [newValues] 
/// * [createdAt] 
/// * [sessionId] 
/// * [user] 
/// * [vendor] 
/// * [session] 
@BuiltValue()
abstract class AuditLogResponseDto implements Built<AuditLogResponseDto, AuditLogResponseDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'userId')
  String get userId;

  @BuiltValueField(wireName: r'vendorId')
  String? get vendorId;

  @BuiltValueField(wireName: r'actionType')
  AuditActionType get actionType;
  // enum actionTypeEnum {  CREATE,  UPDATE,  DELETE,  OTHER,  };

  @BuiltValueField(wireName: r'action')
  String get action;

  @BuiltValueField(wireName: r'entityType')
  String get entityType;

  @BuiltValueField(wireName: r'entityId')
  String get entityId;

  @BuiltValueField(wireName: r'oldValues')
  JsonObject? get oldValues;

  @BuiltValueField(wireName: r'newValues')
  JsonObject? get newValues;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'sessionId')
  String? get sessionId;

  @BuiltValueField(wireName: r'user')
  User? get user;

  @BuiltValueField(wireName: r'vendor')
  Vendor? get vendor;

  @BuiltValueField(wireName: r'session')
  Session? get session;

  AuditLogResponseDto._();

  factory AuditLogResponseDto([void updates(AuditLogResponseDtoBuilder b)]) = _$AuditLogResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AuditLogResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AuditLogResponseDto> get serializer => _$AuditLogResponseDtoSerializer();
}

class _$AuditLogResponseDtoSerializer implements PrimitiveSerializer<AuditLogResponseDto> {
  @override
  final Iterable<Type> types = const [AuditLogResponseDto, _$AuditLogResponseDto];

  @override
  final String wireName = r'AuditLogResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AuditLogResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'userId';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    if (object.vendorId != null) {
      yield r'vendorId';
      yield serializers.serialize(
        object.vendorId,
        specifiedType: const FullType(String),
      );
    }
    yield r'actionType';
    yield serializers.serialize(
      object.actionType,
      specifiedType: const FullType(AuditActionType),
    );
    yield r'action';
    yield serializers.serialize(
      object.action,
      specifiedType: const FullType(String),
    );
    yield r'entityType';
    yield serializers.serialize(
      object.entityType,
      specifiedType: const FullType(String),
    );
    yield r'entityId';
    yield serializers.serialize(
      object.entityId,
      specifiedType: const FullType(String),
    );
    if (object.oldValues != null) {
      yield r'oldValues';
      yield serializers.serialize(
        object.oldValues,
        specifiedType: const FullType(JsonObject),
      );
    }
    if (object.newValues != null) {
      yield r'newValues';
      yield serializers.serialize(
        object.newValues,
        specifiedType: const FullType(JsonObject),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.sessionId != null) {
      yield r'sessionId';
      yield serializers.serialize(
        object.sessionId,
        specifiedType: const FullType(String),
      );
    }
    if (object.user != null) {
      yield r'user';
      yield serializers.serialize(
        object.user,
        specifiedType: const FullType(User),
      );
    }
    if (object.vendor != null) {
      yield r'vendor';
      yield serializers.serialize(
        object.vendor,
        specifiedType: const FullType(Vendor),
      );
    }
    if (object.session != null) {
      yield r'session';
      yield serializers.serialize(
        object.session,
        specifiedType: const FullType(Session),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AuditLogResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AuditLogResponseDtoBuilder result,
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
        case r'userId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'actionType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AuditActionType),
          ) as AuditActionType;
          result.actionType = valueDes;
          break;
        case r'action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.action = valueDes;
          break;
        case r'entityType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.entityType = valueDes;
          break;
        case r'entityId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.entityId = valueDes;
          break;
        case r'oldValues':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.oldValues = valueDes;
          break;
        case r'newValues':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.newValues = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'sessionId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.sessionId = valueDes;
          break;
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(User),
          ) as User;
          result.user.replace(valueDes);
          break;
        case r'vendor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Vendor),
          ) as Vendor;
          result.vendor.replace(valueDes);
          break;
        case r'session':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Session),
          ) as Session;
          result.session.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AuditLogResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AuditLogResponseDtoBuilder();
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

