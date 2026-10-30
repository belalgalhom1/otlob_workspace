// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_multi_vendor_order_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PlaceMultiVendorOrderDtoPaymentMethodEnum
_$placeMultiVendorOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY =
    const PlaceMultiVendorOrderDtoPaymentMethodEnum._('CASH_ON_DELIVERY');
const PlaceMultiVendorOrderDtoPaymentMethodEnum
_$placeMultiVendorOrderDtoPaymentMethodEnum_MOBILE_WALLET =
    const PlaceMultiVendorOrderDtoPaymentMethodEnum._('MOBILE_WALLET');

PlaceMultiVendorOrderDtoPaymentMethodEnum
_$placeMultiVendorOrderDtoPaymentMethodEnumValueOf(String name) {
  switch (name) {
    case 'CASH_ON_DELIVERY':
      return _$placeMultiVendorOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY;
    case 'MOBILE_WALLET':
      return _$placeMultiVendorOrderDtoPaymentMethodEnum_MOBILE_WALLET;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PlaceMultiVendorOrderDtoPaymentMethodEnum>
_$placeMultiVendorOrderDtoPaymentMethodEnumValues =
    BuiltSet<PlaceMultiVendorOrderDtoPaymentMethodEnum>(
      const <PlaceMultiVendorOrderDtoPaymentMethodEnum>[
        _$placeMultiVendorOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY,
        _$placeMultiVendorOrderDtoPaymentMethodEnum_MOBILE_WALLET,
      ],
    );

Serializer<PlaceMultiVendorOrderDtoPaymentMethodEnum>
_$placeMultiVendorOrderDtoPaymentMethodEnumSerializer =
    _$PlaceMultiVendorOrderDtoPaymentMethodEnumSerializer();

class _$PlaceMultiVendorOrderDtoPaymentMethodEnumSerializer
    implements PrimitiveSerializer<PlaceMultiVendorOrderDtoPaymentMethodEnum> {
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
    PlaceMultiVendorOrderDtoPaymentMethodEnum,
  ];
  @override
  final String wireName = 'PlaceMultiVendorOrderDtoPaymentMethodEnum';

  @override
  Object serialize(
    Serializers serializers,
    PlaceMultiVendorOrderDtoPaymentMethodEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PlaceMultiVendorOrderDtoPaymentMethodEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PlaceMultiVendorOrderDtoPaymentMethodEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PlaceMultiVendorOrderDto extends PlaceMultiVendorOrderDto {
  @override
  final BuiltList<String> vendorIds;
  @override
  final PlaceMultiVendorOrderDtoPaymentMethodEnum paymentMethod;
  @override
  final String deliveryAddress;
  @override
  final BuiltList<String> deliveryLocation;
  @override
  final String? specialRequest;
  @override
  final num? coinsToUse;

  factory _$PlaceMultiVendorOrderDto([
    void Function(PlaceMultiVendorOrderDtoBuilder)? updates,
  ]) => (PlaceMultiVendorOrderDtoBuilder()..update(updates))._build();

  _$PlaceMultiVendorOrderDto._({
    required this.vendorIds,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.deliveryLocation,
    this.specialRequest,
    this.coinsToUse,
  }) : super._();
  @override
  PlaceMultiVendorOrderDto rebuild(
    void Function(PlaceMultiVendorOrderDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PlaceMultiVendorOrderDtoBuilder toBuilder() =>
      PlaceMultiVendorOrderDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlaceMultiVendorOrderDto &&
        vendorIds == other.vendorIds &&
        paymentMethod == other.paymentMethod &&
        deliveryAddress == other.deliveryAddress &&
        deliveryLocation == other.deliveryLocation &&
        specialRequest == other.specialRequest &&
        coinsToUse == other.coinsToUse;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, vendorIds.hashCode);
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
    return (newBuiltValueToStringHelper(r'PlaceMultiVendorOrderDto')
          ..add('vendorIds', vendorIds)
          ..add('paymentMethod', paymentMethod)
          ..add('deliveryAddress', deliveryAddress)
          ..add('deliveryLocation', deliveryLocation)
          ..add('specialRequest', specialRequest)
          ..add('coinsToUse', coinsToUse))
        .toString();
  }
}

class PlaceMultiVendorOrderDtoBuilder
    implements
        Builder<PlaceMultiVendorOrderDto, PlaceMultiVendorOrderDtoBuilder> {
  _$PlaceMultiVendorOrderDto? _$v;

  ListBuilder<String>? _vendorIds;
  ListBuilder<String> get vendorIds =>
      _$this._vendorIds ??= ListBuilder<String>();
  set vendorIds(ListBuilder<String>? vendorIds) =>
      _$this._vendorIds = vendorIds;

  PlaceMultiVendorOrderDtoPaymentMethodEnum? _paymentMethod;
  PlaceMultiVendorOrderDtoPaymentMethodEnum? get paymentMethod =>
      _$this._paymentMethod;
  set paymentMethod(PlaceMultiVendorOrderDtoPaymentMethodEnum? paymentMethod) =>
      _$this._paymentMethod = paymentMethod;

  String? _deliveryAddress;
  String? get deliveryAddress => _$this._deliveryAddress;
  set deliveryAddress(String? deliveryAddress) =>
      _$this._deliveryAddress = deliveryAddress;

  ListBuilder<String>? _deliveryLocation;
  ListBuilder<String> get deliveryLocation =>
      _$this._deliveryLocation ??= ListBuilder<String>();
  set deliveryLocation(ListBuilder<String>? deliveryLocation) =>
      _$this._deliveryLocation = deliveryLocation;

  String? _specialRequest;
  String? get specialRequest => _$this._specialRequest;
  set specialRequest(String? specialRequest) =>
      _$this._specialRequest = specialRequest;

  num? _coinsToUse;
  num? get coinsToUse => _$this._coinsToUse;
  set coinsToUse(num? coinsToUse) => _$this._coinsToUse = coinsToUse;

  PlaceMultiVendorOrderDtoBuilder() {
    PlaceMultiVendorOrderDto._defaults(this);
  }

  PlaceMultiVendorOrderDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _vendorIds = $v.vendorIds.toBuilder();
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
  void replace(PlaceMultiVendorOrderDto other) {
    _$v = other as _$PlaceMultiVendorOrderDto;
  }

  @override
  void update(void Function(PlaceMultiVendorOrderDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlaceMultiVendorOrderDto build() => _build();

  _$PlaceMultiVendorOrderDto _build() {
    _$PlaceMultiVendorOrderDto _$result;
    try {
      _$result =
          _$v ??
          _$PlaceMultiVendorOrderDto._(
            vendorIds: vendorIds.build(),
            paymentMethod: BuiltValueNullFieldError.checkNotNull(
              paymentMethod,
              r'PlaceMultiVendorOrderDto',
              'paymentMethod',
            ),
            deliveryAddress: BuiltValueNullFieldError.checkNotNull(
              deliveryAddress,
              r'PlaceMultiVendorOrderDto',
              'deliveryAddress',
            ),
            deliveryLocation: deliveryLocation.build(),
            specialRequest: specialRequest,
            coinsToUse: coinsToUse,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vendorIds';
        vendorIds.build();

        _$failedField = 'deliveryLocation';
        deliveryLocation.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PlaceMultiVendorOrderDto',
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
