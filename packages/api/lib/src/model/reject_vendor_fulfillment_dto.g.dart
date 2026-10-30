// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reject_vendor_fulfillment_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RejectVendorFulfillmentDtoCodeEnum
_$rejectVendorFulfillmentDtoCodeEnum_OUT_OF_STOCK =
    const RejectVendorFulfillmentDtoCodeEnum._('OUT_OF_STOCK');
const RejectVendorFulfillmentDtoCodeEnum
_$rejectVendorFulfillmentDtoCodeEnum_OUT_OF_DELIVERY_RANGE =
    const RejectVendorFulfillmentDtoCodeEnum._('OUT_OF_DELIVERY_RANGE');
const RejectVendorFulfillmentDtoCodeEnum
_$rejectVendorFulfillmentDtoCodeEnum_TOO_BUSY =
    const RejectVendorFulfillmentDtoCodeEnum._('TOO_BUSY');
const RejectVendorFulfillmentDtoCodeEnum
_$rejectVendorFulfillmentDtoCodeEnum_ITEM_UNAVAILABLE =
    const RejectVendorFulfillmentDtoCodeEnum._('ITEM_UNAVAILABLE');
const RejectVendorFulfillmentDtoCodeEnum
_$rejectVendorFulfillmentDtoCodeEnum_ADDRESS_UNREACHABLE =
    const RejectVendorFulfillmentDtoCodeEnum._('ADDRESS_UNREACHABLE');
const RejectVendorFulfillmentDtoCodeEnum
_$rejectVendorFulfillmentDtoCodeEnum_ORDER_TOO_LARGE =
    const RejectVendorFulfillmentDtoCodeEnum._('ORDER_TOO_LARGE');
const RejectVendorFulfillmentDtoCodeEnum
_$rejectVendorFulfillmentDtoCodeEnum_OTHER =
    const RejectVendorFulfillmentDtoCodeEnum._('OTHER');

RejectVendorFulfillmentDtoCodeEnum _$rejectVendorFulfillmentDtoCodeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'OUT_OF_STOCK':
      return _$rejectVendorFulfillmentDtoCodeEnum_OUT_OF_STOCK;
    case 'OUT_OF_DELIVERY_RANGE':
      return _$rejectVendorFulfillmentDtoCodeEnum_OUT_OF_DELIVERY_RANGE;
    case 'TOO_BUSY':
      return _$rejectVendorFulfillmentDtoCodeEnum_TOO_BUSY;
    case 'ITEM_UNAVAILABLE':
      return _$rejectVendorFulfillmentDtoCodeEnum_ITEM_UNAVAILABLE;
    case 'ADDRESS_UNREACHABLE':
      return _$rejectVendorFulfillmentDtoCodeEnum_ADDRESS_UNREACHABLE;
    case 'ORDER_TOO_LARGE':
      return _$rejectVendorFulfillmentDtoCodeEnum_ORDER_TOO_LARGE;
    case 'OTHER':
      return _$rejectVendorFulfillmentDtoCodeEnum_OTHER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RejectVendorFulfillmentDtoCodeEnum>
_$rejectVendorFulfillmentDtoCodeEnumValues =
    BuiltSet<RejectVendorFulfillmentDtoCodeEnum>(
      const <RejectVendorFulfillmentDtoCodeEnum>[
        _$rejectVendorFulfillmentDtoCodeEnum_OUT_OF_STOCK,
        _$rejectVendorFulfillmentDtoCodeEnum_OUT_OF_DELIVERY_RANGE,
        _$rejectVendorFulfillmentDtoCodeEnum_TOO_BUSY,
        _$rejectVendorFulfillmentDtoCodeEnum_ITEM_UNAVAILABLE,
        _$rejectVendorFulfillmentDtoCodeEnum_ADDRESS_UNREACHABLE,
        _$rejectVendorFulfillmentDtoCodeEnum_ORDER_TOO_LARGE,
        _$rejectVendorFulfillmentDtoCodeEnum_OTHER,
      ],
    );

Serializer<RejectVendorFulfillmentDtoCodeEnum>
_$rejectVendorFulfillmentDtoCodeEnumSerializer =
    _$RejectVendorFulfillmentDtoCodeEnumSerializer();

class _$RejectVendorFulfillmentDtoCodeEnumSerializer
    implements PrimitiveSerializer<RejectVendorFulfillmentDtoCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OUT_OF_STOCK': 'OUT_OF_STOCK',
    'OUT_OF_DELIVERY_RANGE': 'OUT_OF_DELIVERY_RANGE',
    'TOO_BUSY': 'TOO_BUSY',
    'ITEM_UNAVAILABLE': 'ITEM_UNAVAILABLE',
    'ADDRESS_UNREACHABLE': 'ADDRESS_UNREACHABLE',
    'ORDER_TOO_LARGE': 'ORDER_TOO_LARGE',
    'OTHER': 'OTHER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OUT_OF_STOCK': 'OUT_OF_STOCK',
    'OUT_OF_DELIVERY_RANGE': 'OUT_OF_DELIVERY_RANGE',
    'TOO_BUSY': 'TOO_BUSY',
    'ITEM_UNAVAILABLE': 'ITEM_UNAVAILABLE',
    'ADDRESS_UNREACHABLE': 'ADDRESS_UNREACHABLE',
    'ORDER_TOO_LARGE': 'ORDER_TOO_LARGE',
    'OTHER': 'OTHER',
  };

  @override
  final Iterable<Type> types = const <Type>[RejectVendorFulfillmentDtoCodeEnum];
  @override
  final String wireName = 'RejectVendorFulfillmentDtoCodeEnum';

  @override
  Object serialize(
    Serializers serializers,
    RejectVendorFulfillmentDtoCodeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RejectVendorFulfillmentDtoCodeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RejectVendorFulfillmentDtoCodeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RejectVendorFulfillmentDto extends RejectVendorFulfillmentDto {
  @override
  final RejectVendorFulfillmentDtoCodeEnum code;
  @override
  final String reason;
  @override
  final String? reasonAr;

  factory _$RejectVendorFulfillmentDto([
    void Function(RejectVendorFulfillmentDtoBuilder)? updates,
  ]) => (RejectVendorFulfillmentDtoBuilder()..update(updates))._build();

  _$RejectVendorFulfillmentDto._({
    required this.code,
    required this.reason,
    this.reasonAr,
  }) : super._();
  @override
  RejectVendorFulfillmentDto rebuild(
    void Function(RejectVendorFulfillmentDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RejectVendorFulfillmentDtoBuilder toBuilder() =>
      RejectVendorFulfillmentDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RejectVendorFulfillmentDto &&
        code == other.code &&
        reason == other.reason &&
        reasonAr == other.reasonAr;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, reasonAr.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RejectVendorFulfillmentDto')
          ..add('code', code)
          ..add('reason', reason)
          ..add('reasonAr', reasonAr))
        .toString();
  }
}

class RejectVendorFulfillmentDtoBuilder
    implements
        Builder<RejectVendorFulfillmentDto, RejectVendorFulfillmentDtoBuilder> {
  _$RejectVendorFulfillmentDto? _$v;

  RejectVendorFulfillmentDtoCodeEnum? _code;
  RejectVendorFulfillmentDtoCodeEnum? get code => _$this._code;
  set code(RejectVendorFulfillmentDtoCodeEnum? code) => _$this._code = code;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  String? _reasonAr;
  String? get reasonAr => _$this._reasonAr;
  set reasonAr(String? reasonAr) => _$this._reasonAr = reasonAr;

  RejectVendorFulfillmentDtoBuilder() {
    RejectVendorFulfillmentDto._defaults(this);
  }

  RejectVendorFulfillmentDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _reason = $v.reason;
      _reasonAr = $v.reasonAr;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RejectVendorFulfillmentDto other) {
    _$v = other as _$RejectVendorFulfillmentDto;
  }

  @override
  void update(void Function(RejectVendorFulfillmentDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RejectVendorFulfillmentDto build() => _build();

  _$RejectVendorFulfillmentDto _build() {
    final _$result =
        _$v ??
        _$RejectVendorFulfillmentDto._(
          code: BuiltValueNullFieldError.checkNotNull(
            code,
            r'RejectVendorFulfillmentDto',
            'code',
          ),
          reason: BuiltValueNullFieldError.checkNotNull(
            reason,
            r'RejectVendorFulfillmentDto',
            'reason',
          ),
          reasonAr: reasonAr,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
