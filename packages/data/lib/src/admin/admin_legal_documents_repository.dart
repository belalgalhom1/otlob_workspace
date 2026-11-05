import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class AdminLegalDocumentsRepository {
  final Dio _dio;

  AdminLegalDocumentsRepository(this._dio);

  /// Fetch all legal documents (drafts, published, archived) with optional type filter
  Future<List<Map<String, dynamic>>> getAllDocuments({String? type}) async {
    final queryParams = <String, dynamic>{};
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final response = await _dio.get(
      '/legal-documents/admin/all',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final parsed = ResponseParser.parseList(response);
    if (parsed is List) {
      return parsed
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  /// Get details of a single document
  Future<Map<String, dynamic>?> getDocumentById(String id) async {
    final response = await _dio.get('/legal-documents/admin/$id');
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return null;
  }

  /// Create a new document draft
  Future<Map<String, dynamic>?> createDocument({
    required String type,
    required String title,
    required String titleAr,
    required String content,
    required String contentAr,
    required String version,
  }) async {
    final response = await _dio.post(
      '/legal-documents/admin',
      data: {
        'type': type,
        'title': title,
        'titleAr': titleAr,
        'content': content,
        'contentAr': contentAr,
        'version': version,
      },
    );
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return null;
  }

  /// Update an existing document draft or version
  Future<Map<String, dynamic>?> updateDocument(
    String id, {
    String? title,
    String? titleAr,
    String? content,
    String? contentAr,
    String? version,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (titleAr != null) data['titleAr'] = titleAr;
    if (content != null) data['content'] = content;
    if (contentAr != null) data['contentAr'] = contentAr;
    if (version != null) data['version'] = version;

    final response = await _dio.patch(
      '/legal-documents/admin/$id',
      data: data,
    );
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return null;
  }

  /// Publish a document version (makes it active, unpublishes older versions of same type)
  Future<Map<String, dynamic>?> publishDocument(String id) async {
    final response = await _dio.post('/legal-documents/admin/$id/publish');
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return null;
  }

  /// Soft delete a document
  Future<bool> deleteDocument(String id) async {
    final response = await _dio.delete('/legal-documents/admin/$id');
    final parsed = ResponseParser.parse(response);
    if (parsed is Map && parsed['success'] == true) {
      return true;
    }
    return true;
  }

  /// Get acceptance metrics and role breakdown
  Future<Map<String, dynamic>?> getDocumentStats(String id) async {
    final response = await _dio.get('/legal-documents/admin/$id/stats');
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      return Map<String, dynamic>.from(parsed);
    }
    return null;
  }
}
