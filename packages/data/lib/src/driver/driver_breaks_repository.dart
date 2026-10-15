import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

/// Driver break sessions (backend `driver_break` feature).
///
/// The generated API client predates these endpoints, so everything here goes
/// through raw dio. Responses are envelope-wrapped
/// (`{success, message, data}`) — [parse] unwraps the inner `data` payload.
class DriverBreaksRepository {
  final Dio? _dio;
  DriverBreaksRepository({Dio? dio}) : _dio = dio;

  Dio get _client {
    final client = _dio;
    if (client == null) throw Exception('Dio is required');
    return client;
  }

  dynamic _parse(dynamic response) {
    final parsed = ResponseParser.parse(response);
    if (parsed is Map) {
      // Envelope ({success, message, data}) -> inner payload, which may
      // legitimately be null (e.g. no active break). A real break object
      // never carries envelope keys, so it passes through untouched.
      if (parsed.containsKey('success') || parsed.containsKey('data')) {
        return parsed['data'];
      }
      return parsed;
    }
    if (parsed is List) return parsed;
    return parsed;
  }

  // ─── Driver ───────────────────────────────────────────────────────────

  Future<dynamic> startBreak({
    String? reason,
    String? note,
    int? requestedMinutes,
  }) async {
    final response = await _client.post(
      '/drivers/me/break/start',
      data: {
        if (reason case final r?) 'reason': r,
        if (note case final n?) 'note': n,
        if (requestedMinutes case final m?) 'requestedMinutes': m,
      },
    );
    return _parse(response);
  }

  Future<dynamic> endBreak() async {
    final response = await _client.post('/drivers/me/break/end');
    return _parse(response);
  }

  Future<dynamic> cancelBreakRequest() async {
    final response = await _client.post('/drivers/me/break/cancel');
    return _parse(response);
  }

  Future<dynamic> getMyBreaks() async {
    final response = await _client.get('/drivers/me/breaks');
    return _parse(response);
  }

  Future<dynamic> getActiveBreak() async {
    final response = await _client.get('/drivers/me/break/active');
    return _parse(response);
  }

  // ─── Admin (MANAGE_DRIVERS) ───────────────────────────────────────────

  Future<dynamic> getPendingBreaks() async {
    final response = await _client.get('/drivers/breaks/pending');
    return _parse(response);
  }

  Future<dynamic> approveBreak(String breakId) async {
    final response = await _client.post('/drivers/breaks/$breakId/approve');
    return _parse(response);
  }

  Future<dynamic> rejectBreak(String breakId) async {
    final response = await _client.post('/drivers/breaks/$breakId/reject');
    return _parse(response);
  }

  Future<dynamic> forceEndBreak(String breakId) async {
    final response = await _client.post('/drivers/breaks/$breakId/end');
    return _parse(response);
  }

  Future<dynamic> grantBreak(
    String driverId, {
    String? reason,
    String? note,
    int? requestedMinutes,
  }) async {
    final response = await _client.post(
      '/drivers/$driverId/breaks/grant',
      data: {
        if (reason case final r?) 'reason': r,
        if (note case final n?) 'note': n,
        if (requestedMinutes case final m?) 'requestedMinutes': m,
      },
    );
    return _parse(response);
  }

  Future<dynamic> getDriverBreaks(String driverId) async {
    final response = await _client.get('/drivers/$driverId/breaks');
    return _parse(response);
  }

  /// PATCH platform settings with break keys only (the generated
  /// UpdatePlatformSettingsDto predates these fields).
  Future<dynamic> updateBreakSettings(Map<String, dynamic> data) async {
    final response = await _client.patch('/platform-settings', data: data);
    return _parse(response);
  }
}
