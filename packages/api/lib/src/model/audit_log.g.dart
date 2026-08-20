// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuditLog extends AuditLog {
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

  factory _$AuditLog([void Function(AuditLogBuilder)? updates]) =>
      (AuditLogBuilder()..update(updates))._build();

  _$AuditLog._({
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
  }) : super._();
  @override
  AuditLog rebuild(void Function(AuditLogBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AuditLogBuilder toBuilder() => AuditLogBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuditLog &&
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
        sessionId == other.sessionId;
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
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuditLog')
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
          ..add('sessionId', sessionId))
        .toString();
  }
}

class AuditLogBuilder implements Builder<AuditLog, AuditLogBuilder> {
  _$AuditLog? _$v;

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

  AuditLogBuilder() {
    AuditLog._defaults(this);
  }

  AuditLogBuilder get _$this {
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
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuditLog other) {
    _$v = other as _$AuditLog;
  }

  @override
  void update(void Function(AuditLogBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuditLog build() => _build();

  _$AuditLog _build() {
    final _$result =
        _$v ??
        _$AuditLog._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'AuditLog', 'id'),
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'AuditLog',
            'userId',
          ),
          vendorId: vendorId,
          actionType: BuiltValueNullFieldError.checkNotNull(
            actionType,
            r'AuditLog',
            'actionType',
          ),
          action: BuiltValueNullFieldError.checkNotNull(
            action,
            r'AuditLog',
            'action',
          ),
          entityType: BuiltValueNullFieldError.checkNotNull(
            entityType,
            r'AuditLog',
            'entityType',
          ),
          entityId: BuiltValueNullFieldError.checkNotNull(
            entityId,
            r'AuditLog',
            'entityId',
          ),
          oldValues: oldValues,
          newValues: newValues,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'AuditLog',
            'createdAt',
          ),
          sessionId: sessionId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
