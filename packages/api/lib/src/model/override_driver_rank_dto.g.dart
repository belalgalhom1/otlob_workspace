// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'override_driver_rank_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OverrideDriverRankDto extends OverrideDriverRankDto {
  @override
  final DriverTier newTier;
  @override
  final String reason;

  factory _$OverrideDriverRankDto([
    void Function(OverrideDriverRankDtoBuilder)? updates,
  ]) => (OverrideDriverRankDtoBuilder()..update(updates))._build();

  _$OverrideDriverRankDto._({required this.newTier, required this.reason})
    : super._();
  @override
  OverrideDriverRankDto rebuild(
    void Function(OverrideDriverRankDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OverrideDriverRankDtoBuilder toBuilder() =>
      OverrideDriverRankDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OverrideDriverRankDto &&
        newTier == other.newTier &&
        reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, newTier.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OverrideDriverRankDto')
          ..add('newTier', newTier)
          ..add('reason', reason))
        .toString();
  }
}

class OverrideDriverRankDtoBuilder
    implements Builder<OverrideDriverRankDto, OverrideDriverRankDtoBuilder> {
  _$OverrideDriverRankDto? _$v;

  DriverTier? _newTier;
  DriverTier? get newTier => _$this._newTier;
  set newTier(DriverTier? newTier) => _$this._newTier = newTier;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  OverrideDriverRankDtoBuilder() {
    OverrideDriverRankDto._defaults(this);
  }

  OverrideDriverRankDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _newTier = $v.newTier;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OverrideDriverRankDto other) {
    _$v = other as _$OverrideDriverRankDto;
  }

  @override
  void update(void Function(OverrideDriverRankDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OverrideDriverRankDto build() => _build();

  _$OverrideDriverRankDto _build() {
    final _$result =
        _$v ??
        _$OverrideDriverRankDto._(
          newTier: BuiltValueNullFieldError.checkNotNull(
            newTier,
            r'OverrideDriverRankDto',
            'newTier',
          ),
          reason: BuiltValueNullFieldError.checkNotNull(
            reason,
            r'OverrideDriverRankDto',
            'reason',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
