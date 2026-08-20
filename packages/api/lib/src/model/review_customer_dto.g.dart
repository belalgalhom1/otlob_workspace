// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_customer_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReviewCustomerDto extends ReviewCustomerDto {
  @override
  final ReviewCustomerUserDto user;

  factory _$ReviewCustomerDto([
    void Function(ReviewCustomerDtoBuilder)? updates,
  ]) => (ReviewCustomerDtoBuilder()..update(updates))._build();

  _$ReviewCustomerDto._({required this.user}) : super._();
  @override
  ReviewCustomerDto rebuild(void Function(ReviewCustomerDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReviewCustomerDtoBuilder toBuilder() =>
      ReviewCustomerDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReviewCustomerDto && user == other.user;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, user.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ReviewCustomerDto',
    )..add('user', user)).toString();
  }
}

class ReviewCustomerDtoBuilder
    implements Builder<ReviewCustomerDto, ReviewCustomerDtoBuilder> {
  _$ReviewCustomerDto? _$v;

  ReviewCustomerUserDtoBuilder? _user;
  ReviewCustomerUserDtoBuilder get user =>
      _$this._user ??= ReviewCustomerUserDtoBuilder();
  set user(ReviewCustomerUserDtoBuilder? user) => _$this._user = user;

  ReviewCustomerDtoBuilder() {
    ReviewCustomerDto._defaults(this);
  }

  ReviewCustomerDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _user = $v.user.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReviewCustomerDto other) {
    _$v = other as _$ReviewCustomerDto;
  }

  @override
  void update(void Function(ReviewCustomerDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReviewCustomerDto build() => _build();

  _$ReviewCustomerDto _build() {
    _$ReviewCustomerDto _$result;
    try {
      _$result = _$v ?? _$ReviewCustomerDto._(user: user.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'user';
        user.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ReviewCustomerDto',
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
