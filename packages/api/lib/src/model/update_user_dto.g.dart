// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_user_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateUserDtoLanguageEnum _$updateUserDtoLanguageEnum_EN =
    const UpdateUserDtoLanguageEnum._('EN');
const UpdateUserDtoLanguageEnum _$updateUserDtoLanguageEnum_AR =
    const UpdateUserDtoLanguageEnum._('AR');

UpdateUserDtoLanguageEnum _$updateUserDtoLanguageEnumValueOf(String name) {
  switch (name) {
    case 'EN':
      return _$updateUserDtoLanguageEnum_EN;
    case 'AR':
      return _$updateUserDtoLanguageEnum_AR;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateUserDtoLanguageEnum> _$updateUserDtoLanguageEnumValues =
    BuiltSet<UpdateUserDtoLanguageEnum>(const <UpdateUserDtoLanguageEnum>[
      _$updateUserDtoLanguageEnum_EN,
      _$updateUserDtoLanguageEnum_AR,
    ]);

Serializer<UpdateUserDtoLanguageEnum> _$updateUserDtoLanguageEnumSerializer =
    _$UpdateUserDtoLanguageEnumSerializer();

class _$UpdateUserDtoLanguageEnumSerializer
    implements PrimitiveSerializer<UpdateUserDtoLanguageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'EN': 'EN',
    'AR': 'AR',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'EN': 'EN',
    'AR': 'AR',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateUserDtoLanguageEnum];
  @override
  final String wireName = 'UpdateUserDtoLanguageEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateUserDtoLanguageEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateUserDtoLanguageEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateUserDtoLanguageEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateUserDto extends UpdateUserDto {
  @override
  final String? name;
  @override
  final String? email;
  @override
  final String? phone;
  @override
  final UpdateUserDtoLanguageEnum? language;
  @override
  final String? autoReplyMessage;

  factory _$UpdateUserDto([void Function(UpdateUserDtoBuilder)? updates]) =>
      (UpdateUserDtoBuilder()..update(updates))._build();

  _$UpdateUserDto._({
    this.name,
    this.email,
    this.phone,
    this.language,
    this.autoReplyMessage,
  }) : super._();
  @override
  UpdateUserDto rebuild(void Function(UpdateUserDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateUserDtoBuilder toBuilder() => UpdateUserDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateUserDto &&
        name == other.name &&
        email == other.email &&
        phone == other.phone &&
        language == other.language &&
        autoReplyMessage == other.autoReplyMessage;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, language.hashCode);
    _$hash = $jc(_$hash, autoReplyMessage.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateUserDto')
          ..add('name', name)
          ..add('email', email)
          ..add('phone', phone)
          ..add('language', language)
          ..add('autoReplyMessage', autoReplyMessage))
        .toString();
  }
}

class UpdateUserDtoBuilder
    implements Builder<UpdateUserDto, UpdateUserDtoBuilder> {
  _$UpdateUserDto? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  UpdateUserDtoLanguageEnum? _language;
  UpdateUserDtoLanguageEnum? get language => _$this._language;
  set language(UpdateUserDtoLanguageEnum? language) =>
      _$this._language = language;

  String? _autoReplyMessage;
  String? get autoReplyMessage => _$this._autoReplyMessage;
  set autoReplyMessage(String? autoReplyMessage) =>
      _$this._autoReplyMessage = autoReplyMessage;

  UpdateUserDtoBuilder() {
    UpdateUserDto._defaults(this);
  }

  UpdateUserDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _email = $v.email;
      _phone = $v.phone;
      _language = $v.language;
      _autoReplyMessage = $v.autoReplyMessage;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateUserDto other) {
    _$v = other as _$UpdateUserDto;
  }

  @override
  void update(void Function(UpdateUserDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateUserDto build() => _build();

  _$UpdateUserDto _build() {
    final _$result =
        _$v ??
        _$UpdateUserDto._(
          name: name,
          email: email,
          phone: phone,
          language: language,
          autoReplyMessage: autoReplyMessage,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
