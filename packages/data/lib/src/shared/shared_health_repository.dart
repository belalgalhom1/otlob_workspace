import 'package:api/api.dart';
import 'response_parser.dart';

class SharedHealthRepository {
  final HealthSystemApi _api;
  SharedHealthRepository(this._api);

  Future<dynamic> healthCheck() async {
    final response = await _api.apiControllerRoot();
    return ResponseParser.parse(response);
  }
}
