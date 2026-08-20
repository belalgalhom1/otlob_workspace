// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_notification_settings_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateNotificationSettingsDto extends UpdateNotificationSettingsDto {
  @override
  final bool? pushEnabled;
  @override
  final bool? orderUpdates;
  @override
  final bool? chatMessages;
  @override
  final bool? promotions;
  @override
  final bool? system;

  factory _$UpdateNotificationSettingsDto([
    void Function(UpdateNotificationSettingsDtoBuilder)? updates,
  ]) => (UpdateNotificationSettingsDtoBuilder()..update(updates))._build();

  _$UpdateNotificationSettingsDto._({
    this.pushEnabled,
    this.orderUpdates,
    this.chatMessages,
    this.promotions,
    this.system,
  }) : super._();
  @override
  UpdateNotificationSettingsDto rebuild(
    void Function(UpdateNotificationSettingsDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateNotificationSettingsDtoBuilder toBuilder() =>
      UpdateNotificationSettingsDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateNotificationSettingsDto &&
        pushEnabled == other.pushEnabled &&
        orderUpdates == other.orderUpdates &&
        chatMessages == other.chatMessages &&
        promotions == other.promotions &&
        system == other.system;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, pushEnabled.hashCode);
    _$hash = $jc(_$hash, orderUpdates.hashCode);
    _$hash = $jc(_$hash, chatMessages.hashCode);
    _$hash = $jc(_$hash, promotions.hashCode);
    _$hash = $jc(_$hash, system.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateNotificationSettingsDto')
          ..add('pushEnabled', pushEnabled)
          ..add('orderUpdates', orderUpdates)
          ..add('chatMessages', chatMessages)
          ..add('promotions', promotions)
          ..add('system', system))
        .toString();
  }
}

class UpdateNotificationSettingsDtoBuilder
    implements
        Builder<
          UpdateNotificationSettingsDto,
          UpdateNotificationSettingsDtoBuilder
        > {
  _$UpdateNotificationSettingsDto? _$v;

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

  UpdateNotificationSettingsDtoBuilder() {
    UpdateNotificationSettingsDto._defaults(this);
  }

  UpdateNotificationSettingsDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _pushEnabled = $v.pushEnabled;
      _orderUpdates = $v.orderUpdates;
      _chatMessages = $v.chatMessages;
      _promotions = $v.promotions;
      _system = $v.system;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateNotificationSettingsDto other) {
    _$v = other as _$UpdateNotificationSettingsDto;
  }

  @override
  void update(void Function(UpdateNotificationSettingsDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateNotificationSettingsDto build() => _build();

  _$UpdateNotificationSettingsDto _build() {
    final _$result =
        _$v ??
        _$UpdateNotificationSettingsDto._(
          pushEnabled: pushEnabled,
          orderUpdates: orderUpdates,
          chatMessages: chatMessages,
          promotions: promotions,
          system: system,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
