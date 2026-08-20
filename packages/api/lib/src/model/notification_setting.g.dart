// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_setting.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationSetting extends NotificationSetting {
  @override
  final String id;
  @override
  final String userId;
  @override
  final bool pushEnabled;
  @override
  final bool orderUpdates;
  @override
  final bool chatMessages;
  @override
  final bool promotions;
  @override
  final bool system;
  @override
  final bool ticketUpdates;
  @override
  final DateTime updatedAt;
  @override
  final JsonObject? user;

  factory _$NotificationSetting([
    void Function(NotificationSettingBuilder)? updates,
  ]) => (NotificationSettingBuilder()..update(updates))._build();

  _$NotificationSetting._({
    required this.id,
    required this.userId,
    required this.pushEnabled,
    required this.orderUpdates,
    required this.chatMessages,
    required this.promotions,
    required this.system,
    required this.ticketUpdates,
    required this.updatedAt,
    this.user,
  }) : super._();
  @override
  NotificationSetting rebuild(
    void Function(NotificationSettingBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotificationSettingBuilder toBuilder() =>
      NotificationSettingBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationSetting &&
        id == other.id &&
        userId == other.userId &&
        pushEnabled == other.pushEnabled &&
        orderUpdates == other.orderUpdates &&
        chatMessages == other.chatMessages &&
        promotions == other.promotions &&
        system == other.system &&
        ticketUpdates == other.ticketUpdates &&
        updatedAt == other.updatedAt &&
        user == other.user;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, pushEnabled.hashCode);
    _$hash = $jc(_$hash, orderUpdates.hashCode);
    _$hash = $jc(_$hash, chatMessages.hashCode);
    _$hash = $jc(_$hash, promotions.hashCode);
    _$hash = $jc(_$hash, system.hashCode);
    _$hash = $jc(_$hash, ticketUpdates.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, user.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotificationSetting')
          ..add('id', id)
          ..add('userId', userId)
          ..add('pushEnabled', pushEnabled)
          ..add('orderUpdates', orderUpdates)
          ..add('chatMessages', chatMessages)
          ..add('promotions', promotions)
          ..add('system', system)
          ..add('ticketUpdates', ticketUpdates)
          ..add('updatedAt', updatedAt)
          ..add('user', user))
        .toString();
  }
}

class NotificationSettingBuilder
    implements Builder<NotificationSetting, NotificationSettingBuilder> {
  _$NotificationSetting? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  bool? _pushEnabled;
  bool? get pushEnabled => _$this._pushEnabled;
  set pushEnabled(bool? pushEnabled) => _$this._pushEnabled = pushEnabled;

  bool? _orderUpdates;
  bool? get orderUpdates => _$this._orderUpdates;
  set orderUpdates(bool? orderUpdates) => _$this._orderUpdates = orderUpdates;

  bool? _chatMessages;
  bool? get chatMessages => _$this._chatMessages;
  set chatMessages(bool? chatMessages) => _$this._chatMessages = chatMessages;

  bool? _promotions;
  bool? get promotions => _$this._promotions;
  set promotions(bool? promotions) => _$this._promotions = promotions;

  bool? _system;
  bool? get system => _$this._system;
  set system(bool? system) => _$this._system = system;

  bool? _ticketUpdates;
  bool? get ticketUpdates => _$this._ticketUpdates;
  set ticketUpdates(bool? ticketUpdates) =>
      _$this._ticketUpdates = ticketUpdates;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  JsonObject? _user;
  JsonObject? get user => _$this._user;
  set user(JsonObject? user) => _$this._user = user;

  NotificationSettingBuilder() {
    NotificationSetting._defaults(this);
  }

  NotificationSettingBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _userId = $v.userId;
      _pushEnabled = $v.pushEnabled;
      _orderUpdates = $v.orderUpdates;
      _chatMessages = $v.chatMessages;
      _promotions = $v.promotions;
      _system = $v.system;
      _ticketUpdates = $v.ticketUpdates;
      _updatedAt = $v.updatedAt;
      _user = $v.user;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotificationSetting other) {
    _$v = other as _$NotificationSetting;
  }

  @override
  void update(void Function(NotificationSettingBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotificationSetting build() => _build();

  _$NotificationSetting _build() {
    final _$result =
        _$v ??
        _$NotificationSetting._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'NotificationSetting',
            'id',
          ),
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'NotificationSetting',
            'userId',
          ),
          pushEnabled: BuiltValueNullFieldError.checkNotNull(
            pushEnabled,
            r'NotificationSetting',
            'pushEnabled',
          ),
          orderUpdates: BuiltValueNullFieldError.checkNotNull(
            orderUpdates,
            r'NotificationSetting',
            'orderUpdates',
          ),
          chatMessages: BuiltValueNullFieldError.checkNotNull(
            chatMessages,
            r'NotificationSetting',
            'chatMessages',
          ),
          promotions: BuiltValueNullFieldError.checkNotNull(
            promotions,
            r'NotificationSetting',
            'promotions',
          ),
          system: BuiltValueNullFieldError.checkNotNull(
            system,
            r'NotificationSetting',
            'system',
          ),
          ticketUpdates: BuiltValueNullFieldError.checkNotNull(
            ticketUpdates,
            r'NotificationSetting',
            'ticketUpdates',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'NotificationSetting',
            'updatedAt',
          ),
          user: user,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
