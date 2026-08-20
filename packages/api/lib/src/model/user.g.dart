// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$User extends User {
  @override
  final String id;
  @override
  final String? email;
  @override
  final String? phone;
  @override
  final String password;
  @override
  final String name;
  @override
  final JsonObject? role;
  @override
  final String? title;
  @override
  final String? titleAr;
  @override
  final BuiltList<Permission> permissions;
  @override
  final String? avatar;
  @override
  final JsonObject? language;
  @override
  final bool isEmailVerified;
  @override
  final bool isPhoneVerified;
  @override
  final bool isBanned;
  @override
  final String? banReason;
  @override
  final String? autoReplyMessage;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  @override
  final BuiltList<AuditLog> auditLogs;
  @override
  final BuiltList<ConversationParticipant> conversations;
  @override
  final JsonObject? customer;
  @override
  final BuiltList<Device> devices;
  @override
  final JsonObject? driver;
  @override
  final BuiltList<Message> messages;
  @override
  final JsonObject? notificationSettings;
  @override
  final BuiltList<Notification> notifications;
  @override
  final BuiltList<Session> sessions;
  @override
  final BuiltList<SupportTicket> assignedTickets;
  @override
  final BuiltList<SupportTicket> createdTickets;
  @override
  final BuiltList<VendorMember> vendorMemberships;
  @override
  final BuiltList<Conversation> createdConversations;
  @override
  final BuiltList<WalletTopUpRequest> approvedTopUps;

  factory _$User([void Function(UserBuilder)? updates]) =>
      (UserBuilder()..update(updates))._build();

  _$User._({
    required this.id,
    this.email,
    this.phone,
    required this.password,
    required this.name,
    this.role,
    this.title,
    this.titleAr,
    required this.permissions,
    this.avatar,
    this.language,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isBanned,
    this.banReason,
    this.autoReplyMessage,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.auditLogs,
    required this.conversations,
    this.customer,
    required this.devices,
    this.driver,
    required this.messages,
    this.notificationSettings,
    required this.notifications,
    required this.sessions,
    required this.assignedTickets,
    required this.createdTickets,
    required this.vendorMemberships,
    required this.createdConversations,
    required this.approvedTopUps,
  }) : super._();
  @override
  User rebuild(void Function(UserBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserBuilder toBuilder() => UserBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is User &&
        id == other.id &&
        email == other.email &&
        phone == other.phone &&
        password == other.password &&
        name == other.name &&
        role == other.role &&
        title == other.title &&
        titleAr == other.titleAr &&
        permissions == other.permissions &&
        avatar == other.avatar &&
        language == other.language &&
        isEmailVerified == other.isEmailVerified &&
        isPhoneVerified == other.isPhoneVerified &&
        isBanned == other.isBanned &&
        banReason == other.banReason &&
        autoReplyMessage == other.autoReplyMessage &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        deletedAt == other.deletedAt &&
        auditLogs == other.auditLogs &&
        conversations == other.conversations &&
        customer == other.customer &&
        devices == other.devices &&
        driver == other.driver &&
        messages == other.messages &&
        notificationSettings == other.notificationSettings &&
        notifications == other.notifications &&
        sessions == other.sessions &&
        assignedTickets == other.assignedTickets &&
        createdTickets == other.createdTickets &&
        vendorMemberships == other.vendorMemberships &&
        createdConversations == other.createdConversations &&
        approvedTopUps == other.approvedTopUps;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, titleAr.hashCode);
    _$hash = $jc(_$hash, permissions.hashCode);
    _$hash = $jc(_$hash, avatar.hashCode);
    _$hash = $jc(_$hash, language.hashCode);
    _$hash = $jc(_$hash, isEmailVerified.hashCode);
    _$hash = $jc(_$hash, isPhoneVerified.hashCode);
    _$hash = $jc(_$hash, isBanned.hashCode);
    _$hash = $jc(_$hash, banReason.hashCode);
    _$hash = $jc(_$hash, autoReplyMessage.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, auditLogs.hashCode);
    _$hash = $jc(_$hash, conversations.hashCode);
    _$hash = $jc(_$hash, customer.hashCode);
    _$hash = $jc(_$hash, devices.hashCode);
    _$hash = $jc(_$hash, driver.hashCode);
    _$hash = $jc(_$hash, messages.hashCode);
    _$hash = $jc(_$hash, notificationSettings.hashCode);
    _$hash = $jc(_$hash, notifications.hashCode);
    _$hash = $jc(_$hash, sessions.hashCode);
    _$hash = $jc(_$hash, assignedTickets.hashCode);
    _$hash = $jc(_$hash, createdTickets.hashCode);
    _$hash = $jc(_$hash, vendorMemberships.hashCode);
    _$hash = $jc(_$hash, createdConversations.hashCode);
    _$hash = $jc(_$hash, approvedTopUps.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'User')
          ..add('id', id)
          ..add('email', email)
          ..add('phone', phone)
          ..add('password', password)
          ..add('name', name)
          ..add('role', role)
          ..add('title', title)
          ..add('titleAr', titleAr)
          ..add('permissions', permissions)
          ..add('avatar', avatar)
          ..add('language', language)
          ..add('isEmailVerified', isEmailVerified)
          ..add('isPhoneVerified', isPhoneVerified)
          ..add('isBanned', isBanned)
          ..add('banReason', banReason)
          ..add('autoReplyMessage', autoReplyMessage)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('deletedAt', deletedAt)
          ..add('auditLogs', auditLogs)
          ..add('conversations', conversations)
          ..add('customer', customer)
          ..add('devices', devices)
          ..add('driver', driver)
          ..add('messages', messages)
          ..add('notificationSettings', notificationSettings)
          ..add('notifications', notifications)
          ..add('sessions', sessions)
          ..add('assignedTickets', assignedTickets)
          ..add('createdTickets', createdTickets)
          ..add('vendorMemberships', vendorMemberships)
          ..add('createdConversations', createdConversations)
          ..add('approvedTopUps', approvedTopUps))
        .toString();
  }
}

class UserBuilder implements Builder<User, UserBuilder> {
  _$User? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  JsonObject? _role;
  JsonObject? get role => _$this._role;
  set role(JsonObject? role) => _$this._role = role;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _titleAr;
  String? get titleAr => _$this._titleAr;
  set titleAr(String? titleAr) => _$this._titleAr = titleAr;

  ListBuilder<Permission>? _permissions;
  ListBuilder<Permission> get permissions =>
      _$this._permissions ??= ListBuilder<Permission>();
  set permissions(ListBuilder<Permission>? permissions) =>
      _$this._permissions = permissions;

  String? _avatar;
  String? get avatar => _$this._avatar;
  set avatar(String? avatar) => _$this._avatar = avatar;

  JsonObject? _language;
  JsonObject? get language => _$this._language;
  set language(JsonObject? language) => _$this._language = language;

  bool? _isEmailVerified;
  bool? get isEmailVerified => _$this._isEmailVerified;
  set isEmailVerified(bool? isEmailVerified) =>
      _$this._isEmailVerified = isEmailVerified;

  bool? _isPhoneVerified;
  bool? get isPhoneVerified => _$this._isPhoneVerified;
  set isPhoneVerified(bool? isPhoneVerified) =>
      _$this._isPhoneVerified = isPhoneVerified;

  bool? _isBanned;
  bool? get isBanned => _$this._isBanned;
  set isBanned(bool? isBanned) => _$this._isBanned = isBanned;

  String? _banReason;
  String? get banReason => _$this._banReason;
  set banReason(String? banReason) => _$this._banReason = banReason;

  String? _autoReplyMessage;
  String? get autoReplyMessage => _$this._autoReplyMessage;
  set autoReplyMessage(String? autoReplyMessage) =>
      _$this._autoReplyMessage = autoReplyMessage;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _$this._deletedAt;
  set deletedAt(DateTime? deletedAt) => _$this._deletedAt = deletedAt;

  ListBuilder<AuditLog>? _auditLogs;
  ListBuilder<AuditLog> get auditLogs =>
      _$this._auditLogs ??= ListBuilder<AuditLog>();
  set auditLogs(ListBuilder<AuditLog>? auditLogs) =>
      _$this._auditLogs = auditLogs;

  ListBuilder<ConversationParticipant>? _conversations;
  ListBuilder<ConversationParticipant> get conversations =>
      _$this._conversations ??= ListBuilder<ConversationParticipant>();
  set conversations(ListBuilder<ConversationParticipant>? conversations) =>
      _$this._conversations = conversations;

  JsonObject? _customer;
  JsonObject? get customer => _$this._customer;
  set customer(JsonObject? customer) => _$this._customer = customer;

  ListBuilder<Device>? _devices;
  ListBuilder<Device> get devices => _$this._devices ??= ListBuilder<Device>();
  set devices(ListBuilder<Device>? devices) => _$this._devices = devices;

  JsonObject? _driver;
  JsonObject? get driver => _$this._driver;
  set driver(JsonObject? driver) => _$this._driver = driver;

  ListBuilder<Message>? _messages;
  ListBuilder<Message> get messages =>
      _$this._messages ??= ListBuilder<Message>();
  set messages(ListBuilder<Message>? messages) => _$this._messages = messages;

  JsonObject? _notificationSettings;
  JsonObject? get notificationSettings => _$this._notificationSettings;
  set notificationSettings(JsonObject? notificationSettings) =>
      _$this._notificationSettings = notificationSettings;

  ListBuilder<Notification>? _notifications;
  ListBuilder<Notification> get notifications =>
      _$this._notifications ??= ListBuilder<Notification>();
  set notifications(ListBuilder<Notification>? notifications) =>
      _$this._notifications = notifications;

  ListBuilder<Session>? _sessions;
  ListBuilder<Session> get sessions =>
      _$this._sessions ??= ListBuilder<Session>();
  set sessions(ListBuilder<Session>? sessions) => _$this._sessions = sessions;

  ListBuilder<SupportTicket>? _assignedTickets;
  ListBuilder<SupportTicket> get assignedTickets =>
      _$this._assignedTickets ??= ListBuilder<SupportTicket>();
  set assignedTickets(ListBuilder<SupportTicket>? assignedTickets) =>
      _$this._assignedTickets = assignedTickets;

  ListBuilder<SupportTicket>? _createdTickets;
  ListBuilder<SupportTicket> get createdTickets =>
      _$this._createdTickets ??= ListBuilder<SupportTicket>();
  set createdTickets(ListBuilder<SupportTicket>? createdTickets) =>
      _$this._createdTickets = createdTickets;

  ListBuilder<VendorMember>? _vendorMemberships;
  ListBuilder<VendorMember> get vendorMemberships =>
      _$this._vendorMemberships ??= ListBuilder<VendorMember>();
  set vendorMemberships(ListBuilder<VendorMember>? vendorMemberships) =>
      _$this._vendorMemberships = vendorMemberships;

  ListBuilder<Conversation>? _createdConversations;
  ListBuilder<Conversation> get createdConversations =>
      _$this._createdConversations ??= ListBuilder<Conversation>();
  set createdConversations(ListBuilder<Conversation>? createdConversations) =>
      _$this._createdConversations = createdConversations;

  ListBuilder<WalletTopUpRequest>? _approvedTopUps;
  ListBuilder<WalletTopUpRequest> get approvedTopUps =>
      _$this._approvedTopUps ??= ListBuilder<WalletTopUpRequest>();
  set approvedTopUps(ListBuilder<WalletTopUpRequest>? approvedTopUps) =>
      _$this._approvedTopUps = approvedTopUps;

  UserBuilder() {
    User._defaults(this);
  }

  UserBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _email = $v.email;
      _phone = $v.phone;
      _password = $v.password;
      _name = $v.name;
      _role = $v.role;
      _title = $v.title;
      _titleAr = $v.titleAr;
      _permissions = $v.permissions.toBuilder();
      _avatar = $v.avatar;
      _language = $v.language;
      _isEmailVerified = $v.isEmailVerified;
      _isPhoneVerified = $v.isPhoneVerified;
      _isBanned = $v.isBanned;
      _banReason = $v.banReason;
      _autoReplyMessage = $v.autoReplyMessage;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _deletedAt = $v.deletedAt;
      _auditLogs = $v.auditLogs.toBuilder();
      _conversations = $v.conversations.toBuilder();
      _customer = $v.customer;
      _devices = $v.devices.toBuilder();
      _driver = $v.driver;
      _messages = $v.messages.toBuilder();
      _notificationSettings = $v.notificationSettings;
      _notifications = $v.notifications.toBuilder();
      _sessions = $v.sessions.toBuilder();
      _assignedTickets = $v.assignedTickets.toBuilder();
      _createdTickets = $v.createdTickets.toBuilder();
      _vendorMemberships = $v.vendorMemberships.toBuilder();
      _createdConversations = $v.createdConversations.toBuilder();
      _approvedTopUps = $v.approvedTopUps.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(User other) {
    _$v = other as _$User;
  }

  @override
  void update(void Function(UserBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  User build() => _build();

  _$User _build() {
    _$User _$result;
    try {
      _$result =
          _$v ??
          _$User._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'User', 'id'),
            email: email,
            phone: phone,
            password: BuiltValueNullFieldError.checkNotNull(
              password,
              r'User',
              'password',
            ),
            name: BuiltValueNullFieldError.checkNotNull(name, r'User', 'name'),
            role: role,
            title: title,
            titleAr: titleAr,
            permissions: permissions.build(),
            avatar: avatar,
            language: language,
            isEmailVerified: BuiltValueNullFieldError.checkNotNull(
              isEmailVerified,
              r'User',
              'isEmailVerified',
            ),
            isPhoneVerified: BuiltValueNullFieldError.checkNotNull(
              isPhoneVerified,
              r'User',
              'isPhoneVerified',
            ),
            isBanned: BuiltValueNullFieldError.checkNotNull(
              isBanned,
              r'User',
              'isBanned',
            ),
            banReason: banReason,
            autoReplyMessage: autoReplyMessage,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'User',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'User',
              'updatedAt',
            ),
            deletedAt: deletedAt,
            auditLogs: auditLogs.build(),
            conversations: conversations.build(),
            customer: customer,
            devices: devices.build(),
            driver: driver,
            messages: messages.build(),
            notificationSettings: notificationSettings,
            notifications: notifications.build(),
            sessions: sessions.build(),
            assignedTickets: assignedTickets.build(),
            createdTickets: createdTickets.build(),
            vendorMemberships: vendorMemberships.build(),
            createdConversations: createdConversations.build(),
            approvedTopUps: approvedTopUps.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'permissions';
        permissions.build();

        _$failedField = 'auditLogs';
        auditLogs.build();
        _$failedField = 'conversations';
        conversations.build();

        _$failedField = 'devices';
        devices.build();

        _$failedField = 'messages';
        messages.build();

        _$failedField = 'notifications';
        notifications.build();
        _$failedField = 'sessions';
        sessions.build();
        _$failedField = 'assignedTickets';
        assignedTickets.build();
        _$failedField = 'createdTickets';
        createdTickets.build();
        _$failedField = 'vendorMemberships';
        vendorMemberships.build();
        _$failedField = 'createdConversations';
        createdConversations.build();
        _$failedField = 'approvedTopUps';
        approvedTopUps.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'User', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
