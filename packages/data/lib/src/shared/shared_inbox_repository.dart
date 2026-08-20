import 'package:api/api.dart';
import 'response_parser.dart';

class SharedInboxRepository {
  final InboxSummaryCountsApi _api;
  SharedInboxRepository(this._api);

  Future<dynamic> getCounts() async {
    final response = await _api.inboxControllerGetCounts();
    return ResponseParser.parse(response);
  }
}