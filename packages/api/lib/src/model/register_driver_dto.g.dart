// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_driver_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RegisterDriverDtoVehicleTypeEnum
_$registerDriverDtoVehicleTypeEnum_BICYCLE =
    const RegisterDriverDtoVehicleTypeEnum._('BICYCLE');
const RegisterDriverDtoVehicleTypeEnum
_$registerDriverDtoVehicleTypeEnum_MOTORCYCLE =
    const RegisterDriverDtoVehicleTypeEnum._('MOTORCYCLE');
const RegisterDriverDtoVehicleTypeEnum _$registerDriverDtoVehicleTypeEnum_CAR =
    const RegisterDriverDtoVehicleTypeEnum._('CAR');
const RegisterDriverDtoVehicleTypeEnum _$registerDriverDtoVehicleTypeEnum_VAN =
    const RegisterDriverDtoVehicleTypeEnum._('VAN');
const RegisterDriverDtoVehicleTypeEnum
_$registerDriverDtoVehicleTypeEnum_TRUCK =
    const RegisterDriverDtoVehicleTypeEnum._('TRUCK');
const RegisterDriverDtoVehicleTypeEnum
_$registerDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE =
    const RegisterDriverDtoVehicleTypeEnum._('MOTOR_TRICYCLE');

RegisterDriverDtoVehicleTypeEnum _$registerDriverDtoVehicleTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'BICYCLE':
      return _$registerDriverDtoVehicleTypeEnum_BICYCLE;
    case 'MOTORCYCLE':
      return _$registerDriverDtoVehicleTypeEnum_MOTORCYCLE;
    case 'CAR':
      return _$registerDriverDtoVehicleTypeEnum_CAR;
    case 'VAN':
      return _$registerDriverDtoVehicleTypeEnum_VAN;
    case 'TRUCK':
      return _$registerDriverDtoVehicleTypeEnum_TRUCK;
    case 'MOTOR_TRICYCLE':
      return _$registerDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RegisterDriverDtoVehicleTypeEnum>
_$registerDriverDtoVehicleTypeEnumValues =
    BuiltSet<RegisterDriverDtoVehicleTypeEnum>(
      const <RegisterDriverDtoVehicleTypeEnum>[
        _$registerDriverDtoVehicleTypeEnum_BICYCLE,
        _$registerDriverDtoVehicleTypeEnum_MOTORCYCLE,
        _$registerDriverDtoVehicleTypeEnum_CAR,
        _$registerDriverDtoVehicleTypeEnum_VAN,
        _$registerDriverDtoVehicleTypeEnum_TRUCK,
        _$registerDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE,
      ],
    );

Serializer<RegisterDriverDtoVehicleTypeEnum>
_$registerDriverDtoVehicleTypeEnumSerializer =
    _$RegisterDriverDtoVehicleTypeEnumSerializer();

class _$RegisterDriverDtoVehicleTypeEnumSerializer
    implements PrimitiveSerializer<RegisterDriverDtoVehicleTypeEnum> {
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
  final Iterable<Type> types = const <Type>[RegisterDriverDtoVehicleTypeEnum];
  @override
  final String wireName = 'RegisterDriverDtoVehicleTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    RegisterDriverDtoVehicleTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RegisterDriverDtoVehicleTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RegisterDriverDtoVehicleTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RegisterDriverDto extends RegisterDriverDto {
  @override
  final String name;
  @override
  final String? nationalId;
  @override
  final String? licenseNumber;
  @override
  final RegisterDriverDtoVehicleTypeEnum vehicleType;
  @override
  final String? vehiclePlate;

  factory _$RegisterDriverDto([
    void Function(RegisterDriverDtoBuilder)? updates,
  ]) => (RegisterDriverDtoBuilder()..update(updates))._build();

  _$RegisterDriverDto._({
    required this.name,
    this.nationalId,
    this.licenseNumber,
    required this.vehicleType,
    this.vehiclePlate,
  }) : super._();
  @override
  RegisterDriverDto rebuild(void Function(RegisterDriverDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterDriverDtoBuilder toBuilder() =>
      RegisterDriverDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterDriverDto &&
        name == other.name &&
        nationalId == other.nationalId &&
        licenseNumber == other.licenseNumber &&
        vehicleType == other.vehicleType &&
        vehiclePlate == other.vehiclePlate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nationalId.hashCode);
    _$hash = $jc(_$hash, licenseNumber.hashCode);
    _$hash = $jc(_$hash, vehicleType.hashCode);
    _$hash = $jc(_$hash, vehiclePlate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterDriverDto')
          ..add('name', name)
          ..add('nationalId', nationalId)
          ..add('licenseNumber', licenseNumber)
          ..add('vehicleType', vehicleType)
          ..add('vehiclePlate', vehiclePlate))
        .toString();
  }
}

class RegisterDriverDtoBuilder
    implements Builder<RegisterDriverDto, RegisterDriverDtoBuilder> {
  _$RegisterDriverDto? _$v;

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

  RegisterDriverDtoVehicleTypeEnum? _vehicleType;
  RegisterDriverDtoVehicleTypeEnum? get vehicleType => _$this._vehicleType;
  set vehicleType(RegisterDriverDtoVehicleTypeEnum? vehicleType) =>
      _$this._vehicleType = vehicleType;

  String? _vehiclePlate;
  String? get vehiclePlate => _$this._vehiclePlate;
  set vehiclePlate(String? vehiclePlate) => _$this._vehiclePlate = vehiclePlate;

  RegisterDriverDtoBuilder() {
    RegisterDriverDto._defaults(this);
  }

  RegisterDriverDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nationalId = $v.nationalId;
      _licenseNumber = $v.licenseNumber;
      _vehicleType = $v.vehicleType;
      _vehiclePlate = $v.vehiclePlate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterDriverDto other) {
    _$v = other as _$RegisterDriverDto;
  }

  @override
  void update(void Function(RegisterDriverDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterDriverDto build() => _build();

  _$RegisterDriverDto _build() {
    final _$result =
        _$v ??
        _$RegisterDriverDto._(
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'RegisterDriverDto',
            'name',
          ),
          nationalId: nationalId,
          licenseNumber: licenseNumber,
          vehicleType: BuiltValueNullFieldError.checkNotNull(
            vehicleType,
            r'RegisterDriverDto',
            'vehicleType',
          ),
          vehiclePlate: vehiclePlate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
