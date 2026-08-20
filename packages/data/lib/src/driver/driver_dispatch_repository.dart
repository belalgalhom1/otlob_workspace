import 'package:api/api.dart';
import '../shared/response_parser.dart';

class DriverDispatchRepository {
  final OrdersApi _api;
  DriverDispatchRepository(this._api);

  Future<dynamic> getMyDispatches() async {
    final response = await _api.ordersControllerGetMyDispatches();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> respondToDispatch(String dispatchId, String responseEnum) async {
    final response = await _api.ordersControllerRespondToDispatch(
      dispatchId: dispatchId,
      respondToDispatchDto: RespondToDispatchDto((b) => b
        ..response = RespondToDispatchDtoResponseEnum.valueOf(responseEnum.toUpperCase())
      )
    );
    return ResponseParser.parse(response);
  }
}
