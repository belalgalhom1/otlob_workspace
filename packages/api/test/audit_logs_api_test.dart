import 'package:test/test.dart';
import 'package:api/api.dart';


/// tests for AuditLogsApi
void main() {
  final instance = Api().getAuditLogsApi();

  group(AuditLogsApi, () {
    // List audit logs with pagination and filters
    //
    //Future<AuditLogsControllerFindAll200Response> auditLogsControllerFindAll({ num page, num limit, String userId, String vendorId, String entityType, String entityId, String actionType }) async
    test('test auditLogsControllerFindAll', () async {
      // TODO
    });

  });
}
