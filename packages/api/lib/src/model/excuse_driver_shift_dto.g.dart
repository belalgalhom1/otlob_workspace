// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'excuse_driver_shift_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExcuseDriverShiftDto extends ExcuseDriverShiftDto {
  @override
  final bool isExcused;
  @override
  final String? excuseReason;

  factory _$ExcuseDriverShiftDto([
    void Function(ExcuseDriverShiftDtoBuilder)? updates,
  ]) => (ExcuseDriverShiftDtoBuilder()..update(updates))._build();

  _$ExcuseDriverShiftDto._({required this.isExcused, this.excuseReason})
    : super._();
  @override
  ExcuseDriverShiftDto rebuild(
    void Function(ExcuseDriverShiftDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ExcuseDriverShiftDtoBuilder toBuilder() =>
      ExcuseDriverShiftDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExcuseDriverShiftDto &&
        isExcused == other.isExcused &&
        excuseReason == other.excuseReason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, isExcused.hashCode);
    _$hash = $jc(_$hash, excuseReason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExcuseDriverShiftDto')
          ..add('isExcused', isExcused)
          ..add('excuseReason', excuseReason))
        .toString();
  }
}

class ExcuseDriverShiftDtoBuilder
    implements Builder<ExcuseDriverShiftDto, ExcuseDriverShiftDtoBuilder> {
  _$ExcuseDriverShiftDto? _$v;

  bool? _isExcused;
  bool? get isExcused => _$this._isExcused;
  set isExcused(bool? isExcused) => _$this._isExcused = isExcused;

  String? _excuseReason;
  String? get excuseReason => _$this._excuseReason;
  set excuseReason(String? excuseReason) => _$this._excuseReason = excuseReason;

  ExcuseDriverShiftDtoBuilder() {
    ExcuseDriverShiftDto._defaults(this);
  }

  ExcuseDriverShiftDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _isExcused = $v.isExcused;
      _excuseReason = $v.excuseReason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExcuseDriverShiftDto other) {
    _$v = other as _$ExcuseDriverShiftDto;
  }

  @override
  void update(void Function(ExcuseDriverShiftDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExcuseDriverShiftDto build() => _build();

  _$ExcuseDriverShiftDto _build() {
    final _$result =
        _$v ??
        _$ExcuseDriverShiftDto._(
          isExcused: BuiltValueNullFieldError.checkNotNull(
            isExcused,
            r'ExcuseDriverShiftDto',
            'isExcused',
          ),
          excuseReason: excuseReason,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
