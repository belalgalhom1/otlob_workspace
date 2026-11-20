import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminDriverRankingRepository {
  final DriverRankingApi _api;

  AdminDriverRankingRepository(this._api);

  Future<DriverRankingScheduleStatusDto> getScheduleStatus() async {
    final response = await _api.driverRankingControllerGetScheduleStatus();
    return ResponseParser.parseTyped(
      response,
      DriverRankingScheduleStatusDto.serializer,
    );
  }

  Future<DriverRankingPreviewResponseDto> previewEvaluation({
    int page = 1,
    int limit = 50,
    String? search,
    DriverTier? tier,
  }) async {
    final trimmedSearch = search?.trim();
    final response = await _api.driverRankingControllerPreviewEvaluation(
      page: page,
      limit: limit,
      search: (trimmedSearch != null && trimmedSearch.isNotEmpty)
          ? trimmedSearch
          : null,
      tier: tier,
    );
    return ResponseParser.parseTyped(
      response,
      DriverRankingPreviewResponseDto.serializer,
    );
  }

  Future<DriverRankingEvaluationRunDto> runEvaluationNow() async {
    final response = await _api.driverRankingControllerRunEvaluationNow();
    return ResponseParser.parseTyped(
      response,
      DriverRankingEvaluationRunDto.serializer,
    );
  }

  Future<PaginatedRankingRunsResponseDto> listRuns({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.driverRankingControllerListRuns(
      page: page,
      limit: limit,
    );
    return ResponseParser.parseTyped(
      response,
      PaginatedRankingRunsResponseDto.serializer,
    );
  }

  Future<DriverRankingRunDetailsResponseDto> getRunDetails(
    String runId, {
    int page = 1,
    int limit = 50,
    String? search,
    DriverTier? tier,
  }) async {
    final trimmedSearch = search?.trim();
    final response = await _api.driverRankingControllerGetRunDetails(
      runId: runId,
      page: page,
      limit: limit,
      search: (trimmedSearch != null && trimmedSearch.isNotEmpty)
          ? trimmedSearch
          : null,
      tier: tier,
    );
    return ResponseParser.parseTyped(
      response,
      DriverRankingRunDetailsResponseDto.serializer,
    );
  }

  Future<DriverRankingEvaluationRunDto> retryFailedRun(String runId) async {
    final response = await _api.driverRankingControllerRetryFailedRun(
      runId: runId,
    );
    return ResponseParser.parseTyped(
      response,
      DriverRankingEvaluationRunDto.serializer,
    );
  }

  Future<PaginatedDriverRankHistoryResponseDto> getDriverHistory(
    String driverId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.driverRankingControllerGetDriverHistory(
      driverId: driverId,
      page: page,
      limit: limit,
    );
    return ResponseParser.parseTyped(
      response,
      PaginatedDriverRankHistoryResponseDto.serializer,
    );
  }

  Future<DriverRankHistoryEntryDto> overrideDriverTier(
    String driverId, {
    required DriverTier newTier,
    required String reason,
  }) async {
    final dto = OverrideDriverRankDto(
      (b) => b
        ..newTier = newTier
        ..reason = reason.trim(),
    );
    final response = await _api.driverRankingControllerOverrideDriverTier(
      driverId: driverId,
      overrideDriverRankDto: dto,
    );
    return ResponseParser.parseTyped(
      response,
      DriverRankHistoryEntryDto.serializer,
    );
  }

  Future<PaginatedDeliveryIncidentsResponseDto> listIncidents({
    int page = 1,
    int limit = 20,
    DeliveryIncidentResponsibility? responsibility,
    String? driverId,
  }) async {
    final trimmedDriverId = driverId?.trim();
    final response = await _api.driverRankingControllerListIncidents(
      page: page,
      limit: limit,
      responsibility: responsibility,
      driverId: (trimmedDriverId != null && trimmedDriverId.isNotEmpty)
          ? trimmedDriverId
          : null,
    );
    return ResponseParser.parseTyped(
      response,
      PaginatedDeliveryIncidentsResponseDto.serializer,
    );
  }

  Future<DriverDeliveryIncidentDto> reviewIncident(
    String incidentId, {
    required DeliveryIncidentResponsibility responsibility,
    String? reviewNote,
  }) async {
    final trimmedNote = reviewNote?.trim();
    final dto = UpdateDeliveryIncidentDto((b) {
      b.responsibility = responsibility;
      if (trimmedNote != null && trimmedNote.isNotEmpty) {
        b.reviewNote = trimmedNote;
      }
    });
    final response = await _api.driverRankingControllerReviewIncident(
      incidentId: incidentId,
      updateDeliveryIncidentDto: dto,
    );
    return ResponseParser.parseTyped(
      response,
      DriverDeliveryIncidentDto.serializer,
    );
  }
}
