// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_review_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateReviewDto extends CreateReviewDto {
  @override
  final BuiltList<FulfillmentRatingInputDto>? fulfillmentRatings;
  @override
  final BuiltList<DeliveryGroupRatingInputDto>? deliveryGroupRatings;
  @override
  final num? vendorRating;
  @override
  final num? driverRating;
  @override
  final String? comment;

  factory _$CreateReviewDto([void Function(CreateReviewDtoBuilder)? updates]) =>
      (CreateReviewDtoBuilder()..update(updates))._build();

  _$CreateReviewDto._({
    this.fulfillmentRatings,
    this.deliveryGroupRatings,
    this.vendorRating,
    this.driverRating,
    this.comment,
  }) : super._();
  @override
  CreateReviewDto rebuild(void Function(CreateReviewDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateReviewDtoBuilder toBuilder() => CreateReviewDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateReviewDto &&
        fulfillmentRatings == other.fulfillmentRatings &&
        deliveryGroupRatings == other.deliveryGroupRatings &&
        vendorRating == other.vendorRating &&
        driverRating == other.driverRating &&
        comment == other.comment;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fulfillmentRatings.hashCode);
    _$hash = $jc(_$hash, deliveryGroupRatings.hashCode);
    _$hash = $jc(_$hash, vendorRating.hashCode);
    _$hash = $jc(_$hash, driverRating.hashCode);
    _$hash = $jc(_$hash, comment.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateReviewDto')
          ..add('fulfillmentRatings', fulfillmentRatings)
          ..add('deliveryGroupRatings', deliveryGroupRatings)
          ..add('vendorRating', vendorRating)
          ..add('driverRating', driverRating)
          ..add('comment', comment))
        .toString();
  }
}

class CreateReviewDtoBuilder
    implements Builder<CreateReviewDto, CreateReviewDtoBuilder> {
  _$CreateReviewDto? _$v;

  ListBuilder<FulfillmentRatingInputDto>? _fulfillmentRatings;
  ListBuilder<FulfillmentRatingInputDto> get fulfillmentRatings =>
      _$this._fulfillmentRatings ??= ListBuilder<FulfillmentRatingInputDto>();
  set fulfillmentRatings(
    ListBuilder<FulfillmentRatingInputDto>? fulfillmentRatings,
  ) => _$this._fulfillmentRatings = fulfillmentRatings;

  ListBuilder<DeliveryGroupRatingInputDto>? _deliveryGroupRatings;
  ListBuilder<DeliveryGroupRatingInputDto> get deliveryGroupRatings =>
      _$this._deliveryGroupRatings ??=
          ListBuilder<DeliveryGroupRatingInputDto>();
  set deliveryGroupRatings(
    ListBuilder<DeliveryGroupRatingInputDto>? deliveryGroupRatings,
  ) => _$this._deliveryGroupRatings = deliveryGroupRatings;

  num? _vendorRating;
  num? get vendorRating => _$this._vendorRating;
  set vendorRating(num? vendorRating) => _$this._vendorRating = vendorRating;

  num? _driverRating;
  num? get driverRating => _$this._driverRating;
  set driverRating(num? driverRating) => _$this._driverRating = driverRating;

  String? _comment;
  String? get comment => _$this._comment;
  set comment(String? comment) => _$this._comment = comment;

  CreateReviewDtoBuilder() {
    CreateReviewDto._defaults(this);
  }

  CreateReviewDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fulfillmentRatings = $v.fulfillmentRatings?.toBuilder();
      _deliveryGroupRatings = $v.deliveryGroupRatings?.toBuilder();
      _vendorRating = $v.vendorRating;
      _driverRating = $v.driverRating;
      _comment = $v.comment;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateReviewDto other) {
    _$v = other as _$CreateReviewDto;
  }

  @override
  void update(void Function(CreateReviewDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateReviewDto build() => _build();

  _$CreateReviewDto _build() {
    _$CreateReviewDto _$result;
    try {
      _$result =
          _$v ??
          _$CreateReviewDto._(
            fulfillmentRatings: _fulfillmentRatings?.build(),
            deliveryGroupRatings: _deliveryGroupRatings?.build(),
            vendorRating: vendorRating,
            driverRating: driverRating,
            comment: comment,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'fulfillmentRatings';
        _fulfillmentRatings?.build();
        _$failedField = 'deliveryGroupRatings';
        _deliveryGroupRatings?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreateReviewDto',
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
