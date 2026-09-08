// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuditLogResponseDto extends AuditLogResponseDto {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String? vendorId;
  @override
  final AuditActionType actionType;
  @override
  final String action;
  @override
  final String entityType;
  @override
  final String entityId;
  @override
  final JsonObject? oldValues;
  @override
  final JsonObject? newValues;
  @override
  final DateTime createdAt;
  @override
  final String? sessionId;
  @override
  final User? user;
  @override
  final Vendor? vendor;
  @override
  final Session? session;

  factory _$AuditLogResponseDto([
    void Function(AuditLogResponseDtoBuilder)? updates,
  ]) => (AuditLogResponseDtoBuilder()..update(updates))._build();

  _$AuditLogResponseDto._({
    required this.id,
    required this.userId,
    this.vendorId,
    required this.actionType,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.oldValues,
    this.newValues,
    required this.createdAt,
    this.sessionId,
    this.user,
    this.vendor,
    this.session,
  }) : super._();
  @override
  AuditLogResponseDto rebuild(
    void Function(AuditLogResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AuditLogResponseDtoBuilder toBuilder() =>
      AuditLogResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuditLogResponseDto &&
        id == other.id &&
        userId == other.userId &&
        vendorId == other.vendorId &&
        actionType == other.actionType &&
        action == other.action &&
        entityType == other.entityType &&
        entityId == other.entityId &&
        oldValues == other.oldValues &&
        newValues == other.newValues &&
        createdAt == other.createdAt &&
        sessionId == other.sessionId &&
        user == other.user &&
        vendor == other.vendor &&
        session == other.session;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, actionType.hashCode);
    _$hash = $jc(_$hash, action.hashCode);
    _$hash = $jc(_$hash, entityType.hashCode);
    _$hash = $jc(_$hash, entityId.hashCode);
    _$hash = $jc(_$hash, oldValues.hashCode);
    _$hash = $jc(_$hash, newValues.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, sessionId.hashCode);
    _$hash = $jc(_$hash, user.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jc(_$hash, session.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuditLogResponseDto')
          ..add('id', id)
          ..add('userId', userId)
          ..add('vendorId', vendorId)
          ..add('actionType', actionType)
          ..add('action', action)
          ..add('entityType', entityType)
          ..add('entityId', entityId)
          ..add('oldValues', oldValues)
          ..add('newValues', newValues)
          ..add('createdAt', createdAt)
          ..add('sessionId', sessionId)
          ..add('user', user)
          ..add('vendor', vendor)
          ..add('session', session))
        .toString();
  }
}

class AuditLogResponseDtoBuilder
    implements Builder<AuditLogResponseDto, AuditLogResponseDtoBuilder> {
  _$AuditLogResponseDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  AuditActionType? _actionType;
  AuditActionType? get actionType => _$this._actionType;
  set actionType(AuditActionType? actionType) =>
      _$this._actionType = actionType;

  String? _action;
  String? get action => _$this._action;
  set action(String? action) => _$this._action = action;

  String? _entityType;
  String? get entityType => _$this._entityType;
  set entityType(String? entityType) => _$this._entityType = entityType;

  String? _entityId;
  String? get entityId => _$this._entityId;
  set entityId(String? entityId) => _$this._entityId = entityId;

  JsonObject? _oldValues;
  JsonObject? get oldValues => _$this._oldValues;
  set oldValues(JsonObject? oldValues) => _$this._oldValues = oldValues;

  JsonObject? _newValues;
  JsonObject? get newValues => _$this._newValues;
  set newValues(JsonObject? newValues) => _$this._newValues = newValues;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _sessionId;
  String? get sessionId => _$this._sessionId;
  set sessionId(String? sessionId) => _$this._sessionId = sessionId;

  UserBuilder? _user;
  UserBuilder get user => _$this._user ??= UserBuilder();
  set user(UserBuilder? user) => _$this._user = user;

  VendorBuilder? _vendor;
  VendorBuilder get vendor => _$this._vendor ??= VendorBuilder();
  set vendor(VendorBuilder? vendor) => _$this._vendor = vendor;

  SessionBuilder? _session;
  SessionBuilder get session => _$this._session ??= SessionBuilder();
  set session(SessionBuilder? session) => _$this._session = session;

  AuditLogResponseDtoBuilder() {
    AuditLogResponseDto._defaults(this);
  }

  AuditLogResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _userId = $v.userId;
      _vendorId = $v.vendorId;
      _actionType = $v.actionType;
      _action = $v.action;
      _entityType = $v.entityType;
      _entityId = $v.entityId;
      _oldValues = $v.oldValues;
      _newValues = $v.newValues;
      _createdAt = $v.createdAt;
      _sessionId = $v.sessionId;
      _user = $v.user?.toBuilder();
      _vendor = $v.vendor?.toBuilder();
      _session = $v.session?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuditLogResponseDto other) {
    _$v = other as _$AuditLogResponseDto;
  }

  @override
  void update(void Function(AuditLogResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuditLogResponseDto build() => _build();

  _$AuditLogResponseDto _build() {
    _$AuditLogResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$AuditLogResponseDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'AuditLogResponseDto',
              'id',
            ),
            userId: BuiltValueNullFieldError.checkNotNull(
              userId,
              r'AuditLogResponseDto',
              'userId',
            ),
            vendorId: vendorId,
            actionType: BuiltValueNullFieldError.checkNotNull(
              actionType,
              r'AuditLogResponseDto',
              'actionType',
            ),
            action: BuiltValueNullFieldError.checkNotNull(
              action,
              r'AuditLogResponseDto',
              'action',
            ),
            entityType: BuiltValueNullFieldError.checkNotNull(
              entityType,
              r'AuditLogResponseDto',
              'entityType',
            ),
            entityId: BuiltValueNullFieldError.checkNotNull(
              entityId,
              r'AuditLogResponseDto',
              'entityId',
            ),
            oldValues: oldValues,
            newValues: newValues,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'AuditLogResponseDto',
              'createdAt',
            ),
            sessionId: sessionId,
            user: _user?.build(),
            vendor: _vendor?.build(),
            session: _session?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'user';
        _user?.build();
        _$failedField = 'vendor';
        _vendor?.build();
        _$failedField = 'session';
        _session?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'AuditLogResponseDto',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
