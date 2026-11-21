// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_my_rank_summary_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverMyRankSummaryResponseDto extends DriverMyRankSummaryResponseDto {
  @override
  final String driverId;
  @override
  final DriverTier currentTier;
  @override
  final String timezone;
  @override
  final num goldThreshold;
  @override
  final num silverThreshold;
  @override
  final DateTime nextEvaluationAt;
  @override
  final RankingWeekWindowDto currentWeek;
  @override
  final DriverRankingPreviewItemDto? currentWeekProgress;
  @override
  final DriverRankHistoryEntryDto? latestEvaluation;
  @override
  final BuiltList<DriverRankHistoryEntryDto> recentHistory;

  factory _$DriverMyRankSummaryResponseDto([
    void Function(DriverMyRankSummaryResponseDtoBuilder)? updates,
  ]) => (DriverMyRankSummaryResponseDtoBuilder()..update(updates))._build();

  _$DriverMyRankSummaryResponseDto._({
    required this.driverId,
    required this.currentTier,
    required this.timezone,
    required this.goldThreshold,
    required this.silverThreshold,
    required this.nextEvaluationAt,
    required this.currentWeek,
    this.currentWeekProgress,
    this.latestEvaluation,
    required this.recentHistory,
  }) : super._();
  @override
  DriverMyRankSummaryResponseDto rebuild(
    void Function(DriverMyRankSummaryResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverMyRankSummaryResponseDtoBuilder toBuilder() =>
      DriverMyRankSummaryResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverMyRankSummaryResponseDto &&
        driverId == other.driverId &&
        currentTier == other.currentTier &&
        timezone == other.timezone &&
        goldThreshold == other.goldThreshold &&
        silverThreshold == other.silverThreshold &&
        nextEvaluationAt == other.nextEvaluationAt &&
        currentWeek == other.currentWeek &&
        currentWeekProgress == other.currentWeekProgress &&
        latestEvaluation == other.latestEvaluation &&
        recentHistory == other.recentHistory;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, currentTier.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, goldThreshold.hashCode);
    _$hash = $jc(_$hash, silverThreshold.hashCode);
    _$hash = $jc(_$hash, nextEvaluationAt.hashCode);
    _$hash = $jc(_$hash, currentWeek.hashCode);
    _$hash = $jc(_$hash, currentWeekProgress.hashCode);
    _$hash = $jc(_$hash, latestEvaluation.hashCode);
    _$hash = $jc(_$hash, recentHistory.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverMyRankSummaryResponseDto')
          ..add('driverId', driverId)
          ..add('currentTier', currentTier)
          ..add('timezone', timezone)
          ..add('goldThreshold', goldThreshold)
          ..add('silverThreshold', silverThreshold)
          ..add('nextEvaluationAt', nextEvaluationAt)
          ..add('currentWeek', currentWeek)
          ..add('currentWeekProgress', currentWeekProgress)
          ..add('latestEvaluation', latestEvaluation)
          ..add('recentHistory', recentHistory))
        .toString();
  }
}

class DriverMyRankSummaryResponseDtoBuilder
    implements
        Builder<
          DriverMyRankSummaryResponseDto,
          DriverMyRankSummaryResponseDtoBuilder
        > {
  _$DriverMyRankSummaryResponseDto? _$v;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  DriverTier? _currentTier;
  DriverTier? get currentTier => _$this._currentTier;
  set currentTier(DriverTier? currentTier) => _$this._currentTier = currentTier;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  num? _goldThreshold;
  num? get goldThreshold => _$this._goldThreshold;
  set goldThreshold(num? goldThreshold) =>
      _$this._goldThreshold = goldThreshold;

  num? _silverThreshold;
  num? get silverThreshold => _$this._silverThreshold;
  set silverThreshold(num? silverThreshold) =>
      _$this._silverThreshold = silverThreshold;

  DateTime? _nextEvaluationAt;
  DateTime? get nextEvaluationAt => _$this._nextEvaluationAt;
  set nextEvaluationAt(DateTime? nextEvaluationAt) =>
      _$this._nextEvaluationAt = nextEvaluationAt;

  RankingWeekWindowDtoBuilder? _currentWeek;
  RankingWeekWindowDtoBuilder get currentWeek =>
      _$this._currentWeek ??= RankingWeekWindowDtoBuilder();
  set currentWeek(RankingWeekWindowDtoBuilder? currentWeek) =>
      _$this._currentWeek = currentWeek;

  DriverRankingPreviewItemDtoBuilder? _currentWeekProgress;
  DriverRankingPreviewItemDtoBuilder get currentWeekProgress =>
      _$this._currentWeekProgress ??= DriverRankingPreviewItemDtoBuilder();
  set currentWeekProgress(
    DriverRankingPreviewItemDtoBuilder? currentWeekProgress,
  ) => _$this._currentWeekProgress = currentWeekProgress;

  DriverRankHistoryEntryDtoBuilder? _latestEvaluation;
  DriverRankHistoryEntryDtoBuilder get latestEvaluation =>
      _$this._latestEvaluation ??= DriverRankHistoryEntryDtoBuilder();
  set latestEvaluation(DriverRankHistoryEntryDtoBuilder? latestEvaluation) =>
      _$this._latestEvaluation = latestEvaluation;

  ListBuilder<DriverRankHistoryEntryDto>? _recentHistory;
  ListBuilder<DriverRankHistoryEntryDto> get recentHistory =>
      _$this._recentHistory ??= ListBuilder<DriverRankHistoryEntryDto>();
  set recentHistory(ListBuilder<DriverRankHistoryEntryDto>? recentHistory) =>
      _$this._recentHistory = recentHistory;

  DriverMyRankSummaryResponseDtoBuilder() {
    DriverMyRankSummaryResponseDto._defaults(this);
  }

  DriverMyRankSummaryResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driverId = $v.driverId;
      _currentTier = $v.currentTier;
      _timezone = $v.timezone;
      _goldThreshold = $v.goldThreshold;
      _silverThreshold = $v.silverThreshold;
      _nextEvaluationAt = $v.nextEvaluationAt;
      _currentWeek = $v.currentWeek.toBuilder();
      _currentWeekProgress = $v.currentWeekProgress?.toBuilder();
      _latestEvaluation = $v.latestEvaluation?.toBuilder();
      _recentHistory = $v.recentHistory.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverMyRankSummaryResponseDto other) {
    _$v = other as _$DriverMyRankSummaryResponseDto;
  }

  @override
  void update(void Function(DriverMyRankSummaryResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverMyRankSummaryResponseDto build() => _build();

  _$DriverMyRankSummaryResponseDto _build() {
    _$DriverMyRankSummaryResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$DriverMyRankSummaryResponseDto._(
            driverId: BuiltValueNullFieldError.checkNotNull(
              driverId,
              r'DriverMyRankSummaryResponseDto',
              'driverId',
            ),
            currentTier: BuiltValueNullFieldError.checkNotNull(
              currentTier,
              r'DriverMyRankSummaryResponseDto',
              'currentTier',
            ),
            timezone: BuiltValueNullFieldError.checkNotNull(
              timezone,
              r'DriverMyRankSummaryResponseDto',
              'timezone',
            ),
            goldThreshold: BuiltValueNullFieldError.checkNotNull(
              goldThreshold,
              r'DriverMyRankSummaryResponseDto',
              'goldThreshold',
            ),
            silverThreshold: BuiltValueNullFieldError.checkNotNull(
              silverThreshold,
              r'DriverMyRankSummaryResponseDto',
              'silverThreshold',
            ),
            nextEvaluationAt: BuiltValueNullFieldError.checkNotNull(
              nextEvaluationAt,
              r'DriverMyRankSummaryResponseDto',
              'nextEvaluationAt',
            ),
            currentWeek: currentWeek.build(),
            currentWeekProgress: _currentWeekProgress?.build(),
            latestEvaluation: _latestEvaluation?.build(),
            recentHistory: recentHistory.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'currentWeek';
        currentWeek.build();
        _$failedField = 'currentWeekProgress';
        _currentWeekProgress?.build();
        _$failedField = 'latestEvaluation';
        _latestEvaluation?.build();
        _$failedField = 'recentHistory';
        recentHistory.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DriverMyRankSummaryResponseDto',
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
