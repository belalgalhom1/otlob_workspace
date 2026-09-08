// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zone.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Zone extends Zone {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final bool isActive;
  @override
  final num? baseDeliveryFeeOverride;
  @override
  final num? minOrderAmountOverride;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$Zone([void Function(ZoneBuilder)? updates]) =>
      (ZoneBuilder()..update(updates))._build();

  _$Zone._({
    required this.id,
    required this.name,
    this.nameAr,
    required this.isActive,
    this.baseDeliveryFeeOverride,
    this.minOrderAmountOverride,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  Zone rebuild(void Function(ZoneBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ZoneBuilder toBuilder() => ZoneBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Zone &&
        id == other.id &&
        name == other.name &&
        nameAr == other.nameAr &&
        isActive == other.isActive &&
        baseDeliveryFeeOverride == other.baseDeliveryFeeOverride &&
        minOrderAmountOverride == other.minOrderAmountOverride &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, baseDeliveryFeeOverride.hashCode);
    _$hash = $jc(_$hash, minOrderAmountOverride.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Zone')
          ..add('id', id)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('isActive', isActive)
          ..add('baseDeliveryFeeOverride', baseDeliveryFeeOverride)
          ..add('minOrderAmountOverride', minOrderAmountOverride)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class ZoneBuilder implements Builder<Zone, ZoneBuilder> {
  _$Zone? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  num? _baseDeliveryFeeOverride;
  num? get baseDeliveryFeeOverride => _$this._baseDeliveryFeeOverride;
  set baseDeliveryFeeOverride(num? baseDeliveryFeeOverride) =>
      _$this._baseDeliveryFeeOverride = baseDeliveryFeeOverride;

  num? _minOrderAmountOverride;
  num? get minOrderAmountOverride => _$this._minOrderAmountOverride;
  set minOrderAmountOverride(num? minOrderAmountOverride) =>
      _$this._minOrderAmountOverride = minOrderAmountOverride;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ZoneBuilder() {
    Zone._defaults(this);
  }

  ZoneBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _isActive = $v.isActive;
      _baseDeliveryFeeOverride = $v.baseDeliveryFeeOverride;
      _minOrderAmountOverride = $v.minOrderAmountOverride;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Zone other) {
    _$v = other as _$Zone;
  }

  @override
  void update(void Function(ZoneBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Zone build() => _build();

  _$Zone _build() {
    final _$result =
        _$v ??
        _$Zone._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Zone', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'Zone', 'name'),
          nameAr: nameAr,
          isActive: BuiltValueNullFieldError.checkNotNull(
            isActive,
            r'Zone',
            'isActive',
          ),
          baseDeliveryFeeOverride: baseDeliveryFeeOverride,
          minOrderAmountOverride: minOrderAmountOverride,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'Zone',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'Zone',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
