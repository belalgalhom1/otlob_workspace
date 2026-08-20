// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_reviews_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaginatedReviewsResponseDto extends PaginatedReviewsResponseDto {
  @override
  final BuiltList<ReviewDto> data;
  @override
  final PaginationMetaDto meta;

  factory _$PaginatedReviewsResponseDto([
    void Function(PaginatedReviewsResponseDtoBuilder)? updates,
  ]) => (PaginatedReviewsResponseDtoBuilder()..update(updates))._build();

  _$PaginatedReviewsResponseDto._({required this.data, required this.meta})
    : super._();
  @override
  PaginatedReviewsResponseDto rebuild(
    void Function(PaginatedReviewsResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PaginatedReviewsResponseDtoBuilder toBuilder() =>
      PaginatedReviewsResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaginatedReviewsResponseDto &&
        data == other.data &&
        meta == other.meta;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, data.hashCode);
    _$hash = $jc(_$hash, meta.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PaginatedReviewsResponseDto')
          ..add('data', data)
          ..add('meta', meta))
        .toString();
  }
}

class PaginatedReviewsResponseDtoBuilder
    implements
        Builder<
          PaginatedReviewsResponseDto,
          PaginatedReviewsResponseDtoBuilder
        > {
  _$PaginatedReviewsResponseDto? _$v;

  ListBuilder<ReviewDto>? _data;
  ListBuilder<ReviewDto> get data => _$this._data ??= ListBuilder<ReviewDto>();
  set data(ListBuilder<ReviewDto>? data) => _$this._data = data;

  PaginationMetaDtoBuilder? _meta;
  PaginationMetaDtoBuilder get meta =>
      _$this._meta ??= PaginationMetaDtoBuilder();
  set meta(PaginationMetaDtoBuilder? meta) => _$this._meta = meta;

  PaginatedReviewsResponseDtoBuilder() {
    PaginatedReviewsResponseDto._defaults(this);
  }

  PaginatedReviewsResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _data = $v.data.toBuilder();
      _meta = $v.meta.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaginatedReviewsResponseDto other) {
    _$v = other as _$PaginatedReviewsResponseDto;
  }

  @override
  void update(void Function(PaginatedReviewsResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PaginatedReviewsResponseDto build() => _build();

  _$PaginatedReviewsResponseDto _build() {
    _$PaginatedReviewsResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$PaginatedReviewsResponseDto._(
            data: data.build(),
            meta: meta.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'data';
        data.build();
        _$failedField = 'meta';
        meta.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PaginatedReviewsResponseDto',
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
