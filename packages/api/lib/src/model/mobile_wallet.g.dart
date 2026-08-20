// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_wallet.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MobileWallet extends MobileWallet {
  @override
  final String id;
  @override
  final String number;
  @override
  final WalletType type;
  @override
  final bool isActive;
  @override
  final bool isPlatform;
  @override
  final String? driverId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$MobileWallet([void Function(MobileWalletBuilder)? updates]) =>
      (MobileWalletBuilder()..update(updates))._build();

  _$MobileWallet._({
    required this.id,
    required this.number,
    required this.type,
    required this.isActive,
    required this.isPlatform,
    this.driverId,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  MobileWallet rebuild(void Function(MobileWalletBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MobileWalletBuilder toBuilder() => MobileWalletBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MobileWallet &&
        id == other.id &&
        number == other.number &&
        type == other.type &&
        isActive == other.isActive &&
        isPlatform == other.isPlatform &&
        driverId == other.driverId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, number.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, isPlatform.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MobileWallet')
          ..add('id', id)
          ..add('number', number)
          ..add('type', type)
          ..add('isActive', isActive)
          ..add('isPlatform', isPlatform)
          ..add('driverId', driverId)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class MobileWalletBuilder
    implements Builder<MobileWallet, MobileWalletBuilder> {
  _$MobileWallet? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _number;
  String? get number => _$this._number;
  set number(String? number) => _$this._number = number;

  WalletType? _type;
  WalletType? get type => _$this._type;
  set type(WalletType? type) => _$this._type = type;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  bool? _isPlatform;
  bool? get isPlatform => _$this._isPlatform;
  set isPlatform(bool? isPlatform) => _$this._isPlatform = isPlatform;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  MobileWalletBuilder() {
    MobileWallet._defaults(this);
  }

  MobileWalletBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _number = $v.number;
      _type = $v.type;
      _isActive = $v.isActive;
      _isPlatform = $v.isPlatform;
      _driverId = $v.driverId;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MobileWallet other) {
    _$v = other as _$MobileWallet;
  }

  @override
  void update(void Function(MobileWalletBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MobileWallet build() => _build();

  _$MobileWallet _build() {
    final _$result =
        _$v ??
        _$MobileWallet._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'MobileWallet', 'id'),
          number: BuiltValueNullFieldError.checkNotNull(
            number,
            r'MobileWallet',
            'number',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'MobileWallet',
            'type',
          ),
          isActive: BuiltValueNullFieldError.checkNotNull(
            isActive,
            r'MobileWallet',
            'isActive',
          ),
          isPlatform: BuiltValueNullFieldError.checkNotNull(
            isPlatform,
            r'MobileWallet',
            'isPlatform',
          ),
          driverId: driverId,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'MobileWallet',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'MobileWallet',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
