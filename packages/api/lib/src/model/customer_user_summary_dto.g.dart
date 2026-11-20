// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_user_summary_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CustomerUserSummaryDto extends CustomerUserSummaryDto {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? phone;
  @override
  final String? avatar;

  factory _$CustomerUserSummaryDto([
    void Function(CustomerUserSummaryDtoBuilder)? updates,
  ]) => (CustomerUserSummaryDtoBuilder()..update(updates))._build();

  _$CustomerUserSummaryDto._({
    required this.id,
    required this.name,
    this.phone,
    this.avatar,
  }) : super._();
  @override
  CustomerUserSummaryDto rebuild(
    void Function(CustomerUserSummaryDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CustomerUserSummaryDtoBuilder toBuilder() =>
      CustomerUserSummaryDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CustomerUserSummaryDto &&
        id == other.id &&
        name == other.name &&
        phone == other.phone &&
        avatar == other.avatar;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, avatar.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CustomerUserSummaryDto')
          ..add('id', id)
          ..add('name', name)
          ..add('phone', phone)
          ..add('avatar', avatar))
        .toString();
  }
}

class CustomerUserSummaryDtoBuilder
    implements Builder<CustomerUserSummaryDto, CustomerUserSummaryDtoBuilder> {
  _$CustomerUserSummaryDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  String? _avatar;
  String? get avatar => _$this._avatar;
  set avatar(String? avatar) => _$this._avatar = avatar;

  CustomerUserSummaryDtoBuilder() {
    CustomerUserSummaryDto._defaults(this);
  }

  CustomerUserSummaryDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _phone = $v.phone;
      _avatar = $v.avatar;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CustomerUserSummaryDto other) {
    _$v = other as _$CustomerUserSummaryDto;
  }

  @override
  void update(void Function(CustomerUserSummaryDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CustomerUserSummaryDto build() => _build();

  _$CustomerUserSummaryDto _build() {
    final _$result =
        _$v ??
        _$CustomerUserSummaryDto._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'CustomerUserSummaryDto',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'CustomerUserSummaryDto',
            'name',
          ),
          phone: phone,
          avatar: avatar,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
