// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_group_rating_input_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeliveryGroupRatingInputDto extends DeliveryGroupRatingInputDto {
  @override
  final String deliveryGroupId;
  @override
  final num rating;
  @override
  final String? comment;

  factory _$DeliveryGroupRatingInputDto([
    void Function(DeliveryGroupRatingInputDtoBuilder)? updates,
  ]) => (DeliveryGroupRatingInputDtoBuilder()..update(updates))._build();

  _$DeliveryGroupRatingInputDto._({
    required this.deliveryGroupId,
    required this.rating,
    this.comment,
  }) : super._();
  @override
  DeliveryGroupRatingInputDto rebuild(
    void Function(DeliveryGroupRatingInputDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DeliveryGroupRatingInputDtoBuilder toBuilder() =>
      DeliveryGroupRatingInputDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeliveryGroupRatingInputDto &&
        deliveryGroupId == other.deliveryGroupId &&
        rating == other.rating &&
        comment == other.comment;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, deliveryGroupId.hashCode);
    _$hash = $jc(_$hash, rating.hashCode);
    _$hash = $jc(_$hash, comment.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeliveryGroupRatingInputDto')
          ..add('deliveryGroupId', deliveryGroupId)
          ..add('rating', rating)
          ..add('comment', comment))
        .toString();
  }
}

class DeliveryGroupRatingInputDtoBuilder
    implements
        Builder<
          DeliveryGroupRatingInputDto,
          DeliveryGroupRatingInputDtoBuilder
        > {
  _$DeliveryGroupRatingInputDto? _$v;

  String? _deliveryGroupId;
  String? get deliveryGroupId => _$this._deliveryGroupId;
  set deliveryGroupId(String? deliveryGroupId) =>
      _$this._deliveryGroupId = deliveryGroupId;

  num? _rating;
  num? get rating => _$this._rating;
  set rating(num? rating) => _$this._rating = rating;

  String? _comment;
  String? get comment => _$this._comment;
  set comment(String? comment) => _$this._comment = comment;

  DeliveryGroupRatingInputDtoBuilder() {
    DeliveryGroupRatingInputDto._defaults(this);
  }

  DeliveryGroupRatingInputDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _deliveryGroupId = $v.deliveryGroupId;
      _rating = $v.rating;
      _comment = $v.comment;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeliveryGroupRatingInputDto other) {
    _$v = other as _$DeliveryGroupRatingInputDto;
  }

  @override
  void update(void Function(DeliveryGroupRatingInputDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeliveryGroupRatingInputDto build() => _build();

  _$DeliveryGroupRatingInputDto _build() {
    final _$result =
        _$v ??
        _$DeliveryGroupRatingInputDto._(
          deliveryGroupId: BuiltValueNullFieldError.checkNotNull(
            deliveryGroupId,
            r'DeliveryGroupRatingInputDto',
            'deliveryGroupId',
          ),
          rating: BuiltValueNullFieldError.checkNotNull(
            rating,
            r'DeliveryGroupRatingInputDto',
            'rating',
          ),
          comment: comment,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
