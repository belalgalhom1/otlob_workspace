import 'package:api/api.dart';
import '../shared/response_parser.dart';

class AdminAuditLogsRepository {
  final AuditLogsApi _api;
  AdminAuditLogsRepository(this._api);

  Future<Map<String, dynamic>> getAuditLogs({int page = 1}) async {
    final response = await _api.auditLogsControllerFindAll(page: page);
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return {};
  }
}