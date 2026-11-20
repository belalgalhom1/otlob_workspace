// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'excluded_incidents_summary_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExcludedIncidentsSummaryDto extends ExcludedIncidentsSummaryDto {
  @override
  final num customer;
  @override
  final num vendor;
  @override
  final num externalOrSystem;
  @override
  final num underReview;

  factory _$ExcludedIncidentsSummaryDto([
    void Function(ExcludedIncidentsSummaryDtoBuilder)? updates,
  ]) => (ExcludedIncidentsSummaryDtoBuilder()..update(updates))._build();

  _$ExcludedIncidentsSummaryDto._({
    required this.customer,
    required this.vendor,
    required this.externalOrSystem,
    required this.underReview,
  }) : super._();
  @override
  ExcludedIncidentsSummaryDto rebuild(
    void Function(ExcludedIncidentsSummaryDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ExcludedIncidentsSummaryDtoBuilder toBuilder() =>
      ExcludedIncidentsSummaryDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExcludedIncidentsSummaryDto &&
        customer == other.customer &&
        vendor == other.vendor &&
        externalOrSystem == other.externalOrSystem &&
        underReview == other.underReview;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, customer.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jc(_$hash, externalOrSystem.hashCode);
    _$hash = $jc(_$hash, underReview.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExcludedIncidentsSummaryDto')
          ..add('customer', customer)
          ..add('vendor', vendor)
          ..add('externalOrSystem', externalOrSystem)
          ..add('underReview', underReview))
        .toString();
  }
}

class ExcludedIncidentsSummaryDtoBuilder
    implements
        Builder<
          ExcludedIncidentsSummaryDto,
          ExcludedIncidentsSummaryDtoBuilder
        > {
  _$ExcludedIncidentsSummaryDto? _$v;

  num? _customer;
  num? get customer => _$this._customer;
  set customer(num? customer) => _$this._customer = customer;

  num? _vendor;
  num? get vendor => _$this._vendor;
  set vendor(num? vendor) => _$this._vendor = vendor;

  num? _externalOrSystem;
  num? get externalOrSystem => _$this._externalOrSystem;
  set externalOrSystem(num? externalOrSystem) =>
      _$this._externalOrSystem = externalOrSystem;

  num? _underReview;
  num? get underReview => _$this._underReview;
  set underReview(num? underReview) => _$this._underReview = underReview;

  ExcludedIncidentsSummaryDtoBuilder() {
    ExcludedIncidentsSummaryDto._defaults(this);
  }

  ExcludedIncidentsSummaryDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _customer = $v.customer;
      _vendor = $v.vendor;
      _externalOrSystem = $v.externalOrSystem;
      _underReview = $v.underReview;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExcludedIncidentsSummaryDto other) {
    _$v = other as _$ExcludedIncidentsSummaryDto;
  }

  @override
  void update(void Function(ExcludedIncidentsSummaryDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExcludedIncidentsSummaryDto build() => _build();

  _$ExcludedIncidentsSummaryDto _build() {
    final _$result =
        _$v ??
        _$ExcludedIncidentsSummaryDto._(
          customer: BuiltValueNullFieldError.checkNotNull(
            customer,
            r'ExcludedIncidentsSummaryDto',
            'customer',
          ),
          vendor: BuiltValueNullFieldError.checkNotNull(
            vendor,
            r'ExcludedIncidentsSummaryDto',
            'vendor',
          ),
          externalOrSystem: BuiltValueNullFieldError.checkNotNull(
            externalOrSystem,
            r'ExcludedIncidentsSummaryDto',
            'externalOrSystem',
          ),
          underReview: BuiltValueNullFieldError.checkNotNull(
            underReview,
            r'ExcludedIncidentsSummaryDto',
            'underReview',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
