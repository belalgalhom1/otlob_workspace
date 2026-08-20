// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_order_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PlaceOrderDtoPaymentMethodEnum
_$placeOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY =
    const PlaceOrderDtoPaymentMethodEnum._('CASH_ON_DELIVERY');
const PlaceOrderDtoPaymentMethodEnum
_$placeOrderDtoPaymentMethodEnum_MOBILE_WALLET =
    const PlaceOrderDtoPaymentMethodEnum._('MOBILE_WALLET');

PlaceOrderDtoPaymentMethodEnum _$placeOrderDtoPaymentMethodEnumValueOf(
  String name,
) {
  switch (name) {
    case 'CASH_ON_DELIVERY':
      return _$placeOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY;
    case 'MOBILE_WALLET':
      return _$placeOrderDtoPaymentMethodEnum_MOBILE_WALLET;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PlaceOrderDtoPaymentMethodEnum>
_$placeOrderDtoPaymentMethodEnumValues =
    BuiltSet<PlaceOrderDtoPaymentMethodEnum>(
      const <PlaceOrderDtoPaymentMethodEnum>[
        _$placeOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY,
        _$placeOrderDtoPaymentMethodEnum_MOBILE_WALLET,
      ],
    );

Serializer<PlaceOrderDtoPaymentMethodEnum>
_$placeOrderDtoPaymentMethodEnumSerializer =
    _$PlaceOrderDtoPaymentMethodEnumSerializer();

class _$PlaceOrderDtoPaymentMethodEnumSerializer
    implements PrimitiveSerializer<PlaceOrderDtoPaymentMethodEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CASH_ON_DELIVERY': 'CASH_ON_DELIVERY',
    'MOBILE_WALLET': 'MOBILE_WALLET',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CASH_ON_DELIVERY': 'CASH_ON_DELIVERY',
    'MOBILE_WALLET': 'MOBILE_WALLET',
  };

  @override
  final Iterable<Type> types = const <Type>[PlaceOrderDtoPaymentMethodEnum];
  @override
  final String wireName = 'PlaceOrderDtoPaymentMethodEnum';

  @override
  Object serialize(
    Serializers serializers,
    PlaceOrderDtoPaymentMethodEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PlaceOrderDtoPaymentMethodEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PlaceOrderDtoPaymentMethodEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PlaceOrderDto extends PlaceOrderDto {
  @override
  final String vendorId;
  @override
  final PlaceOrderDtoPaymentMethodEnum paymentMethod;
  @override
  final String deliveryAddress;
  @override
  final BuiltList<num> deliveryLocation;
  @override
  final String? specialRequest;
  @override
  final num? coinsToUse;

  factory _$PlaceOrderDto([void Function(PlaceOrderDtoBuilder)? updates]) =>
      (PlaceOrderDtoBuilder()..update(updates))._build();

  _$PlaceOrderDto._({
    required this.vendorId,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.deliveryLocation,
    this.specialRequest,
    this.coinsToUse,
  }) : super._();
  @override
  PlaceOrderDto rebuild(void Function(PlaceOrderDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlaceOrderDtoBuilder toBuilder() => PlaceOrderDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlaceOrderDto &&
        vendorId == other.vendorId &&
        paymentMethod == other.paymentMethod &&
        deliveryAddress == other.deliveryAddress &&
        deliveryLocation == other.deliveryLocation &&
        specialRequest == other.specialRequest &&
        coinsToUse == other.coinsToUse;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, paymentMethod.hashCode);
    _$hash = $jc(_$hash, deliveryAddress.hashCode);
    _$hash = $jc(_$hash, deliveryLocation.hashCode);
    _$hash = $jc(_$hash, specialRequest.hashCode);
    _$hash = $jc(_$hash, coinsToUse.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlaceOrderDto')
          ..add('vendorId', vendorId)
          ..add('paymentMethod', paymentMethod)
          ..add('deliveryAddress', deliveryAddress)
          ..add('deliveryLocation', deliveryLocation)
          ..add('specialRequest', specialRequest)
          ..add('coinsToUse', coinsToUse))
        .toString();
  }
}

class PlaceOrderDtoBuilder
    implements Builder<PlaceOrderDto, PlaceOrderDtoBuilder> {
  _$PlaceOrderDto? _$v;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  PlaceOrderDtoPaymentMethodEnum? _paymentMethod;
  PlaceOrderDtoPaymentMethodEnum? get paymentMethod => _$this._paymentMethod;
  set paymentMethod(PlaceOrderDtoPaymentMethodEnum? paymentMethod) =>
      _$this._paymentMethod = paymentMethod;

  String? _deliveryAddress;
  String? get deliveryAddress => _$this._deliveryAddress;
  set deliveryAddress(String? deliveryAddress) =>
      _$this._deliveryAddress = deliveryAddress;

  ListBuilder<num>? _deliveryLocation;
  ListBuilder<num> get deliveryLocation =>
      _$this._deliveryLocation ??= ListBuilder<num>();
  set deliveryLocation(ListBuilder<num>? deliveryLocation) =>
      _$this._deliveryLocation = deliveryLocation;

  String? _specialRequest;
  String? get specialRequest => _$this._specialRequest;
  set specialRequest(String? specialRequest) =>
      _$this._specialRequest = specialRequest;

  num? _coinsToUse;
  num? get coinsToUse => _$this._coinsToUse;
  set coinsToUse(num? coinsToUse) => _$this._coinsToUse = coinsToUse;

  PlaceOrderDtoBuilder() {
    PlaceOrderDto._defaults(this);
  }

  PlaceOrderDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _vendorId = $v.vendorId;
      _paymentMethod = $v.paymentMethod;
      _deliveryAddress = $v.deliveryAddress;
      _deliveryLocation = $v.deliveryLocation.toBuilder();
      _specialRequest = $v.specialRequest;
      _coinsToUse = $v.coinsToUse;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlaceOrderDto other) {
    _$v = other as _$PlaceOrderDto;
  }

  @override
  void update(void Function(PlaceOrderDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlaceOrderDto build() => _build();

  _$PlaceOrderDto _build() {
    _$PlaceOrderDto _$result;
    try {
      _$result =
          _$v ??
          _$PlaceOrderDto._(
            vendorId: BuiltValueNullFieldError.checkNotNull(
              vendorId,
              r'PlaceOrderDto',
              'vendorId',
            ),
            paymentMethod: BuiltValueNullFieldError.checkNotNull(
              paymentMethod,
              r'PlaceOrderDto',
              'paymentMethod',
            ),
            deliveryAddress: BuiltValueNullFieldError.checkNotNull(
              deliveryAddress,
              r'PlaceOrderDto',
              'deliveryAddress',
            ),
            deliveryLocation: deliveryLocation.build(),
            specialRequest: specialRequest,
            coinsToUse: coinsToUse,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'deliveryLocation';
        deliveryLocation.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PlaceOrderDto',
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
