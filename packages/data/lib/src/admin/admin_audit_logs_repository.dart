import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminAuditLogsRepository {
  final AuditLogsApi _api;
  AdminAuditLogsRepository(this._api);

  Future<Map<String, dynamic>> getAuditLogs({
    int page = 1,
    String? actionType,
    String? entityType,
    String? userId,
  }) async {
    final response = await _api.auditLogsControllerFindAll(
      page: page,
      actionType: actionType,
      entityType: entityType,
      userId: userId,
    );
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return {};
  }
}