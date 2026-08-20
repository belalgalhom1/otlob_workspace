//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/user.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'notification_setting.g.dart';

/// NotificationSetting
///
/// Properties:
/// * [id] 
/// * [userId] 
/// * [pushEnabled] 
/// * [orderUpdates] 
/// * [chatMessages] 
/// * [promotions] 
/// * [system] 
/// * [ticketUpdates] 
/// * [updatedAt] 
/// * [user] 
@BuiltValue()
abstract class NotificationSetting implements Built<NotificationSetting, NotificationSettingBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'userId')
  String get userId;

  @BuiltValueField(wireName: r'pushEnabled')
  bool get pushEnabled;

  @BuiltValueField(wireName: r'orderUpdates')
  bool get orderUpdates;

  @BuiltValueField(wireName: r'chatMessages')
  bool get chatMessages;

  @BuiltValueField(wireName: r'promotions')
  bool get promotions;

  @BuiltValueField(wireName: r'system')
  bool get system;

  @BuiltValueField(wireName: r'ticketUpdates')
  bool get ticketUpdates;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'user')
  JsonObject? get user;

  NotificationSetting._();

  factory NotificationSetting([void updates(NotificationSettingBuilder b)]) = _$NotificationSetting;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotificationSettingBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotificationSetting> get serializer => _$NotificationSettingSerializer();
}

class _$NotificationSettingSerializer implements PrimitiveSerializer<NotificationSetting> {
  @override
  final Iterable<Type> types = const [NotificationSetting, _$NotificationSetting];

  @override
  final String wireName = r'NotificationSetting';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotificationSetting object, {
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
    yield r'pushEnabled';
    yield serializers.serialize(
      object.pushEnabled,
      specifiedType: const FullType(bool),
    );
    yield r'orderUpdates';
    yield serializers.serialize(
      object.orderUpdates,
      specifiedType: const FullType(bool),
    );
    yield r'chatMessages';
    yield serializers.serialize(
      object.chatMessages,
      specifiedType: const FullType(bool),
    );
    yield r'promotions';
    yield serializers.serialize(
      object.promotions,
      specifiedType: const FullType(bool),
    );
    yield r'system';
    yield serializers.serialize(
      object.system,
      specifiedType: const FullType(bool),
    );
    yield r'ticketUpdates';
    yield serializers.serialize(
      object.ticketUpdates,
      specifiedType: const FullType(bool),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'user';
    yield serializers.serialize(
      object.user,
      specifiedType: const FullType(User),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotificationSetting object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NotificationSettingBuilder result,
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
        case r'pushEnabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.pushEnabled = valueDes;
          break;
        case r'orderUpdates':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.orderUpdates = valueDes;
          break;
        case r'chatMessages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.chatMessages = valueDes;
          break;
        case r'promotions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.promotions = valueDes;
          break;
        case r'system':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.system = valueDes;
          break;
        case r'ticketUpdates':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.ticketUpdates = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.user = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotificationSetting deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotificationSettingBuilder();
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

