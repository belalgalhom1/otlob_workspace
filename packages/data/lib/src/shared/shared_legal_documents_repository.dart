import 'package:dio/dio.dart';
import 'response_parser.dart';

class SharedLegalDocumentsRepository {
  final Dio _dio;

  SharedLegalDocumentsRepository(this._dio);

  /// Fetch currently active and published legal document (e.g. TERMS_OF_USE or PRIVACY_POLICY)
  Future<Map<String, dynamic>?> getActiveDocument(String type) async {
    final response = await _dio.get('/legal-documents/active/$type');
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return null;
  }

  /// Check whether the logged-in user needs to accept the latest published Terms of Use
  Future<Map<String, dynamic>?> getAcceptanceStatus() async {
    final response = await _dio.get('/legal-documents/acceptance-status');
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return null;
  }

  /// Accept a legal document version
  Future<Map<String, dynamic>?> acceptDocument({
    required String documentId,
    required String version,
  }) async {
    final response = await _dio.post(
      '/legal-documents/accept',
      data: {
        'documentId': documentId,
        'version': version,
      },
    );
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return null;
  }
}
