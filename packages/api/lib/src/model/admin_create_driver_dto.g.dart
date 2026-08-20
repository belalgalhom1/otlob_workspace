// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_create_driver_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AdminCreateDriverDtoVehicleTypeEnum
_$adminCreateDriverDtoVehicleTypeEnum_BICYCLE =
    const AdminCreateDriverDtoVehicleTypeEnum._('BICYCLE');
const AdminCreateDriverDtoVehicleTypeEnum
_$adminCreateDriverDtoVehicleTypeEnum_MOTORCYCLE =
    const AdminCreateDriverDtoVehicleTypeEnum._('MOTORCYCLE');
const AdminCreateDriverDtoVehicleTypeEnum
_$adminCreateDriverDtoVehicleTypeEnum_CAR =
    const AdminCreateDriverDtoVehicleTypeEnum._('CAR');
const AdminCreateDriverDtoVehicleTypeEnum
_$adminCreateDriverDtoVehicleTypeEnum_VAN =
    const AdminCreateDriverDtoVehicleTypeEnum._('VAN');
const AdminCreateDriverDtoVehicleTypeEnum
_$adminCreateDriverDtoVehicleTypeEnum_TRUCK =
    const AdminCreateDriverDtoVehicleTypeEnum._('TRUCK');
const AdminCreateDriverDtoVehicleTypeEnum
_$adminCreateDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE =
    const AdminCreateDriverDtoVehicleTypeEnum._('MOTOR_TRICYCLE');

AdminCreateDriverDtoVehicleTypeEnum
_$adminCreateDriverDtoVehicleTypeEnumValueOf(String name) {
  switch (name) {
    case 'BICYCLE':
      return _$adminCreateDriverDtoVehicleTypeEnum_BICYCLE;
    case 'MOTORCYCLE':
      return _$adminCreateDriverDtoVehicleTypeEnum_MOTORCYCLE;
    case 'CAR':
      return _$adminCreateDriverDtoVehicleTypeEnum_CAR;
    case 'VAN':
      return _$adminCreateDriverDtoVehicleTypeEnum_VAN;
    case 'TRUCK':
      return _$adminCreateDriverDtoVehicleTypeEnum_TRUCK;
    case 'MOTOR_TRICYCLE':
      return _$adminCreateDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AdminCreateDriverDtoVehicleTypeEnum>
_$adminCreateDriverDtoVehicleTypeEnumValues =
    BuiltSet<AdminCreateDriverDtoVehicleTypeEnum>(
      const <AdminCreateDriverDtoVehicleTypeEnum>[
        _$adminCreateDriverDtoVehicleTypeEnum_BICYCLE,
        _$adminCreateDriverDtoVehicleTypeEnum_MOTORCYCLE,
        _$adminCreateDriverDtoVehicleTypeEnum_CAR,
        _$adminCreateDriverDtoVehicleTypeEnum_VAN,
        _$adminCreateDriverDtoVehicleTypeEnum_TRUCK,
        _$adminCreateDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE,
      ],
    );

const AdminCreateDriverDtoStatusEnum _$adminCreateDriverDtoStatusEnum_OFFLINE =
    const AdminCreateDriverDtoStatusEnum._('OFFLINE');
const AdminCreateDriverDtoStatusEnum _$adminCreateDriverDtoStatusEnum_ONLINE =
    const AdminCreateDriverDtoStatusEnum._('ONLINE');
const AdminCreateDriverDtoStatusEnum _$adminCreateDriverDtoStatusEnum_BUSY =
    const AdminCreateDriverDtoStatusEnum._('BUSY');
const AdminCreateDriverDtoStatusEnum
_$adminCreateDriverDtoStatusEnum_ON_DELIVERY =
    const AdminCreateDriverDtoStatusEnum._('ON_DELIVERY');
const AdminCreateDriverDtoStatusEnum _$adminCreateDriverDtoStatusEnum_ON_BREAK =
    const AdminCreateDriverDtoStatusEnum._('ON_BREAK');
const AdminCreateDriverDtoStatusEnum
_$adminCreateDriverDtoStatusEnum_SUSPENDED =
    const AdminCreateDriverDtoStatusEnum._('SUSPENDED');

AdminCreateDriverDtoStatusEnum _$adminCreateDriverDtoStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'OFFLINE':
      return _$adminCreateDriverDtoStatusEnum_OFFLINE;
    case 'ONLINE':
      return _$adminCreateDriverDtoStatusEnum_ONLINE;
    case 'BUSY':
      return _$adminCreateDriverDtoStatusEnum_BUSY;
    case 'ON_DELIVERY':
      return _$adminCreateDriverDtoStatusEnum_ON_DELIVERY;
    case 'ON_BREAK':
      return _$adminCreateDriverDtoStatusEnum_ON_BREAK;
    case 'SUSPENDED':
      return _$adminCreateDriverDtoStatusEnum_SUSPENDED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AdminCreateDriverDtoStatusEnum>
_$adminCreateDriverDtoStatusEnumValues =
    BuiltSet<AdminCreateDriverDtoStatusEnum>(
      const <AdminCreateDriverDtoStatusEnum>[
        _$adminCreateDriverDtoStatusEnum_OFFLINE,
        _$adminCreateDriverDtoStatusEnum_ONLINE,
        _$adminCreateDriverDtoStatusEnum_BUSY,
        _$adminCreateDriverDtoStatusEnum_ON_DELIVERY,
        _$adminCreateDriverDtoStatusEnum_ON_BREAK,
        _$adminCreateDriverDtoStatusEnum_SUSPENDED,
      ],
    );

Serializer<AdminCreateDriverDtoVehicleTypeEnum>
_$adminCreateDriverDtoVehicleTypeEnumSerializer =
    _$AdminCreateDriverDtoVehicleTypeEnumSerializer();
Serializer<AdminCreateDriverDtoStatusEnum>
_$adminCreateDriverDtoStatusEnumSerializer =
    _$AdminCreateDriverDtoStatusEnumSerializer();

class _$AdminCreateDriverDtoVehicleTypeEnumSerializer
    implements PrimitiveSerializer<AdminCreateDriverDtoVehicleTypeEnum> {
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
    AdminCreateDriverDtoVehicleTypeEnum,
  ];
  @override
  final String wireName = 'AdminCreateDriverDtoVehicleTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    AdminCreateDriverDtoVehicleTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  AdminCreateDriverDtoVehicleTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AdminCreateDriverDtoVehicleTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$AdminCreateDriverDtoStatusEnumSerializer
    implements PrimitiveSerializer<AdminCreateDriverDtoStatusEnum> {
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
  final Iterable<Type> types = const <Type>[AdminCreateDriverDtoStatusEnum];
  @override
  final String wireName = 'AdminCreateDriverDtoStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    AdminCreateDriverDtoStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  AdminCreateDriverDtoStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AdminCreateDriverDtoStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$AdminCreateDriverDto extends AdminCreateDriverDto {
  @override
  final String email;
  @override
  final String? phone;
  @override
  final String password;
  @override
  final String name;
  @override
  final String? nationalId;
  @override
  final String? licenseNumber;
  @override
  final AdminCreateDriverDtoVehicleTypeEnum vehicleType;
  @override
  final String? vehiclePlate;
  @override
  final AdminCreateDriverDtoStatusEnum? status;
  @override
  final String? tier;
  @override
  final bool? isApproved;

  factory _$AdminCreateDriverDto([
    void Function(AdminCreateDriverDtoBuilder)? updates,
  ]) => (AdminCreateDriverDtoBuilder()..update(updates))._build();

  _$AdminCreateDriverDto._({
    required this.email,
    this.phone,
    required this.password,
    required this.name,
    this.nationalId,
    this.licenseNumber,
    required this.vehicleType,
    this.vehiclePlate,
    this.status,
    this.tier,
    this.isApproved,
  }) : super._();
  @override
  AdminCreateDriverDto rebuild(
    void Function(AdminCreateDriverDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AdminCreateDriverDtoBuilder toBuilder() =>
      AdminCreateDriverDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminCreateDriverDto &&
        email == other.email &&
        phone == other.phone &&
        password == other.password &&
        name == other.name &&
        nationalId == other.nationalId &&
        licenseNumber == other.licenseNumber &&
        vehicleType == other.vehicleType &&
        vehiclePlate == other.vehiclePlate &&
        status == other.status &&
        tier == other.tier &&
        isApproved == other.isApproved;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nationalId.hashCode);
    _$hash = $jc(_$hash, licenseNumber.hashCode);
    _$hash = $jc(_$hash, vehicleType.hashCode);
    _$hash = $jc(_$hash, vehiclePlate.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, tier.hashCode);
    _$hash = $jc(_$hash, isApproved.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminCreateDriverDto')
          ..add('email', email)
          ..add('phone', phone)
          ..add('password', password)
          ..add('name', name)
          ..add('nationalId', nationalId)
          ..add('licenseNumber', licenseNumber)
          ..add('vehicleType', vehicleType)
          ..add('vehiclePlate', vehiclePlate)
          ..add('status', status)
          ..add('tier', tier)
          ..add('isApproved', isApproved))
        .toString();
  }
}

class AdminCreateDriverDtoBuilder
    implements Builder<AdminCreateDriverDto, AdminCreateDriverDtoBuilder> {
  _$AdminCreateDriverDto? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

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

  AdminCreateDriverDtoVehicleTypeEnum? _vehicleType;
  AdminCreateDriverDtoVehicleTypeEnum? get vehicleType => _$this._vehicleType;
  set vehicleType(AdminCreateDriverDtoVehicleTypeEnum? vehicleType) =>
      _$this._vehicleType = vehicleType;

  String? _vehiclePlate;
  String? get vehiclePlate => _$this._vehiclePlate;
  set vehiclePlate(String? vehiclePlate) => _$this._vehiclePlate = vehiclePlate;

  AdminCreateDriverDtoStatusEnum? _status;
  AdminCreateDriverDtoStatusEnum? get status => _$this._status;
  set status(AdminCreateDriverDtoStatusEnum? status) => _$this._status = status;

  String? _tier;
  String? get tier => _$this._tier;
  set tier(String? tier) => _$this._tier = tier;

  bool? _isApproved;
  bool? get isApproved => _$this._isApproved;
  set isApproved(bool? isApproved) => _$this._isApproved = isApproved;

  AdminCreateDriverDtoBuilder() {
    AdminCreateDriverDto._defaults(this);
  }

  AdminCreateDriverDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _phone = $v.phone;
      _password = $v.password;
      _name = $v.name;
      _nationalId = $v.nationalId;
      _licenseNumber = $v.licenseNumber;
      _vehicleType = $v.vehicleType;
      _vehiclePlate = $v.vehiclePlate;
      _status = $v.status;
      _tier = $v.tier;
      _isApproved = $v.isApproved;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminCreateDriverDto other) {
    _$v = other as _$AdminCreateDriverDto;
  }

  @override
  void update(void Function(AdminCreateDriverDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminCreateDriverDto build() => _build();

  _$AdminCreateDriverDto _build() {
    final _$result =
        _$v ??
        _$AdminCreateDriverDto._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'AdminCreateDriverDto',
            'email',
          ),
          phone: phone,
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'AdminCreateDriverDto',
            'password',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'AdminCreateDriverDto',
            'name',
          ),
          nationalId: nationalId,
          licenseNumber: licenseNumber,
          vehicleType: BuiltValueNullFieldError.checkNotNull(
            vehicleType,
            r'AdminCreateDriverDto',
            'vehicleType',
          ),
          vehiclePlate: vehiclePlate,
          status: status,
          tier: tier,
          isApproved: isApproved,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
