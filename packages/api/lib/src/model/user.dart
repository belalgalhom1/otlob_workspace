//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/support_ticket.dart';
import 'package:api/src/model/role.dart';
import 'package:api/src/model/conversation.dart';
import 'package:api/src/model/language.dart';
import 'package:api/src/model/driver.dart';
import 'package:api/src/model/wallet_top_up_request.dart';
import 'package:api/src/model/permission.dart';
import 'package:api/src/model/session.dart';
import 'package:api/src/model/customer.dart';
import 'package:api/src/model/device.dart';
import 'package:api/src/model/vendor_member.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/conversation_participant.dart';
import 'package:api/src/model/notification.dart';
import 'package:api/src/model/audit_log.dart';
import 'package:api/src/model/notification_setting.dart';
import 'package:api/src/model/message.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'user.g.dart';

/// User
///
/// Properties:
/// * [id] 
/// * [email] 
/// * [phone] 
/// * [password] 
/// * [name] 
/// * [role] 
/// * [title] 
/// * [titleAr] 
/// * [permissions] 
/// * [avatar] 
/// * [language] 
/// * [isEmailVerified] 
/// * [isPhoneVerified] 
/// * [isBanned] 
/// * [banReason] 
/// * [autoReplyMessage] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [deletedAt] 
/// * [auditLogs] 
/// * [conversations] 
/// * [customer] 
/// * [devices] 
/// * [driver] 
/// * [messages] 
/// * [notificationSettings] 
/// * [notifications] 
/// * [sessions] 
/// * [assignedTickets] 
/// * [createdTickets] 
/// * [vendorMemberships] 
/// * [createdConversations] 
/// * [approvedTopUps] 
@BuiltValue()
abstract class User implements Built<User, UserBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'email')
  String? get email;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'password')
  String get password;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'role')
  JsonObject? get role;
  // enum roleEnum {  CUSTOMER,  DRIVER,  VENDOR_MEMBER,  ADMIN,  SUPER_ADMIN,  };

  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'titleAr')
  String? get titleAr;

  @BuiltValueField(wireName: r'permissions')
  BuiltList<Permission> get permissions;

  @BuiltValueField(wireName: r'avatar')
  String? get avatar;

  @BuiltValueField(wireName: r'language')
  JsonObject? get language;
  // enum languageEnum {  EN,  AR,  };

  @BuiltValueField(wireName: r'isEmailVerified')
  bool get isEmailVerified;

  @BuiltValueField(wireName: r'isPhoneVerified')
  bool get isPhoneVerified;

  @BuiltValueField(wireName: r'isBanned')
  bool get isBanned;

  @BuiltValueField(wireName: r'banReason')
  String? get banReason;

  @BuiltValueField(wireName: r'autoReplyMessage')
  String? get autoReplyMessage;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'deletedAt')
  DateTime? get deletedAt;

  @BuiltValueField(wireName: r'auditLogs')
  BuiltList<AuditLog> get auditLogs;

  @BuiltValueField(wireName: r'conversations')
  BuiltList<ConversationParticipant> get conversations;

  @BuiltValueField(wireName: r'customer')
  JsonObject? get customer;

  @BuiltValueField(wireName: r'devices')
  BuiltList<Device> get devices;

  @BuiltValueField(wireName: r'driver')
  JsonObject? get driver;

  @BuiltValueField(wireName: r'messages')
  BuiltList<Message> get messages;

  @BuiltValueField(wireName: r'notificationSettings')
  JsonObject? get notificationSettings;

  @BuiltValueField(wireName: r'notifications')
  BuiltList<Notification> get notifications;

  @BuiltValueField(wireName: r'sessions')
  BuiltList<Session> get sessions;

  @BuiltValueField(wireName: r'assignedTickets')
  BuiltList<SupportTicket> get assignedTickets;

  @BuiltValueField(wireName: r'createdTickets')
  BuiltList<SupportTicket> get createdTickets;

  @BuiltValueField(wireName: r'vendorMemberships')
  BuiltList<VendorMember> get vendorMemberships;

  @BuiltValueField(wireName: r'createdConversations')
  BuiltList<Conversation> get createdConversations;

  @BuiltValueField(wireName: r'approvedTopUps')
  BuiltList<WalletTopUpRequest> get approvedTopUps;

  User._();

  factory User([void updates(UserBuilder b)]) = _$User;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<User> get serializer => _$UserSerializer();
}

class _$UserSerializer implements PrimitiveSerializer<User> {
  @override
  final Iterable<Type> types = const [User, _$User];

  @override
  final String wireName = r'User';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    User object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType(String),
      );
    }
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType(String),
      );
    }
    yield r'password';
    yield serializers.serialize(
      object.password,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(Role),
    );
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType(String),
      );
    }
    if (object.titleAr != null) {
      yield r'titleAr';
      yield serializers.serialize(
        object.titleAr,
        specifiedType: const FullType(String),
      );
    }
    yield r'permissions';
    yield serializers.serialize(
      object.permissions,
      specifiedType: const FullType(BuiltList, [FullType(Permission)]),
    );
    if (object.avatar != null) {
      yield r'avatar';
      yield serializers.serialize(
        object.avatar,
        specifiedType: const FullType(String),
      );
    }
    yield r'language';
    yield serializers.serialize(
      object.language,
      specifiedType: const FullType(Language),
    );
    yield r'isEmailVerified';
    yield serializers.serialize(
      object.isEmailVerified,
      specifiedType: const FullType(bool),
    );
    yield r'isPhoneVerified';
    yield serializers.serialize(
      object.isPhoneVerified,
      specifiedType: const FullType(bool),
    );
    yield r'isBanned';
    yield serializers.serialize(
      object.isBanned,
      specifiedType: const FullType(bool),
    );
    if (object.banReason != null) {
      yield r'banReason';
      yield serializers.serialize(
        object.banReason,
        specifiedType: const FullType(String),
      );
    }
    if (object.autoReplyMessage != null) {
      yield r'autoReplyMessage';
      yield serializers.serialize(
        object.autoReplyMessage,
        specifiedType: const FullType(String),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.deletedAt != null) {
      yield r'deletedAt';
      yield serializers.serialize(
        object.deletedAt,
        specifiedType: const FullType(DateTime),
      );
    }
    yield r'auditLogs';
    yield serializers.serialize(
      object.auditLogs,
      specifiedType: const FullType(BuiltList, [FullType(AuditLog)]),
    );
    yield r'conversations';
    yield serializers.serialize(
      object.conversations,
      specifiedType: const FullType(BuiltList, [FullType(ConversationParticipant)]),
    );
    if (object.customer != null) {
      yield r'customer';
      yield serializers.serialize(
        object.customer,
        specifiedType: const FullType(Customer),
      );
    }
    yield r'devices';
    yield serializers.serialize(
      object.devices,
      specifiedType: const FullType(BuiltList, [FullType(Device)]),
    );
    if (object.driver != null) {
      yield r'driver';
      yield serializers.serialize(
        object.driver,
        specifiedType: const FullType(Driver),
      );
    }
    yield r'messages';
    yield serializers.serialize(
      object.messages,
      specifiedType: const FullType(BuiltList, [FullType(Message)]),
    );
    if (object.notificationSettings != null) {
      yield r'notificationSettings';
      yield serializers.serialize(
        object.notificationSettings,
        specifiedType: const FullType(NotificationSetting),
      );
    }
    yield r'notifications';
    yield serializers.serialize(
      object.notifications,
      specifiedType: const FullType(BuiltList, [FullType(Notification)]),
    );
    yield r'sessions';
    yield serializers.serialize(
      object.sessions,
      specifiedType: const FullType(BuiltList, [FullType(Session)]),
    );
    yield r'assignedTickets';
    yield serializers.serialize(
      object.assignedTickets,
      specifiedType: const FullType(BuiltList, [FullType(SupportTicket)]),
    );
    yield r'createdTickets';
    yield serializers.serialize(
      object.createdTickets,
      specifiedType: const FullType(BuiltList, [FullType(SupportTicket)]),
    );
    yield r'vendorMemberships';
    yield serializers.serialize(
      object.vendorMemberships,
      specifiedType: const FullType(BuiltList, [FullType(VendorMember)]),
    );
    yield r'createdConversations';
    yield serializers.serialize(
      object.createdConversations,
      specifiedType: const FullType(BuiltList, [FullType(Conversation)]),
    );
    yield r'approvedTopUps';
    yield serializers.serialize(
      object.approvedTopUps,
      specifiedType: const FullType(BuiltList, [FullType(WalletTopUpRequest)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    User object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserBuilder result,
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
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        case r'password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.password = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.role = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'titleAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.titleAr = valueDes;
          break;
        case r'permissions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Permission)]),
          ) as BuiltList<Permission>;
          result.permissions.replace(valueDes);
          break;
        case r'avatar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.avatar = valueDes;
          break;
        case r'language':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.language = valueDes;
          break;
        case r'isEmailVerified':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isEmailVerified = valueDes;
          break;
        case r'isPhoneVerified':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isPhoneVerified = valueDes;
          break;
        case r'isBanned':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isBanned = valueDes;
          break;
        case r'banReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.banReason = valueDes;
          break;
        case r'autoReplyMessage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.autoReplyMessage = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'deletedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.deletedAt = valueDes;
          break;
        case r'auditLogs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(AuditLog)]),
          ) as BuiltList<AuditLog>;
          result.auditLogs.replace(valueDes);
          break;
        case r'conversations':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ConversationParticipant)]),
          ) as BuiltList<ConversationParticipant>;
          result.conversations.replace(valueDes);
          break;
        case r'customer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.customer = valueDes;
          break;
        case r'devices':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Device)]),
          ) as BuiltList<Device>;
          result.devices.replace(valueDes);
          break;
        case r'driver':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.driver = valueDes;
          break;
        case r'messages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Message)]),
          ) as BuiltList<Message>;
          result.messages.replace(valueDes);
          break;
        case r'notificationSettings':
          // Patched: skip complex nested type assignment (JsonObject? vs NotificationSettingBuilder?)
          break;
        case r'notifications':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Notification)]),
          ) as BuiltList<Notification>;
          result.notifications.replace(valueDes);
          break;
        case r'sessions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Session)]),
          ) as BuiltList<Session>;
          result.sessions.replace(valueDes);
          break;
        case r'assignedTickets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(SupportTicket)]),
          ) as BuiltList<SupportTicket>;
          result.assignedTickets.replace(valueDes);
          break;
        case r'createdTickets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(SupportTicket)]),
          ) as BuiltList<SupportTicket>;
          result.createdTickets.replace(valueDes);
          break;
        case r'vendorMemberships':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(VendorMember)]),
          ) as BuiltList<VendorMember>;
          result.vendorMemberships.replace(valueDes);
          break;
        case r'createdConversations':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Conversation)]),
          ) as BuiltList<Conversation>;
          result.createdConversations.replace(valueDes);
          break;
        case r'approvedTopUps':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(WalletTopUpRequest)]),
          ) as BuiltList<WalletTopUpRequest>;
          result.approvedTopUps.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  User deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserBuilder();
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




