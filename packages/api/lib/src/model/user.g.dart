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
  final String? password;
  @override
  final String name;
  @override
  final Role role;
  @override
  final String? title;
  @override
  final String? titleAr;
  @override
  final BuiltList<Permission> permissions;
  @override
  final String? avatar;
  @override
  final Language language;
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

  factory _$User([void Function(UserBuilder)? updates]) =>
      (UserBuilder()..update(updates))._build();

  _$User._({
    required this.id,
    this.email,
    this.phone,
    this.password,
    required this.name,
    required this.role,
    this.title,
    this.titleAr,
    required this.permissions,
    this.avatar,
    required this.language,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isBanned,
    this.banReason,
    this.autoReplyMessage,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
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
        deletedAt == other.deletedAt;
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
          ..add('deletedAt', deletedAt))
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

  Role? _role;
  Role? get role => _$this._role;
  set role(Role? role) => _$this._role = role;

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

  Language? _language;
  Language? get language => _$this._language;
  set language(Language? language) => _$this._language = language;

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
            password: password,
            name: BuiltValueNullFieldError.checkNotNull(name, r'User', 'name'),
            role: BuiltValueNullFieldError.checkNotNull(role, r'User', 'role'),
            title: title,
            titleAr: titleAr,
            permissions: permissions.build(),
            avatar: avatar,
            language: BuiltValueNullFieldError.checkNotNull(
              language,
              r'User',
              'language',
            ),
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
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'permissions';
        permissions.build();
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
