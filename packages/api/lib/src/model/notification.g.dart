// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Notification extends Notification {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String? titleAr;
  @override
  final String? body;
  @override
  final String? bodyAr;
  @override
  final NotificationType type;
  @override
  final bool isRead;
  @override
  final JsonObject? data;
  @override
  final DateTime createdAt;

  factory _$Notification([void Function(NotificationBuilder)? updates]) =>
      (NotificationBuilder()..update(updates))._build();

  _$Notification._({
    required this.id,
    required this.userId,
    required this.title,
    this.titleAr,
    this.body,
    this.bodyAr,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
  }) : super._();
  @override
  Notification rebuild(void Function(NotificationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationBuilder toBuilder() => NotificationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Notification &&
        id == other.id &&
        userId == other.userId &&
        title == other.title &&
        titleAr == other.titleAr &&
        body == other.body &&
        bodyAr == other.bodyAr &&
        type == other.type &&
        isRead == other.isRead &&
        data == other.data &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, titleAr.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, bodyAr.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, isRead.hashCode);
    _$hash = $jc(_$hash, data.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Notification')
          ..add('id', id)
          ..add('userId', userId)
          ..add('title', title)
          ..add('titleAr', titleAr)
          ..add('body', body)
          ..add('bodyAr', bodyAr)
          ..add('type', type)
          ..add('isRead', isRead)
          ..add('data', data)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class NotificationBuilder
    implements Builder<Notification, NotificationBuilder> {
  _$Notification? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _titleAr;
  String? get titleAr => _$this._titleAr;
  set titleAr(String? titleAr) => _$this._titleAr = titleAr;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  String? _bodyAr;
  String? get bodyAr => _$this._bodyAr;
  set bodyAr(String? bodyAr) => _$this._bodyAr = bodyAr;

  NotificationType? _type;
  NotificationType? get type => _$this._type;
  set type(NotificationType? type) => _$this._type = type;

  bool? _isRead;
  bool? get isRead => _$this._isRead;
  set isRead(bool? isRead) => _$this._isRead = isRead;

  JsonObject? _data;
  JsonObject? get data => _$this._data;
  set data(JsonObject? data) => _$this._data = data;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  NotificationBuilder() {
    Notification._defaults(this);
  }

  NotificationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _userId = $v.userId;
      _title = $v.title;
      _titleAr = $v.titleAr;
      _body = $v.body;
      _bodyAr = $v.bodyAr;
      _type = $v.type;
      _isRead = $v.isRead;
      _data = $v.data;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Notification other) {
    _$v = other as _$Notification;
  }

  @override
  void update(void Function(NotificationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Notification build() => _build();

  _$Notification _build() {
    final _$result =
        _$v ??
        _$Notification._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Notification', 'id'),
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'Notification',
            'userId',
          ),
          title: BuiltValueNullFieldError.checkNotNull(
            title,
            r'Notification',
            'title',
          ),
          titleAr: titleAr,
          body: body,
          bodyAr: bodyAr,
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'Notification',
            'type',
          ),
          isRead: BuiltValueNullFieldError.checkNotNull(
            isRead,
            r'Notification',
            'isRead',
          ),
          data: data,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'Notification',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
