// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_direct_order_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PlaceDirectOrderDtoPaymentMethodEnum
_$placeDirectOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY =
    const PlaceDirectOrderDtoPaymentMethodEnum._('CASH_ON_DELIVERY');
const PlaceDirectOrderDtoPaymentMethodEnum
_$placeDirectOrderDtoPaymentMethodEnum_MOBILE_WALLET =
    const PlaceDirectOrderDtoPaymentMethodEnum._('MOBILE_WALLET');

PlaceDirectOrderDtoPaymentMethodEnum
_$placeDirectOrderDtoPaymentMethodEnumValueOf(String name) {
  switch (name) {
    case 'CASH_ON_DELIVERY':
      return _$placeDirectOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY;
    case 'MOBILE_WALLET':
      return _$placeDirectOrderDtoPaymentMethodEnum_MOBILE_WALLET;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PlaceDirectOrderDtoPaymentMethodEnum>
_$placeDirectOrderDtoPaymentMethodEnumValues =
    BuiltSet<PlaceDirectOrderDtoPaymentMethodEnum>(
      const <PlaceDirectOrderDtoPaymentMethodEnum>[
        _$placeDirectOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY,
        _$placeDirectOrderDtoPaymentMethodEnum_MOBILE_WALLET,
      ],
    );

Serializer<PlaceDirectOrderDtoPaymentMethodEnum>
_$placeDirectOrderDtoPaymentMethodEnumSerializer =
    _$PlaceDirectOrderDtoPaymentMethodEnumSerializer();

class _$PlaceDirectOrderDtoPaymentMethodEnumSerializer
    implements PrimitiveSerializer<PlaceDirectOrderDtoPaymentMethodEnum> {
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
    PlaceDirectOrderDtoPaymentMethodEnum,
  ];
  @override
  final String wireName = 'PlaceDirectOrderDtoPaymentMethodEnum';

  @override
  Object serialize(
    Serializers serializers,
    PlaceDirectOrderDtoPaymentMethodEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PlaceDirectOrderDtoPaymentMethodEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PlaceDirectOrderDtoPaymentMethodEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$PlaceDirectOrderDto extends PlaceDirectOrderDto {
  @override
  final String customerId;
  @override
  final String vendorId;
  @override
  final String? productId;
  @override
  final String? productName;
  @override
  final num price;
  @override
  final num quantity;
  @override
  final PlaceDirectOrderDtoPaymentMethodEnum paymentMethod;
  @override
  final String? deliveryAddress;
  @override
  final BuiltList<num>? deliveryLocation;
  @override
  final String? specialRequest;

  factory _$PlaceDirectOrderDto([
    void Function(PlaceDirectOrderDtoBuilder)? updates,
  ]) => (PlaceDirectOrderDtoBuilder()..update(updates))._build();

  _$PlaceDirectOrderDto._({
    required this.customerId,
    required this.vendorId,
    this.productId,
    this.productName,
    required this.price,
    required this.quantity,
    required this.paymentMethod,
    this.deliveryAddress,
    this.deliveryLocation,
    this.specialRequest,
  }) : super._();
  @override
  PlaceDirectOrderDto rebuild(
    void Function(PlaceDirectOrderDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PlaceDirectOrderDtoBuilder toBuilder() =>
      PlaceDirectOrderDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlaceDirectOrderDto &&
        customerId == other.customerId &&
        vendorId == other.vendorId &&
        productId == other.productId &&
        productName == other.productName &&
        price == other.price &&
        quantity == other.quantity &&
        paymentMethod == other.paymentMethod &&
        deliveryAddress == other.deliveryAddress &&
        deliveryLocation == other.deliveryLocation &&
        specialRequest == other.specialRequest;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, customerId.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, productName.hashCode);
    _$hash = $jc(_$hash, price.hashCode);
    _$hash = $jc(_$hash, quantity.hashCode);
    _$hash = $jc(_$hash, paymentMethod.hashCode);
    _$hash = $jc(_$hash, deliveryAddress.hashCode);
    _$hash = $jc(_$hash, deliveryLocation.hashCode);
    _$hash = $jc(_$hash, specialRequest.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlaceDirectOrderDto')
          ..add('customerId', customerId)
          ..add('vendorId', vendorId)
          ..add('productId', productId)
          ..add('productName', productName)
          ..add('price', price)
          ..add('quantity', quantity)
          ..add('paymentMethod', paymentMethod)
          ..add('deliveryAddress', deliveryAddress)
          ..add('deliveryLocation', deliveryLocation)
          ..add('specialRequest', specialRequest))
        .toString();
  }
}

class PlaceDirectOrderDtoBuilder
    implements Builder<PlaceDirectOrderDto, PlaceDirectOrderDtoBuilder> {
  _$PlaceDirectOrderDto? _$v;

  String? _customerId;
  String? get customerId => _$this._customerId;
  set customerId(String? customerId) => _$this._customerId = customerId;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  String? _productName;
  String? get productName => _$this._productName;
  set productName(String? productName) => _$this._productName = productName;

  num? _price;
  num? get price => _$this._price;
  set price(num? price) => _$this._price = price;

  num? _quantity;
  num? get quantity => _$this._quantity;
  set quantity(num? quantity) => _$this._quantity = quantity;

  PlaceDirectOrderDtoPaymentMethodEnum? _paymentMethod;
  PlaceDirectOrderDtoPaymentMethodEnum? get paymentMethod =>
      _$this._paymentMethod;
  set paymentMethod(PlaceDirectOrderDtoPaymentMethodEnum? paymentMethod) =>
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

  PlaceDirectOrderDtoBuilder() {
    PlaceDirectOrderDto._defaults(this);
  }

  PlaceDirectOrderDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _customerId = $v.customerId;
      _vendorId = $v.vendorId;
      _productId = $v.productId;
      _productName = $v.productName;
      _price = $v.price;
      _quantity = $v.quantity;
      _paymentMethod = $v.paymentMethod;
      _deliveryAddress = $v.deliveryAddress;
      _deliveryLocation = $v.deliveryLocation?.toBuilder();
      _specialRequest = $v.specialRequest;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlaceDirectOrderDto other) {
    _$v = other as _$PlaceDirectOrderDto;
  }

  @override
  void update(void Function(PlaceDirectOrderDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlaceDirectOrderDto build() => _build();

  _$PlaceDirectOrderDto _build() {
    _$PlaceDirectOrderDto _$result;
    try {
      _$result =
          _$v ??
          _$PlaceDirectOrderDto._(
            customerId: BuiltValueNullFieldError.checkNotNull(
              customerId,
              r'PlaceDirectOrderDto',
              'customerId',
            ),
            vendorId: BuiltValueNullFieldError.checkNotNull(
              vendorId,
              r'PlaceDirectOrderDto',
              'vendorId',
            ),
            productId: productId,
            productName: productName,
            price: BuiltValueNullFieldError.checkNotNull(
              price,
              r'PlaceDirectOrderDto',
              'price',
            ),
            quantity: BuiltValueNullFieldError.checkNotNull(
              quantity,
              r'PlaceDirectOrderDto',
              'quantity',
            ),
            paymentMethod: BuiltValueNullFieldError.checkNotNull(
              paymentMethod,
              r'PlaceDirectOrderDto',
              'paymentMethod',
            ),
            deliveryAddress: deliveryAddress,
            deliveryLocation: _deliveryLocation?.build(),
            specialRequest: specialRequest,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'deliveryLocation';
        _deliveryLocation?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PlaceDirectOrderDto',
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
