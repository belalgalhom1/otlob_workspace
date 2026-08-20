// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_driver_profile_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateDriverProfileDtoVehicleTypeEnum
_$updateDriverProfileDtoVehicleTypeEnum_BICYCLE =
    const UpdateDriverProfileDtoVehicleTypeEnum._('BICYCLE');
const UpdateDriverProfileDtoVehicleTypeEnum
_$updateDriverProfileDtoVehicleTypeEnum_MOTORCYCLE =
    const UpdateDriverProfileDtoVehicleTypeEnum._('MOTORCYCLE');
const UpdateDriverProfileDtoVehicleTypeEnum
_$updateDriverProfileDtoVehicleTypeEnum_CAR =
    const UpdateDriverProfileDtoVehicleTypeEnum._('CAR');
const UpdateDriverProfileDtoVehicleTypeEnum
_$updateDriverProfileDtoVehicleTypeEnum_VAN =
    const UpdateDriverProfileDtoVehicleTypeEnum._('VAN');
const UpdateDriverProfileDtoVehicleTypeEnum
_$updateDriverProfileDtoVehicleTypeEnum_TRUCK =
    const UpdateDriverProfileDtoVehicleTypeEnum._('TRUCK');
const UpdateDriverProfileDtoVehicleTypeEnum
_$updateDriverProfileDtoVehicleTypeEnum_MOTOR_TRICYCLE =
    const UpdateDriverProfileDtoVehicleTypeEnum._('MOTOR_TRICYCLE');

UpdateDriverProfileDtoVehicleTypeEnum
_$updateDriverProfileDtoVehicleTypeEnumValueOf(String name) {
  switch (name) {
    case 'BICYCLE':
      return _$updateDriverProfileDtoVehicleTypeEnum_BICYCLE;
    case 'MOTORCYCLE':
      return _$updateDriverProfileDtoVehicleTypeEnum_MOTORCYCLE;
    case 'CAR':
      return _$updateDriverProfileDtoVehicleTypeEnum_CAR;
    case 'VAN':
      return _$updateDriverProfileDtoVehicleTypeEnum_VAN;
    case 'TRUCK':
      return _$updateDriverProfileDtoVehicleTypeEnum_TRUCK;
    case 'MOTOR_TRICYCLE':
      return _$updateDriverProfileDtoVehicleTypeEnum_MOTOR_TRICYCLE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateDriverProfileDtoVehicleTypeEnum>
_$updateDriverProfileDtoVehicleTypeEnumValues =
    BuiltSet<UpdateDriverProfileDtoVehicleTypeEnum>(
      const <UpdateDriverProfileDtoVehicleTypeEnum>[
        _$updateDriverProfileDtoVehicleTypeEnum_BICYCLE,
        _$updateDriverProfileDtoVehicleTypeEnum_MOTORCYCLE,
        _$updateDriverProfileDtoVehicleTypeEnum_CAR,
        _$updateDriverProfileDtoVehicleTypeEnum_VAN,
        _$updateDriverProfileDtoVehicleTypeEnum_TRUCK,
        _$updateDriverProfileDtoVehicleTypeEnum_MOTOR_TRICYCLE,
      ],
    );

Serializer<UpdateDriverProfileDtoVehicleTypeEnum>
_$updateDriverProfileDtoVehicleTypeEnumSerializer =
    _$UpdateDriverProfileDtoVehicleTypeEnumSerializer();

class _$UpdateDriverProfileDtoVehicleTypeEnumSerializer
    implements PrimitiveSerializer<UpdateDriverProfileDtoVehicleTypeEnum> {
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
    UpdateDriverProfileDtoVehicleTypeEnum,
  ];
  @override
  final String wireName = 'UpdateDriverProfileDtoVehicleTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateDriverProfileDtoVehicleTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateDriverProfileDtoVehicleTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateDriverProfileDtoVehicleTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateDriverProfileDto extends UpdateDriverProfileDto {
  @override
  final String? name;
  @override
  final String? nationalId;
  @override
  final String? licenseNumber;
  @override
  final UpdateDriverProfileDtoVehicleTypeEnum? vehicleType;
  @override
  final String? vehiclePlate;

  factory _$UpdateDriverProfileDto([
    void Function(UpdateDriverProfileDtoBuilder)? updates,
  ]) => (UpdateDriverProfileDtoBuilder()..update(updates))._build();

  _$UpdateDriverProfileDto._({
    this.name,
    this.nationalId,
    this.licenseNumber,
    this.vehicleType,
    this.vehiclePlate,
  }) : super._();
  @override
  UpdateDriverProfileDto rebuild(
    void Function(UpdateDriverProfileDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateDriverProfileDtoBuilder toBuilder() =>
      UpdateDriverProfileDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateDriverProfileDto &&
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
    return (newBuiltValueToStringHelper(r'UpdateDriverProfileDto')
          ..add('name', name)
          ..add('nationalId', nationalId)
          ..add('licenseNumber', licenseNumber)
          ..add('vehicleType', vehicleType)
          ..add('vehiclePlate', vehiclePlate))
        .toString();
  }
}

class UpdateDriverProfileDtoBuilder
    implements Builder<UpdateDriverProfileDto, UpdateDriverProfileDtoBuilder> {
  _$UpdateDriverProfileDto? _$v;

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

  UpdateDriverProfileDtoVehicleTypeEnum? _vehicleType;
  UpdateDriverProfileDtoVehicleTypeEnum? get vehicleType => _$this._vehicleType;
  set vehicleType(UpdateDriverProfileDtoVehicleTypeEnum? vehicleType) =>
      _$this._vehicleType = vehicleType;

  String? _vehiclePlate;
  String? get vehiclePlate => _$this._vehiclePlate;
  set vehiclePlate(String? vehiclePlate) => _$this._vehiclePlate = vehiclePlate;

  UpdateDriverProfileDtoBuilder() {
    UpdateDriverProfileDto._defaults(this);
  }

  UpdateDriverProfileDtoBuilder get _$this {
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
  void replace(UpdateDriverProfileDto other) {
    _$v = other as _$UpdateDriverProfileDto;
  }

  @override
  void update(void Function(UpdateDriverProfileDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateDriverProfileDto build() => _build();

  _$UpdateDriverProfileDto _build() {
    final _$result =
        _$v ??
        _$UpdateDriverProfileDto._(
          name: name,
          nationalId: nationalId,
          licenseNumber: licenseNumber,
          vehicleType: vehicleType,
          vehiclePlate: vehiclePlate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
