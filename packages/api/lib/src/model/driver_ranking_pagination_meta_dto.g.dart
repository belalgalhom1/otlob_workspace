// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_ranking_pagination_meta_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverRankingPaginationMetaDto extends DriverRankingPaginationMetaDto {
  @override
  final num total;
  @override
  final num page;
  @override
  final num limit;
  @override
  final num totalPages;

  factory _$DriverRankingPaginationMetaDto([
    void Function(DriverRankingPaginationMetaDtoBuilder)? updates,
  ]) => (DriverRankingPaginationMetaDtoBuilder()..update(updates))._build();

  _$DriverRankingPaginationMetaDto._({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  }) : super._();
  @override
  DriverRankingPaginationMetaDto rebuild(
    void Function(DriverRankingPaginationMetaDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverRankingPaginationMetaDtoBuilder toBuilder() =>
      DriverRankingPaginationMetaDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverRankingPaginationMetaDto &&
        total == other.total &&
        page == other.page &&
        limit == other.limit &&
        totalPages == other.totalPages;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jc(_$hash, limit.hashCode);
    _$hash = $jc(_$hash, totalPages.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverRankingPaginationMetaDto')
          ..add('total', total)
          ..add('page', page)
          ..add('limit', limit)
          ..add('totalPages', totalPages))
        .toString();
  }
}

class DriverRankingPaginationMetaDtoBuilder
    implements
        Builder<
          DriverRankingPaginationMetaDto,
          DriverRankingPaginationMetaDtoBuilder
        > {
  _$DriverRankingPaginationMetaDto? _$v;

  num? _total;
  num? get total => _$this._total;
  set total(num? total) => _$this._total = total;

  num? _page;
  num? get page => _$this._page;
  set page(num? page) => _$this._page = page;

  num? _limit;
  num? get limit => _$this._limit;
  set limit(num? limit) => _$this._limit = limit;

  num? _totalPages;
  num? get totalPages => _$this._totalPages;
  set totalPages(num? totalPages) => _$this._totalPages = totalPages;

  DriverRankingPaginationMetaDtoBuilder() {
    DriverRankingPaginationMetaDto._defaults(this);
  }

  DriverRankingPaginationMetaDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _total = $v.total;
      _page = $v.page;
      _limit = $v.limit;
      _totalPages = $v.totalPages;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverRankingPaginationMetaDto other) {
    _$v = other as _$DriverRankingPaginationMetaDto;
  }

  @override
  void update(void Function(DriverRankingPaginationMetaDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverRankingPaginationMetaDto build() => _build();

  _$DriverRankingPaginationMetaDto _build() {
    final _$result =
        _$v ??
        _$DriverRankingPaginationMetaDto._(
          total: BuiltValueNullFieldError.checkNotNull(
            total,
            r'DriverRankingPaginationMetaDto',
            'total',
          ),
          page: BuiltValueNullFieldError.checkNotNull(
            page,
            r'DriverRankingPaginationMetaDto',
            'page',
          ),
          limit: BuiltValueNullFieldError.checkNotNull(
            limit,
            r'DriverRankingPaginationMetaDto',
            'limit',
          ),
          totalPages: BuiltValueNullFieldError.checkNotNull(
            totalPages,
            r'DriverRankingPaginationMetaDto',
            'totalPages',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
