// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retry_search_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RetrySearchResponseDto extends RetrySearchResponseDto {
  @override
  final OrderResponseDto order;
  @override
  final bool retried;
  @override
  final bool alreadySearching;
  @override
  final bool alreadyAssigned;
  @override
  final OrderSearchStatusDto searchStatus;

  factory _$RetrySearchResponseDto([
    void Function(RetrySearchResponseDtoBuilder)? updates,
  ]) => (RetrySearchResponseDtoBuilder()..update(updates))._build();

  _$RetrySearchResponseDto._({
    required this.order,
    required this.retried,
    required this.alreadySearching,
    required this.alreadyAssigned,
    required this.searchStatus,
  }) : super._();
  @override
  RetrySearchResponseDto rebuild(
    void Function(RetrySearchResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RetrySearchResponseDtoBuilder toBuilder() =>
      RetrySearchResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RetrySearchResponseDto &&
        order == other.order &&
        retried == other.retried &&
        alreadySearching == other.alreadySearching &&
        alreadyAssigned == other.alreadyAssigned &&
        searchStatus == other.searchStatus;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, order.hashCode);
    _$hash = $jc(_$hash, retried.hashCode);
    _$hash = $jc(_$hash, alreadySearching.hashCode);
    _$hash = $jc(_$hash, alreadyAssigned.hashCode);
    _$hash = $jc(_$hash, searchStatus.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RetrySearchResponseDto')
          ..add('order', order)
          ..add('retried', retried)
          ..add('alreadySearching', alreadySearching)
          ..add('alreadyAssigned', alreadyAssigned)
          ..add('searchStatus', searchStatus))
        .toString();
  }
}

class RetrySearchResponseDtoBuilder
    implements Builder<RetrySearchResponseDto, RetrySearchResponseDtoBuilder> {
  _$RetrySearchResponseDto? _$v;

  OrderResponseDtoBuilder? _order;
  OrderResponseDtoBuilder get order =>
      _$this._order ??= OrderResponseDtoBuilder();
  set order(OrderResponseDtoBuilder? order) => _$this._order = order;

  bool? _retried;
  bool? get retried => _$this._retried;
  set retried(bool? retried) => _$this._retried = retried;

  bool? _alreadySearching;
  bool? get alreadySearching => _$this._alreadySearching;
  set alreadySearching(bool? alreadySearching) =>
      _$this._alreadySearching = alreadySearching;

  bool? _alreadyAssigned;
  bool? get alreadyAssigned => _$this._alreadyAssigned;
  set alreadyAssigned(bool? alreadyAssigned) =>
      _$this._alreadyAssigned = alreadyAssigned;

  OrderSearchStatusDtoBuilder? _searchStatus;
  OrderSearchStatusDtoBuilder get searchStatus =>
      _$this._searchStatus ??= OrderSearchStatusDtoBuilder();
  set searchStatus(OrderSearchStatusDtoBuilder? searchStatus) =>
      _$this._searchStatus = searchStatus;

  RetrySearchResponseDtoBuilder() {
    RetrySearchResponseDto._defaults(this);
  }

  RetrySearchResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _order = $v.order.toBuilder();
      _retried = $v.retried;
      _alreadySearching = $v.alreadySearching;
      _alreadyAssigned = $v.alreadyAssigned;
      _searchStatus = $v.searchStatus.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RetrySearchResponseDto other) {
    _$v = other as _$RetrySearchResponseDto;
  }

  @override
  void update(void Function(RetrySearchResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RetrySearchResponseDto build() => _build();

  _$RetrySearchResponseDto _build() {
    _$RetrySearchResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$RetrySearchResponseDto._(
            order: order.build(),
            retried: BuiltValueNullFieldError.checkNotNull(
              retried,
              r'RetrySearchResponseDto',
              'retried',
            ),
            alreadySearching: BuiltValueNullFieldError.checkNotNull(
              alreadySearching,
              r'RetrySearchResponseDto',
              'alreadySearching',
            ),
            alreadyAssigned: BuiltValueNullFieldError.checkNotNull(
              alreadyAssigned,
              r'RetrySearchResponseDto',
              'alreadyAssigned',
            ),
            searchStatus: searchStatus.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'order';
        order.build();

        _$failedField = 'searchStatus';
        searchStatus.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'RetrySearchResponseDto',
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
