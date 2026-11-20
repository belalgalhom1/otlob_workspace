// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_pool.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ShiftPool extends ShiftPool {
  @override
  final String id;
  @override
  final String? batchId;
  @override
  final String? title;
  @override
  final String? titleAr;
  @override
  final String? zoneId;
  @override
  final DateTime shiftDate;
  @override
  final DateTime startTime;
  @override
  final DateTime endTime;
  @override
  final num maxDrivers;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$ShiftPool([void Function(ShiftPoolBuilder)? updates]) =>
      (ShiftPoolBuilder()..update(updates))._build();

  _$ShiftPool._({
    required this.id,
    this.batchId,
    this.title,
    this.titleAr,
    this.zoneId,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.maxDrivers,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  ShiftPool rebuild(void Function(ShiftPoolBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShiftPoolBuilder toBuilder() => ShiftPoolBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShiftPool &&
        id == other.id &&
        batchId == other.batchId &&
        title == other.title &&
        titleAr == other.titleAr &&
        zoneId == other.zoneId &&
        shiftDate == other.shiftDate &&
        startTime == other.startTime &&
        endTime == other.endTime &&
        maxDrivers == other.maxDrivers &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, batchId.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, titleAr.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jc(_$hash, shiftDate.hashCode);
    _$hash = $jc(_$hash, startTime.hashCode);
    _$hash = $jc(_$hash, endTime.hashCode);
    _$hash = $jc(_$hash, maxDrivers.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ShiftPool')
          ..add('id', id)
          ..add('batchId', batchId)
          ..add('title', title)
          ..add('titleAr', titleAr)
          ..add('zoneId', zoneId)
          ..add('shiftDate', shiftDate)
          ..add('startTime', startTime)
          ..add('endTime', endTime)
          ..add('maxDrivers', maxDrivers)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class ShiftPoolBuilder implements Builder<ShiftPool, ShiftPoolBuilder> {
  _$ShiftPool? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _batchId;
  String? get batchId => _$this._batchId;
  set batchId(String? batchId) => _$this._batchId = batchId;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _titleAr;
  String? get titleAr => _$this._titleAr;
  set titleAr(String? titleAr) => _$this._titleAr = titleAr;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  DateTime? _shiftDate;
  DateTime? get shiftDate => _$this._shiftDate;
  set shiftDate(DateTime? shiftDate) => _$this._shiftDate = shiftDate;

  DateTime? _startTime;
  DateTime? get startTime => _$this._startTime;
  set startTime(DateTime? startTime) => _$this._startTime = startTime;

  DateTime? _endTime;
  DateTime? get endTime => _$this._endTime;
  set endTime(DateTime? endTime) => _$this._endTime = endTime;

  num? _maxDrivers;
  num? get maxDrivers => _$this._maxDrivers;
  set maxDrivers(num? maxDrivers) => _$this._maxDrivers = maxDrivers;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ShiftPoolBuilder() {
    ShiftPool._defaults(this);
  }

  ShiftPoolBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _batchId = $v.batchId;
      _title = $v.title;
      _titleAr = $v.titleAr;
      _zoneId = $v.zoneId;
      _shiftDate = $v.shiftDate;
      _startTime = $v.startTime;
      _endTime = $v.endTime;
      _maxDrivers = $v.maxDrivers;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ShiftPool other) {
    _$v = other as _$ShiftPool;
  }

  @override
  void update(void Function(ShiftPoolBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ShiftPool build() => _build();

  _$ShiftPool _build() {
    final _$result =
        _$v ??
        _$ShiftPool._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'ShiftPool', 'id'),
          batchId: batchId,
          title: title,
          titleAr: titleAr,
          zoneId: zoneId,
          shiftDate: BuiltValueNullFieldError.checkNotNull(
            shiftDate,
            r'ShiftPool',
            'shiftDate',
          ),
          startTime: BuiltValueNullFieldError.checkNotNull(
            startTime,
            r'ShiftPool',
            'startTime',
          ),
          endTime: BuiltValueNullFieldError.checkNotNull(
            endTime,
            r'ShiftPool',
            'endTime',
          ),
          maxDrivers: BuiltValueNullFieldError.checkNotNull(
            maxDrivers,
            r'ShiftPool',
            'maxDrivers',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'ShiftPool',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'ShiftPool',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
