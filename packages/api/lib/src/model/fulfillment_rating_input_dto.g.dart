// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fulfillment_rating_input_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FulfillmentRatingInputDto extends FulfillmentRatingInputDto {
  @override
  final String fulfillmentId;
  @override
  final num rating;
  @override
  final String? comment;

  factory _$FulfillmentRatingInputDto([
    void Function(FulfillmentRatingInputDtoBuilder)? updates,
  ]) => (FulfillmentRatingInputDtoBuilder()..update(updates))._build();

  _$FulfillmentRatingInputDto._({
    required this.fulfillmentId,
    required this.rating,
    this.comment,
  }) : super._();
  @override
  FulfillmentRatingInputDto rebuild(
    void Function(FulfillmentRatingInputDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  FulfillmentRatingInputDtoBuilder toBuilder() =>
      FulfillmentRatingInputDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FulfillmentRatingInputDto &&
        fulfillmentId == other.fulfillmentId &&
        rating == other.rating &&
        comment == other.comment;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fulfillmentId.hashCode);
    _$hash = $jc(_$hash, rating.hashCode);
    _$hash = $jc(_$hash, comment.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FulfillmentRatingInputDto')
          ..add('fulfillmentId', fulfillmentId)
          ..add('rating', rating)
          ..add('comment', comment))
        .toString();
  }
}

class FulfillmentRatingInputDtoBuilder
    implements
        Builder<FulfillmentRatingInputDto, FulfillmentRatingInputDtoBuilder> {
  _$FulfillmentRatingInputDto? _$v;

  String? _fulfillmentId;
  String? get fulfillmentId => _$this._fulfillmentId;
  set fulfillmentId(String? fulfillmentId) =>
      _$this._fulfillmentId = fulfillmentId;

  num? _rating;
  num? get rating => _$this._rating;
  set rating(num? rating) => _$this._rating = rating;

  String? _comment;
  String? get comment => _$this._comment;
  set comment(String? comment) => _$this._comment = comment;

  FulfillmentRatingInputDtoBuilder() {
    FulfillmentRatingInputDto._defaults(this);
  }

  FulfillmentRatingInputDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fulfillmentId = $v.fulfillmentId;
      _rating = $v.rating;
      _comment = $v.comment;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FulfillmentRatingInputDto other) {
    _$v = other as _$FulfillmentRatingInputDto;
  }

  @override
  void update(void Function(FulfillmentRatingInputDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FulfillmentRatingInputDto build() => _build();

  _$FulfillmentRatingInputDto _build() {
    final _$result =
        _$v ??
        _$FulfillmentRatingInputDto._(
          fulfillmentId: BuiltValueNullFieldError.checkNotNull(
            fulfillmentId,
            r'FulfillmentRatingInputDto',
            'fulfillmentId',
          ),
          rating: BuiltValueNullFieldError.checkNotNull(
            rating,
            r'FulfillmentRatingInputDto',
            'rating',
          ),
          comment: comment,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
