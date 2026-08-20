// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rate_order_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RateOrderDto extends RateOrderDto {
  @override
  final num? vendorRating;
  @override
  final num? driverRating;
  @override
  final String? comment;

  factory _$RateOrderDto([void Function(RateOrderDtoBuilder)? updates]) =>
      (RateOrderDtoBuilder()..update(updates))._build();

  _$RateOrderDto._({this.vendorRating, this.driverRating, this.comment})
    : super._();
  @override
  RateOrderDto rebuild(void Function(RateOrderDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RateOrderDtoBuilder toBuilder() => RateOrderDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RateOrderDto &&
        vendorRating == other.vendorRating &&
        driverRating == other.driverRating &&
        comment == other.comment;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, vendorRating.hashCode);
    _$hash = $jc(_$hash, driverRating.hashCode);
    _$hash = $jc(_$hash, comment.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RateOrderDto')
          ..add('vendorRating', vendorRating)
          ..add('driverRating', driverRating)
          ..add('comment', comment))
        .toString();
  }
}

class RateOrderDtoBuilder
    implements Builder<RateOrderDto, RateOrderDtoBuilder> {
  _$RateOrderDto? _$v;

  num? _vendorRating;
  num? get vendorRating => _$this._vendorRating;
  set vendorRating(num? vendorRating) => _$this._vendorRating = vendorRating;

  num? _driverRating;
  num? get driverRating => _$this._driverRating;
  set driverRating(num? driverRating) => _$this._driverRating = driverRating;

  String? _comment;
  String? get comment => _$this._comment;
  set comment(String? comment) => _$this._comment = comment;

  RateOrderDtoBuilder() {
    RateOrderDto._defaults(this);
  }

  RateOrderDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _vendorRating = $v.vendorRating;
      _driverRating = $v.driverRating;
      _comment = $v.comment;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RateOrderDto other) {
    _$v = other as _$RateOrderDto;
  }

  @override
  void update(void Function(RateOrderDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RateOrderDto build() => _build();

  _$RateOrderDto _build() {
    final _$result =
        _$v ??
        _$RateOrderDto._(
          vendorRating: vendorRating,
          driverRating: driverRating,
          comment: comment,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
