import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for InboxSummaryCountsApi
void main() {
  final instance = Api().getInboxSummaryCountsApi();

  group(InboxSummaryCountsApi, () {
    // Get unread counts for chat and notifications
    //
    //Future<AuthControllerRegister200Response> inboxControllerGetCounts() async
    test('test inboxControllerGetCounts', () async {
      // TODO
    });

  });
}
