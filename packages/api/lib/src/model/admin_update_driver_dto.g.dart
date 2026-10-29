// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_update_driver_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AdminUpdateDriverDtoVehicleTypeEnum
_$adminUpdateDriverDtoVehicleTypeEnum_BICYCLE =
    const AdminUpdateDriverDtoVehicleTypeEnum._('BICYCLE');
const AdminUpdateDriverDtoVehicleTypeEnum
_$adminUpdateDriverDtoVehicleTypeEnum_MOTORCYCLE =
    const AdminUpdateDriverDtoVehicleTypeEnum._('MOTORCYCLE');
const AdminUpdateDriverDtoVehicleTypeEnum
_$adminUpdateDriverDtoVehicleTypeEnum_CAR =
    const AdminUpdateDriverDtoVehicleTypeEnum._('CAR');
const AdminUpdateDriverDtoVehicleTypeEnum
_$adminUpdateDriverDtoVehicleTypeEnum_VAN =
    const AdminUpdateDriverDtoVehicleTypeEnum._('VAN');
const AdminUpdateDriverDtoVehicleTypeEnum
_$adminUpdateDriverDtoVehicleTypeEnum_TRUCK =
    const AdminUpdateDriverDtoVehicleTypeEnum._('TRUCK');
const AdminUpdateDriverDtoVehicleTypeEnum
_$adminUpdateDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE =
    const AdminUpdateDriverDtoVehicleTypeEnum._('MOTOR_TRICYCLE');

AdminUpdateDriverDtoVehicleTypeEnum
_$adminUpdateDriverDtoVehicleTypeEnumValueOf(String name) {
  switch (name) {
    case 'BICYCLE':
      return _$adminUpdateDriverDtoVehicleTypeEnum_BICYCLE;
    case 'MOTORCYCLE':
      return _$adminUpdateDriverDtoVehicleTypeEnum_MOTORCYCLE;
    case 'CAR':
      return _$adminUpdateDriverDtoVehicleTypeEnum_CAR;
    case 'VAN':
      return _$adminUpdateDriverDtoVehicleTypeEnum_VAN;
    case 'TRUCK':
      return _$adminUpdateDriverDtoVehicleTypeEnum_TRUCK;
    case 'MOTOR_TRICYCLE':
      return _$adminUpdateDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AdminUpdateDriverDtoVehicleTypeEnum>
_$adminUpdateDriverDtoVehicleTypeEnumValues =
    BuiltSet<AdminUpdateDriverDtoVehicleTypeEnum>(
      const <AdminUpdateDriverDtoVehicleTypeEnum>[
        _$adminUpdateDriverDtoVehicleTypeEnum_BICYCLE,
        _$adminUpdateDriverDtoVehicleTypeEnum_MOTORCYCLE,
        _$adminUpdateDriverDtoVehicleTypeEnum_CAR,
        _$adminUpdateDriverDtoVehicleTypeEnum_VAN,
        _$adminUpdateDriverDtoVehicleTypeEnum_TRUCK,
        _$adminUpdateDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE,
      ],
    );

const AdminUpdateDriverDtoStatusEnum _$adminUpdateDriverDtoStatusEnum_OFFLINE =
    const AdminUpdateDriverDtoStatusEnum._('OFFLINE');
const AdminUpdateDriverDtoStatusEnum _$adminUpdateDriverDtoStatusEnum_ONLINE =
    const AdminUpdateDriverDtoStatusEnum._('ONLINE');
const AdminUpdateDriverDtoStatusEnum _$adminUpdateDriverDtoStatusEnum_BUSY =
    const AdminUpdateDriverDtoStatusEnum._('BUSY');
const AdminUpdateDriverDtoStatusEnum
_$adminUpdateDriverDtoStatusEnum_ON_DELIVERY =
    const AdminUpdateDriverDtoStatusEnum._('ON_DELIVERY');
const AdminUpdateDriverDtoStatusEnum _$adminUpdateDriverDtoStatusEnum_ON_BREAK =
    const AdminUpdateDriverDtoStatusEnum._('ON_BREAK');
const AdminUpdateDriverDtoStatusEnum
_$adminUpdateDriverDtoStatusEnum_SUSPENDED =
    const AdminUpdateDriverDtoStatusEnum._('SUSPENDED');

AdminUpdateDriverDtoStatusEnum _$adminUpdateDriverDtoStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'OFFLINE':
      return _$adminUpdateDriverDtoStatusEnum_OFFLINE;
    case 'ONLINE':
      return _$adminUpdateDriverDtoStatusEnum_ONLINE;
    case 'BUSY':
      return _$adminUpdateDriverDtoStatusEnum_BUSY;
    case 'ON_DELIVERY':
      return _$adminUpdateDriverDtoStatusEnum_ON_DELIVERY;
    case 'ON_BREAK':
      return _$adminUpdateDriverDtoStatusEnum_ON_BREAK;
    case 'SUSPENDED':
      return _$adminUpdateDriverDtoStatusEnum_SUSPENDED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AdminUpdateDriverDtoStatusEnum>
_$adminUpdateDriverDtoStatusEnumValues =
    BuiltSet<AdminUpdateDriverDtoStatusEnum>(
      const <AdminUpdateDriverDtoStatusEnum>[
        _$adminUpdateDriverDtoStatusEnum_OFFLINE,
        _$adminUpdateDriverDtoStatusEnum_ONLINE,
        _$adminUpdateDriverDtoStatusEnum_BUSY,
        _$adminUpdateDriverDtoStatusEnum_ON_DELIVERY,
        _$adminUpdateDriverDtoStatusEnum_ON_BREAK,
        _$adminUpdateDriverDtoStatusEnum_SUSPENDED,
      ],
    );

Serializer<AdminUpdateDriverDtoVehicleTypeEnum>
_$adminUpdateDriverDtoVehicleTypeEnumSerializer =
    _$AdminUpdateDriverDtoVehicleTypeEnumSerializer();
Serializer<AdminUpdateDriverDtoStatusEnum>
_$adminUpdateDriverDtoStatusEnumSerializer =
    _$AdminUpdateDriverDtoStatusEnumSerializer();

class _$AdminUpdateDriverDtoVehicleTypeEnumSerializer
    implements PrimitiveSerializer<AdminUpdateDriverDtoVehicleTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'BICYCLE': 'BICYCLE',
    'MOTORCYCLE': 'MOTORCYCLE',
    'CAR': 'CAR',
    'VAN': 'VAN',
    'TRUCK': 'TRUCK',
    'MOTOR_TRICYCLE': 'MOTOR_TRICYCLE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'BICYCLE': 'BICYCLE',
    'MOTORCYCLE': 'MOTORCYCLE',
    'CAR': 'CAR',
    'VAN': 'VAN',
    'TRUCK': 'TRUCK',
    'MOTOR_TRICYCLE': 'MOTOR_TRICYCLE',
  };

  @override
  final Iterable<Type> types = const <Type>[
    AdminUpdateDriverDtoVehicleTypeEnum,
  ];
  @override
  final String wireName = 'AdminUpdateDriverDtoVehicleTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    AdminUpdateDriverDtoVehicleTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  AdminUpdateDriverDtoVehicleTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AdminUpdateDriverDtoVehicleTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$AdminUpdateDriverDtoStatusEnumSerializer
    implements PrimitiveSerializer<AdminUpdateDriverDtoStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OFFLINE': 'OFFLINE',
    'ONLINE': 'ONLINE',
    'BUSY': 'BUSY',
    'ON_DELIVERY': 'ON_DELIVERY',
    'ON_BREAK': 'ON_BREAK',
    'SUSPENDED': 'SUSPENDED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OFFLINE': 'OFFLINE',
    'ONLINE': 'ONLINE',
    'BUSY': 'BUSY',
    'ON_DELIVERY': 'ON_DELIVERY',
    'ON_BREAK': 'ON_BREAK',
    'SUSPENDED': 'SUSPENDED',
  };

  @override
  final Iterable<Type> types = const <Type>[AdminUpdateDriverDtoStatusEnum];
  @override
  final String wireName = 'AdminUpdateDriverDtoStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    AdminUpdateDriverDtoStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  AdminUpdateDriverDtoStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AdminUpdateDriverDtoStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$AdminUpdateDriverDto extends AdminUpdateDriverDto {
  @override
  final String? name;
  @override
  final String? nationalId;
  @override
  final String? licenseNumber;
  @override
  final AdminUpdateDriverDtoVehicleTypeEnum? vehicleType;
  @override
  final String? vehiclePlate;
  @override
  final AdminUpdateDriverDtoStatusEnum? status;
  @override
  final bool? isApproved;
  @override
  final JsonObject? driverManagerUserId;

  factory _$AdminUpdateDriverDto([
    void Function(AdminUpdateDriverDtoBuilder)? updates,
  ]) => (AdminUpdateDriverDtoBuilder()..update(updates))._build();

  _$AdminUpdateDriverDto._({
    this.name,
    this.nationalId,
    this.licenseNumber,
    this.vehicleType,
    this.vehiclePlate,
    this.status,
    this.isApproved,
    this.driverManagerUserId,
  }) : super._();
  @override
  AdminUpdateDriverDto rebuild(
    void Function(AdminUpdateDriverDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AdminUpdateDriverDtoBuilder toBuilder() =>
      AdminUpdateDriverDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminUpdateDriverDto &&
        name == other.name &&
        nationalId == other.nationalId &&
        licenseNumber == other.licenseNumber &&
        vehicleType == other.vehicleType &&
        vehiclePlate == other.vehiclePlate &&
        status == other.status &&
        isApproved == other.isApproved &&
        driverManagerUserId == other.driverManagerUserId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nationalId.hashCode);
    _$hash = $jc(_$hash, licenseNumber.hashCode);
    _$hash = $jc(_$hash, vehicleType.hashCode);
    _$hash = $jc(_$hash, vehiclePlate.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, isApproved.hashCode);
    _$hash = $jc(_$hash, driverManagerUserId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminUpdateDriverDto')
          ..add('name', name)
          ..add('nationalId', nationalId)
          ..add('licenseNumber', licenseNumber)
          ..add('vehicleType', vehicleType)
          ..add('vehiclePlate', vehiclePlate)
          ..add('status', status)
          ..add('isApproved', isApproved)
          ..add('driverManagerUserId', driverManagerUserId))
        .toString();
  }
}

class AdminUpdateDriverDtoBuilder
    implements Builder<AdminUpdateDriverDto, AdminUpdateDriverDtoBuilder> {
  _$AdminUpdateDriverDto? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nationalId;
  String? get nationalId => _$this._nationalId;
  set nationalId(String? nationalId) => _$this._nationalId = nationalId;

  String? _licenseNumber;
  String? get licenseNumber => _$this._licenseNumber;
  set licenseNumber(String? licenseNumber) =>
      _$this._licenseNumber = licenseNumber;

  AdminUpdateDriverDtoVehicleTypeEnum? _vehicleType;
  AdminUpdateDriverDtoVehicleTypeEnum? get vehicleType => _$this._vehicleType;
  set vehicleType(AdminUpdateDriverDtoVehicleTypeEnum? vehicleType) =>
      _$this._vehicleType = vehicleType;

  String? _vehiclePlate;
  String? get vehiclePlate => _$this._vehiclePlate;
  set vehiclePlate(String? vehiclePlate) => _$this._vehiclePlate = vehiclePlate;

  AdminUpdateDriverDtoStatusEnum? _status;
  AdminUpdateDriverDtoStatusEnum? get status => _$this._status;
  set status(AdminUpdateDriverDtoStatusEnum? status) => _$this._status = status;

  bool? _isApproved;
  bool? get isApproved => _$this._isApproved;
  set isApproved(bool? isApproved) => _$this._isApproved = isApproved;

  JsonObject? _driverManagerUserId;
  JsonObject? get driverManagerUserId => _$this._driverManagerUserId;
  set driverManagerUserId(JsonObject? driverManagerUserId) =>
      _$this._driverManagerUserId = driverManagerUserId;

  AdminUpdateDriverDtoBuilder() {
    AdminUpdateDriverDto._defaults(this);
  }

  AdminUpdateDriverDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nationalId = $v.nationalId;
      _licenseNumber = $v.licenseNumber;
      _vehicleType = $v.vehicleType;
      _vehiclePlate = $v.vehiclePlate;
      _status = $v.status;
      _isApproved = $v.isApproved;
      _driverManagerUserId = $v.driverManagerUserId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminUpdateDriverDto other) {
    _$v = other as _$AdminUpdateDriverDto;
  }

  @override
  void update(void Function(AdminUpdateDriverDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminUpdateDriverDto build() => _build();

  _$AdminUpdateDriverDto _build() {
    final _$result =
        _$v ??
        _$AdminUpdateDriverDto._(
          name: name,
          nationalId: nationalId,
          licenseNumber: licenseNumber,
          vehicleType: vehicleType,
          vehiclePlate: vehiclePlate,
          status: status,
          isApproved: isApproved,
          driverManagerUserId: driverManagerUserId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
