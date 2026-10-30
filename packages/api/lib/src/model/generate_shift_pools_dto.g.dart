// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_shift_pools_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GenerateShiftPoolsDto extends GenerateShiftPoolsDto {
  @override
  final String startDate;
  @override
  final String endDate;
  @override
  final String startTime;
  @override
  final String endTime;
  @override
  final num maxDrivers;
  @override
  final String? zoneId;
  @override
  final String? title;
  @override
  final String? titleAr;

  factory _$GenerateShiftPoolsDto([
    void Function(GenerateShiftPoolsDtoBuilder)? updates,
  ]) => (GenerateShiftPoolsDtoBuilder()..update(updates))._build();

  _$GenerateShiftPoolsDto._({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.maxDrivers,
    this.zoneId,
    this.title,
    this.titleAr,
  }) : super._();
  @override
  GenerateShiftPoolsDto rebuild(
    void Function(GenerateShiftPoolsDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GenerateShiftPoolsDtoBuilder toBuilder() =>
      GenerateShiftPoolsDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GenerateShiftPoolsDto &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        startTime == other.startTime &&
        endTime == other.endTime &&
        maxDrivers == other.maxDrivers &&
        zoneId == other.zoneId &&
        title == other.title &&
        titleAr == other.titleAr;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, startDate.hashCode);
    _$hash = $jc(_$hash, endDate.hashCode);
    _$hash = $jc(_$hash, startTime.hashCode);
    _$hash = $jc(_$hash, endTime.hashCode);
    _$hash = $jc(_$hash, maxDrivers.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, titleAr.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GenerateShiftPoolsDto')
          ..add('startDate', startDate)
          ..add('endDate', endDate)
          ..add('startTime', startTime)
          ..add('endTime', endTime)
          ..add('maxDrivers', maxDrivers)
          ..add('zoneId', zoneId)
          ..add('title', title)
          ..add('titleAr', titleAr))
        .toString();
  }
}

class GenerateShiftPoolsDtoBuilder
    implements Builder<GenerateShiftPoolsDto, GenerateShiftPoolsDtoBuilder> {
  _$GenerateShiftPoolsDto? _$v;

  String? _startDate;
  String? get startDate => _$this._startDate;
  set startDate(String? startDate) => _$this._startDate = startDate;

  String? _endDate;
  String? get endDate => _$this._endDate;
  set endDate(String? endDate) => _$this._endDate = endDate;

  String? _startTime;
  String? get startTime => _$this._startTime;
  set startTime(String? startTime) => _$this._startTime = startTime;

  String? _endTime;
  String? get endTime => _$this._endTime;
  set endTime(String? endTime) => _$this._endTime = endTime;

  num? _maxDrivers;
  num? get maxDrivers => _$this._maxDrivers;
  set maxDrivers(num? maxDrivers) => _$this._maxDrivers = maxDrivers;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _titleAr;
  String? get titleAr => _$this._titleAr;
  set titleAr(String? titleAr) => _$this._titleAr = titleAr;

  GenerateShiftPoolsDtoBuilder() {
    GenerateShiftPoolsDto._defaults(this);
  }

  GenerateShiftPoolsDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _startDate = $v.startDate;
      _endDate = $v.endDate;
      _startTime = $v.startTime;
      _endTime = $v.endTime;
      _maxDrivers = $v.maxDrivers;
      _zoneId = $v.zoneId;
      _title = $v.title;
      _titleAr = $v.titleAr;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GenerateShiftPoolsDto other) {
    _$v = other as _$GenerateShiftPoolsDto;
  }

  @override
  void update(void Function(GenerateShiftPoolsDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GenerateShiftPoolsDto build() => _build();

  _$GenerateShiftPoolsDto _build() {
    final _$result =
        _$v ??
        _$GenerateShiftPoolsDto._(
          startDate: BuiltValueNullFieldError.checkNotNull(
            startDate,
            r'GenerateShiftPoolsDto',
            'startDate',
          ),
          endDate: BuiltValueNullFieldError.checkNotNull(
            endDate,
            r'GenerateShiftPoolsDto',
            'endDate',
          ),
          startTime: BuiltValueNullFieldError.checkNotNull(
            startTime,
            r'GenerateShiftPoolsDto',
            'startTime',
          ),
          endTime: BuiltValueNullFieldError.checkNotNull(
            endTime,
            r'GenerateShiftPoolsDto',
            'endTime',
          ),
          maxDrivers: BuiltValueNullFieldError.checkNotNull(
            maxDrivers,
            r'GenerateShiftPoolsDto',
            'maxDrivers',
          ),
          zoneId: zoneId,
          title: title,
          titleAr: titleAr,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
