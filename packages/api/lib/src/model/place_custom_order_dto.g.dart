// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_custom_order_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PlaceCustomOrderDtoTypeEnum
_$placeCustomOrderDtoTypeEnum_CUSTOM_DELIVERY =
    const PlaceCustomOrderDtoTypeEnum._('CUSTOM_DELIVERY');
const PlaceCustomOrderDtoTypeEnum _$placeCustomOrderDtoTypeEnum_RIDE =
    const PlaceCustomOrderDtoTypeEnum._('RIDE');

PlaceCustomOrderDtoTypeEnum _$placeCustomOrderDtoTypeEnumValueOf(String name) {
  switch (name) {
    case 'CUSTOM_DELIVERY':
      return _$placeCustomOrderDtoTypeEnum_CUSTOM_DELIVERY;
    case 'RIDE':
      return _$placeCustomOrderDtoTypeEnum_RIDE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PlaceCustomOrderDtoTypeEnum>
_$placeCustomOrderDtoTypeEnumValues =
    BuiltSet<PlaceCustomOrderDtoTypeEnum>(const <PlaceCustomOrderDtoTypeEnum>[
      _$placeCustomOrderDtoTypeEnum_CUSTOM_DELIVERY,
      _$placeCustomOrderDtoTypeEnum_RIDE,
    ]);

const PlaceCustomOrderDtoPaymentMethodEnum
_$placeCustomOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY =
    const PlaceCustomOrderDtoPaymentMethodEnum._('CASH_ON_DELIVERY');
const PlaceCustomOrderDtoPaymentMethodEnum
_$placeCustomOrderDtoPaymentMethodEnum_MOBILE_WALLET =
    const PlaceCustomOrderDtoPaymentMethodEnum._('MOBILE_WALLET');

PlaceCustomOrderDtoPaymentMethodEnum
_$placeCustomOrderDtoPaymentMethodEnumValueOf(String name) {
  switch (name) {
    case 'CASH_ON_DELIVERY':
      return _$placeCustomOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY;
    case 'MOBILE_WALLET':
      return _$placeCustomOrderDtoPaymentMethodEnum_MOBILE_WALLET;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PlaceCustomOrderDtoPaymentMethodEnum>
_$placeCustomOrderDtoPaymentMethodEnumValues =
    BuiltSet<PlaceCustomOrderDtoPaymentMethodEnum>(
      const <PlaceCustomOrderDtoPaymentMethodEnum>[
        _$placeCustomOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY,
        _$placeCustomOrderDtoPaymentMethodEnum_MOBILE_WALLET,
      ],
    );

const PlaceCustomOrderDtoVehicleTypeEnum
_$placeCustomOrderDtoVehicleTypeEnum_BICYCLE =
    const PlaceCustomOrderDtoVehicleTypeEnum._('BICYCLE');
const PlaceCustomOrderDtoVehicleTypeEnum
_$placeCustomOrderDtoVehicleTypeEnum_MOTORCYCLE =
    const PlaceCustomOrderDtoVehicleTypeEnum._('MOTORCYCLE');
const PlaceCustomOrderDtoVehicleTypeEnum
_$placeCustomOrderDtoVehicleTypeEnum_CAR =
    const PlaceCustomOrderDtoVehicleTypeEnum._('CAR');
const PlaceCustomOrderDtoVehicleTypeEnum
_$placeCustomOrderDtoVehicleTypeEnum_VAN =
    const PlaceCustomOrderDtoVehicleTypeEnum._('VAN');
const PlaceCustomOrderDtoVehicleTypeEnum
_$placeCustomOrderDtoVehicleTypeEnum_TRUCK =
    const PlaceCustomOrderDtoVehicleTypeEnum._('TRUCK');
const PlaceCustomOrderDtoVehicleTypeEnum
_$placeCustomOrderDtoVehicleTypeEnum_MOTOR_TRICYCLE =
    const PlaceCustomOrderDtoVehicleTypeEnum._('MOTOR_TRICYCLE');

PlaceCustomOrderDtoVehicleTypeEnum _$placeCustomOrderDtoVehicleTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'BICYCLE':
      return _$placeCustomOrderDtoVehicleTypeEnum_BICYCLE;
    case 'MOTORCYCLE':
      return _$placeCustomOrderDtoVehicleTypeEnum_MOTORCYCLE;
    case 'CAR':
      return _$placeCustomOrderDtoVehicleTypeEnum_CAR;
    case 'VAN':
      return _$placeCustomOrderDtoVehicleTypeEnum_VAN;
    case 'TRUCK':
      return _$placeCustomOrderDtoVehicleTypeEnum_TRUCK;
    case 'MOTOR_TRICYCLE':
      return _$placeCustomOrderDtoVehicleTypeEnum_MOTOR_TRICYCLE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PlaceCustomOrderDtoVehicleTypeEnum>
_$placeCustomOrderDtoVehicleTypeEnumValues =
    BuiltSet<PlaceCustomOrderDtoVehicleTypeEnum>(
      const <PlaceCustomOrderDtoVehicleTypeEnum>[
        _$placeCustomOrderDtoVehicleTypeEnum_BICYCLE,
        _$placeCustomOrderDtoVehicleTypeEnum_MOTORCYCLE,
        _$placeCustomOrderDtoVehicleTypeEnum_CAR,
        _$placeCustomOrderDtoVehicleTypeEnum_VAN,
        _$placeCustomOrderDtoVehicleTypeEnum_TRUCK,
        _$placeCustomOrderDtoVehicleTypeEnum_MOTOR_TRICYCLE,
      ],
    );

Serializer<PlaceCustomOrderDtoTypeEnum>
_$placeCustomOrderDtoTypeEnumSerializer =
    _$PlaceCustomOrderDtoTypeEnumSerializer();
Serializer<PlaceCustomOrderDtoPaymentMethodEnum>
_$placeCustomOrderDtoPaymentMethodEnumSerializer =
    _$PlaceCustomOrderDtoPaymentMethodEnumSerializer();
Serializer<PlaceCustomOrderDtoVehicleTypeEnum>
_$placeCustomOrderDtoVehicleTypeEnumSerializer =
    _$PlaceCustomOrderDtoVehicleTypeEnumSerializer();

class _$PlaceCustomOrderDtoTypeEnumSerializer
    implements PrimitiveSerializer<PlaceCustomOrderDtoTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CUSTOM_DELIVERY': 'CUSTOM_DELIVERY',
    'RIDE': 'RIDE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CUSTOM_DELIVERY': 'CUSTOM_DELIVERY',
    'RIDE': 'RIDE',
  };

  @override
  final Iterable<Type> types = const <Type>[PlaceCustomOrderDtoTypeEnum];
  @override
  final String wireName = 'PlaceCustomOrderDtoTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PlaceCustomOrderDtoTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PlaceCustomOrderDtoTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PlaceCustomOrderDtoTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PlaceCustomOrderDtoPaymentMethodEnumSerializer
    implements PrimitiveSerializer<PlaceCustomOrderDtoPaymentMethodEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CASH_ON_DELIVERY': 'CASH_ON_DELIVERY',
    'MOBILE_WALLET': 'MOBILE_WALLET',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CASH_ON_DELIVERY': 'CASH_ON_DELIVERY',
    'MOBILE_WALLET': 'MOBILE_WALLET',
  };

  @override
  final Iterable<Type> types = const <Type>[
    PlaceCustomOrderDtoPaymentMethodEnum,
  ];
  @override
  final String wireName = 'PlaceCustomOrderDtoPaymentMethodEnum';

  @override
  Object serialize(
    Serializers serializers,
    PlaceCustomOrderDtoPaymentMethodEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PlaceCustomOrderDtoPaymentMethodEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PlaceCustomOrderDtoPaymentMethodEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PlaceCustomOrderDtoVehicleTypeEnumSerializer
    implements PrimitiveSerializer<PlaceCustomOrderDtoVehicleTypeEnum> {
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
  final Iterable<Type> types = const <Type>[PlaceCustomOrderDtoVehicleTypeEnum];
  @override
  final String wireName = 'PlaceCustomOrderDtoVehicleTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    PlaceCustomOrderDtoVehicleTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PlaceCustomOrderDtoVehicleTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PlaceCustomOrderDtoVehicleTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PlaceCustomOrderDto extends PlaceCustomOrderDto {
  @override
  final PlaceCustomOrderDtoTypeEnum type;
  @override
  final PlaceCustomOrderDtoPaymentMethodEnum paymentMethod;
  @override
  final String pickupAddress;
  @override
  final BuiltList<num> pickupLocation;
  @override
  final String deliveryAddress;
  @override
  final BuiltList<num> deliveryLocation;
  @override
  final PlaceCustomOrderDtoVehicleTypeEnum vehicleType;
  @override
  final String? itemDetails;
  @override
  final String? specialRequest;
  @override
  final num? coinsToUse;

  factory _$PlaceCustomOrderDto([
    void Function(PlaceCustomOrderDtoBuilder)? updates,
  ]) => (PlaceCustomOrderDtoBuilder()..update(updates))._build();

  _$PlaceCustomOrderDto._({
    required this.type,
    required this.paymentMethod,
    required this.pickupAddress,
    required this.pickupLocation,
    required this.deliveryAddress,
    required this.deliveryLocation,
    required this.vehicleType,
    this.itemDetails,
    this.specialRequest,
    this.coinsToUse,
  }) : super._();
  @override
  PlaceCustomOrderDto rebuild(
    void Function(PlaceCustomOrderDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PlaceCustomOrderDtoBuilder toBuilder() =>
      PlaceCustomOrderDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlaceCustomOrderDto &&
        type == other.type &&
        paymentMethod == other.paymentMethod &&
        pickupAddress == other.pickupAddress &&
        pickupLocation == other.pickupLocation &&
        deliveryAddress == other.deliveryAddress &&
        deliveryLocation == other.deliveryLocation &&
        vehicleType == other.vehicleType &&
        itemDetails == other.itemDetails &&
        specialRequest == other.specialRequest &&
        coinsToUse == other.coinsToUse;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, paymentMethod.hashCode);
    _$hash = $jc(_$hash, pickupAddress.hashCode);
    _$hash = $jc(_$hash, pickupLocation.hashCode);
    _$hash = $jc(_$hash, deliveryAddress.hashCode);
    _$hash = $jc(_$hash, deliveryLocation.hashCode);
    _$hash = $jc(_$hash, vehicleType.hashCode);
    _$hash = $jc(_$hash, itemDetails.hashCode);
    _$hash = $jc(_$hash, specialRequest.hashCode);
    _$hash = $jc(_$hash, coinsToUse.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlaceCustomOrderDto')
          ..add('type', type)
          ..add('paymentMethod', paymentMethod)
          ..add('pickupAddress', pickupAddress)
          ..add('pickupLocation', pickupLocation)
          ..add('deliveryAddress', deliveryAddress)
          ..add('deliveryLocation', deliveryLocation)
          ..add('vehicleType', vehicleType)
          ..add('itemDetails', itemDetails)
          ..add('specialRequest', specialRequest)
          ..add('coinsToUse', coinsToUse))
        .toString();
  }
}

class PlaceCustomOrderDtoBuilder
    implements Builder<PlaceCustomOrderDto, PlaceCustomOrderDtoBuilder> {
  _$PlaceCustomOrderDto? _$v;

  PlaceCustomOrderDtoTypeEnum? _type;
  PlaceCustomOrderDtoTypeEnum? get type => _$this._type;
  set type(PlaceCustomOrderDtoTypeEnum? type) => _$this._type = type;

  PlaceCustomOrderDtoPaymentMethodEnum? _paymentMethod;
  PlaceCustomOrderDtoPaymentMethodEnum? get paymentMethod =>
      _$this._paymentMethod;
  set paymentMethod(PlaceCustomOrderDtoPaymentMethodEnum? paymentMethod) =>
      _$this._paymentMethod = paymentMethod;

  String? _pickupAddress;
  String? get pickupAddress => _$this._pickupAddress;
  set pickupAddress(String? pickupAddress) =>
      _$this._pickupAddress = pickupAddress;

  ListBuilder<num>? _pickupLocation;
  ListBuilder<num> get pickupLocation =>
      _$this._pickupLocation ??= ListBuilder<num>();
  set pickupLocation(ListBuilder<num>? pickupLocation) =>
      _$this._pickupLocation = pickupLocation;

  String? _deliveryAddress;
  String? get deliveryAddress => _$this._deliveryAddress;
  set deliveryAddress(String? deliveryAddress) =>
      _$this._deliveryAddress = deliveryAddress;

  ListBuilder<num>? _deliveryLocation;
  ListBuilder<num> get deliveryLocation =>
      _$this._deliveryLocation ??= ListBuilder<num>();
  set deliveryLocation(ListBuilder<num>? deliveryLocation) =>
      _$this._deliveryLocation = deliveryLocation;

  PlaceCustomOrderDtoVehicleTypeEnum? _vehicleType;
  PlaceCustomOrderDtoVehicleTypeEnum? get vehicleType => _$this._vehicleType;
  set vehicleType(PlaceCustomOrderDtoVehicleTypeEnum? vehicleType) =>
      _$this._vehicleType = vehicleType;

  String? _itemDetails;
  String? get itemDetails => _$this._itemDetails;
  set itemDetails(String? itemDetails) => _$this._itemDetails = itemDetails;

  String? _specialRequest;
  String? get specialRequest => _$this._specialRequest;
  set specialRequest(String? specialRequest) =>
      _$this._specialRequest = specialRequest;

  num? _coinsToUse;
  num? get coinsToUse => _$this._coinsToUse;
  set coinsToUse(num? coinsToUse) => _$this._coinsToUse = coinsToUse;

  PlaceCustomOrderDtoBuilder() {
    PlaceCustomOrderDto._defaults(this);
  }

  PlaceCustomOrderDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _paymentMethod = $v.paymentMethod;
      _pickupAddress = $v.pickupAddress;
      _pickupLocation = $v.pickupLocation.toBuilder();
      _deliveryAddress = $v.deliveryAddress;
      _deliveryLocation = $v.deliveryLocation.toBuilder();
      _vehicleType = $v.vehicleType;
      _itemDetails = $v.itemDetails;
      _specialRequest = $v.specialRequest;
      _coinsToUse = $v.coinsToUse;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlaceCustomOrderDto other) {
    _$v = other as _$PlaceCustomOrderDto;
  }

  @override
  void update(void Function(PlaceCustomOrderDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlaceCustomOrderDto build() => _build();

  _$PlaceCustomOrderDto _build() {
    _$PlaceCustomOrderDto _$result;
    try {
      _$result =
          _$v ??
          _$PlaceCustomOrderDto._(
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'PlaceCustomOrderDto',
              'type',
            ),
            paymentMethod: BuiltValueNullFieldError.checkNotNull(
              paymentMethod,
              r'PlaceCustomOrderDto',
              'paymentMethod',
            ),
            pickupAddress: BuiltValueNullFieldError.checkNotNull(
              pickupAddress,
              r'PlaceCustomOrderDto',
              'pickupAddress',
            ),
            pickupLocation: pickupLocation.build(),
            deliveryAddress: BuiltValueNullFieldError.checkNotNull(
              deliveryAddress,
              r'PlaceCustomOrderDto',
              'deliveryAddress',
            ),
            deliveryLocation: deliveryLocation.build(),
            vehicleType: BuiltValueNullFieldError.checkNotNull(
              vehicleType,
              r'PlaceCustomOrderDto',
              'vehicleType',
            ),
            itemDetails: itemDetails,
            specialRequest: specialRequest,
            coinsToUse: coinsToUse,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'pickupLocation';
        pickupLocation.build();

        _$failedField = 'deliveryLocation';
        deliveryLocation.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PlaceCustomOrderDto',
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
