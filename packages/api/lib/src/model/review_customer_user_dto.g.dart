// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_customer_user_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReviewCustomerUserDto extends ReviewCustomerUserDto {
  @override
  final String name;

  factory _$ReviewCustomerUserDto([
    void Function(ReviewCustomerUserDtoBuilder)? updates,
  ]) => (ReviewCustomerUserDtoBuilder()..update(updates))._build();

  _$ReviewCustomerUserDto._({required this.name}) : super._();
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
    return other is ReviewCustomerUserDto && name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ReviewCustomerUserDto',
    )..add('name', name)).toString();
  }
}

class ReviewCustomerUserDtoBuilder
    implements Builder<ReviewCustomerUserDto, ReviewCustomerUserDtoBuilder> {
  _$ReviewCustomerUserDto? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  ReviewCustomerUserDtoBuilder() {
    ReviewCustomerUserDto._defaults(this);
  }

  ReviewCustomerUserDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
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
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'ReviewCustomerUserDto',
            'name',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
