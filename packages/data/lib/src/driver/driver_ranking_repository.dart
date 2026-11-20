import 'package:api/api.dart';
import '../shared/response_parser.dart';

class DriverRankingRepository {
  final DriverRankingApi _api;

  DriverRankingRepository(this._api);

  Future<DriverMyRankSummaryResponseDto> getMyRankSummary() async {
    final response = await _api.driverRankingControllerGetMyRankSummary();
    return ResponseParser.parseTyped(
      response,
      DriverMyRankSummaryResponseDto.serializer,
    );
  }
}
