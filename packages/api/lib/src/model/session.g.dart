// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Session extends Session {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String hashedRt;
  @override
  final String? ipAddress;
  @override
  final String? userAgent;
  @override
  final DateTime expiresAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final JsonObject? user;
  @override
  final BuiltList<AuditLog> auditLogs;

  factory _$Session([void Function(SessionBuilder)? updates]) =>
      (SessionBuilder()..update(updates))._build();

  _$Session._({
    required this.id,
    required this.userId,
    required this.hashedRt,
    this.ipAddress,
    this.userAgent,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    required this.auditLogs,
  }) : super._();
  @override
  Session rebuild(void Function(SessionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SessionBuilder toBuilder() => SessionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Session &&
        id == other.id &&
        userId == other.userId &&
        hashedRt == other.hashedRt &&
        ipAddress == other.ipAddress &&
        userAgent == other.userAgent &&
        expiresAt == other.expiresAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        user == other.user &&
        auditLogs == other.auditLogs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, hashedRt.hashCode);
    _$hash = $jc(_$hash, ipAddress.hashCode);
    _$hash = $jc(_$hash, userAgent.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, user.hashCode);
    _$hash = $jc(_$hash, auditLogs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Session')
          ..add('id', id)
          ..add('userId', userId)
          ..add('hashedRt', hashedRt)
          ..add('ipAddress', ipAddress)
          ..add('userAgent', userAgent)
          ..add('expiresAt', expiresAt)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('user', user)
          ..add('auditLogs', auditLogs))
        .toString();
  }
}

class SessionBuilder implements Builder<Session, SessionBuilder> {
  _$Session? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  String? _hashedRt;
  String? get hashedRt => _$this._hashedRt;
  set hashedRt(String? hashedRt) => _$this._hashedRt = hashedRt;

  String? _ipAddress;
  String? get ipAddress => _$this._ipAddress;
  set ipAddress(String? ipAddress) => _$this._ipAddress = ipAddress;

  String? _userAgent;
  String? get userAgent => _$this._userAgent;
  set userAgent(String? userAgent) => _$this._userAgent = userAgent;

  DateTime? _expiresAt;
  DateTime? get expiresAt => _$this._expiresAt;
  set expiresAt(DateTime? expiresAt) => _$this._expiresAt = expiresAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  JsonObject? _user;
  JsonObject? get user => _$this._user;
  set user(JsonObject? user) => _$this._user = user;

  ListBuilder<AuditLog>? _auditLogs;
  ListBuilder<AuditLog> get auditLogs =>
      _$this._auditLogs ??= ListBuilder<AuditLog>();
  set auditLogs(ListBuilder<AuditLog>? auditLogs) =>
      _$this._auditLogs = auditLogs;

  SessionBuilder() {
    Session._defaults(this);
  }

  SessionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _userId = $v.userId;
      _hashedRt = $v.hashedRt;
      _ipAddress = $v.ipAddress;
      _userAgent = $v.userAgent;
      _expiresAt = $v.expiresAt;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _user = $v.user;
      _auditLogs = $v.auditLogs.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Session other) {
    _$v = other as _$Session;
  }

  @override
  void update(void Function(SessionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Session build() => _build();

  _$Session _build() {
    _$Session _$result;
    try {
      _$result =
          _$v ??
          _$Session._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Session', 'id'),
            userId: BuiltValueNullFieldError.checkNotNull(
              userId,
              r'Session',
              'userId',
            ),
            hashedRt: BuiltValueNullFieldError.checkNotNull(
              hashedRt,
              r'Session',
              'hashedRt',
            ),
            ipAddress: ipAddress,
            userAgent: userAgent,
            expiresAt: BuiltValueNullFieldError.checkNotNull(
              expiresAt,
              r'Session',
              'expiresAt',
            ),
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'Session',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'Session',
              'updatedAt',
            ),
            user: user,
            auditLogs: auditLogs.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'auditLogs';
        auditLogs.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Session',
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
