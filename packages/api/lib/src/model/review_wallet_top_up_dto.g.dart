// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_wallet_top_up_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReviewWalletTopUpDto extends ReviewWalletTopUpDto {
  @override
  final String status;

  factory _$ReviewWalletTopUpDto([
    void Function(ReviewWalletTopUpDtoBuilder)? updates,
  ]) => (ReviewWalletTopUpDtoBuilder()..update(updates))._build();

  _$ReviewWalletTopUpDto._({required this.status}) : super._();
  @override
  ReviewWalletTopUpDto rebuild(
    void Function(ReviewWalletTopUpDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ReviewWalletTopUpDtoBuilder toBuilder() =>
      ReviewWalletTopUpDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReviewWalletTopUpDto && status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ReviewWalletTopUpDto',
    )..add('status', status)).toString();
  }
}

class ReviewWalletTopUpDtoBuilder
    implements Builder<ReviewWalletTopUpDto, ReviewWalletTopUpDtoBuilder> {
  _$ReviewWalletTopUpDto? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  ReviewWalletTopUpDtoBuilder() {
    ReviewWalletTopUpDto._defaults(this);
  }

  ReviewWalletTopUpDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReviewWalletTopUpDto other) {
    _$v = other as _$ReviewWalletTopUpDto;
  }

  @override
  void update(void Function(ReviewWalletTopUpDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReviewWalletTopUpDto build() => _build();

  _$ReviewWalletTopUpDto _build() {
    final _$result =
        _$v ??
        _$ReviewWalletTopUpDto._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'ReviewWalletTopUpDto',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
