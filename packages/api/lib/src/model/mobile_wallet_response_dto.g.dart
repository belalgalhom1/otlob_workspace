// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_wallet_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MobileWalletResponseDto extends MobileWalletResponseDto {
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
  @override
  final Driver? driver;
  @override
  final BuiltList<WalletTopUpRequest>? topUps;

  factory _$MobileWalletResponseDto([
    void Function(MobileWalletResponseDtoBuilder)? updates,
  ]) => (MobileWalletResponseDtoBuilder()..update(updates))._build();

  _$MobileWalletResponseDto._({
    required this.id,
    required this.number,
    required this.type,
    required this.isActive,
    required this.isPlatform,
    this.driverId,
    required this.createdAt,
    required this.updatedAt,
    this.driver,
    this.topUps,
  }) : super._();
  @override
  MobileWalletResponseDto rebuild(
    void Function(MobileWalletResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  MobileWalletResponseDtoBuilder toBuilder() =>
      MobileWalletResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MobileWalletResponseDto &&
        id == other.id &&
        number == other.number &&
        type == other.type &&
        isActive == other.isActive &&
        isPlatform == other.isPlatform &&
        driverId == other.driverId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        driver == other.driver &&
        topUps == other.topUps;
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
    _$hash = $jc(_$hash, driver.hashCode);
    _$hash = $jc(_$hash, topUps.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MobileWalletResponseDto')
          ..add('id', id)
          ..add('number', number)
          ..add('type', type)
          ..add('isActive', isActive)
          ..add('isPlatform', isPlatform)
          ..add('driverId', driverId)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('driver', driver)
          ..add('topUps', topUps))
        .toString();
  }
}

class MobileWalletResponseDtoBuilder
    implements
        Builder<MobileWalletResponseDto, MobileWalletResponseDtoBuilder> {
  _$MobileWalletResponseDto? _$v;

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

  DriverBuilder? _driver;
  DriverBuilder get driver => _$this._driver ??= DriverBuilder();
  set driver(DriverBuilder? driver) => _$this._driver = driver;

  ListBuilder<WalletTopUpRequest>? _topUps;
  ListBuilder<WalletTopUpRequest> get topUps =>
      _$this._topUps ??= ListBuilder<WalletTopUpRequest>();
  set topUps(ListBuilder<WalletTopUpRequest>? topUps) =>
      _$this._topUps = topUps;

  MobileWalletResponseDtoBuilder() {
    MobileWalletResponseDto._defaults(this);
  }

  MobileWalletResponseDtoBuilder get _$this {
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
      _driver = $v.driver?.toBuilder();
      _topUps = $v.topUps?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MobileWalletResponseDto other) {
    _$v = other as _$MobileWalletResponseDto;
  }

  @override
  void update(void Function(MobileWalletResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MobileWalletResponseDto build() => _build();

  _$MobileWalletResponseDto _build() {
    _$MobileWalletResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$MobileWalletResponseDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'MobileWalletResponseDto',
              'id',
            ),
            number: BuiltValueNullFieldError.checkNotNull(
              number,
              r'MobileWalletResponseDto',
              'number',
            ),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'MobileWalletResponseDto',
              'type',
            ),
            isActive: BuiltValueNullFieldError.checkNotNull(
              isActive,
              r'MobileWalletResponseDto',
              'isActive',
            ),
            isPlatform: BuiltValueNullFieldError.checkNotNull(
              isPlatform,
              r'MobileWalletResponseDto',
              'isPlatform',
            ),
            driverId: driverId,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'MobileWalletResponseDto',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'MobileWalletResponseDto',
              'updatedAt',
            ),
            driver: _driver?.build(),
            topUps: _topUps?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'driver';
        _driver?.build();
        _$failedField = 'topUps';
        _topUps?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'MobileWalletResponseDto',
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
