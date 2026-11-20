// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_customer_user_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReviewCustomerUserDto extends ReviewCustomerUserDto {
  @override
  final String? id;
  @override
  final String name;
  @override
  final JsonObject? avatar;

  factory _$ReviewCustomerUserDto([
    void Function(ReviewCustomerUserDtoBuilder)? updates,
  ]) => (ReviewCustomerUserDtoBuilder()..update(updates))._build();

  _$ReviewCustomerUserDto._({this.id, required this.name, this.avatar})
    : super._();
  @override
  ReviewCustomerUserDto rebuild(
    void Function(ReviewCustomerUserDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ReviewCustomerUserDtoBuilder toBuilder() =>
      ReviewCustomerUserDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReviewCustomerUserDto &&
        id == other.id &&
        name == other.name &&
        avatar == other.avatar;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, avatar.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReviewCustomerUserDto')
          ..add('id', id)
          ..add('name', name)
          ..add('avatar', avatar))
        .toString();
  }
}

class ReviewCustomerUserDtoBuilder
    implements Builder<ReviewCustomerUserDto, ReviewCustomerUserDtoBuilder> {
  _$ReviewCustomerUserDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  JsonObject? _avatar;
  JsonObject? get avatar => _$this._avatar;
  set avatar(JsonObject? avatar) => _$this._avatar = avatar;

  ReviewCustomerUserDtoBuilder() {
    ReviewCustomerUserDto._defaults(this);
  }

  ReviewCustomerUserDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _avatar = $v.avatar;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReviewCustomerUserDto other) {
    _$v = other as _$ReviewCustomerUserDto;
  }

  @override
  void update(void Function(ReviewCustomerUserDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReviewCustomerUserDto build() => _build();

  _$ReviewCustomerUserDto _build() {
    final _$result =
        _$v ??
        _$ReviewCustomerUserDto._(
          id: id,
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'ReviewCustomerUserDto',
            'name',
          ),
          avatar: avatar,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
