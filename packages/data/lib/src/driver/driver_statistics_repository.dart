import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class DriverStatisticsRepository {
  final StatisticsApi _api;
  final Dio? _dio;
  DriverStatisticsRepository(this._api, {Dio? dio}) : _dio = dio;

  Future<dynamic> getMyDriverStats({
    String? period,
    int? limit = 30,
    DateTime? from,
    DateTime? to,
  }) async {
    final dio = _dio;
    if (dio != null) {
      final response = await dio.get<dynamic>(
        '/statistics/driver/me',
        queryParameters: {
          'period': ?period,
          'limit': ?limit,
          if (from != null) 'from': _dateParam(from),
          if (to != null) 'to': _dateParam(to),
        },
      );
      if (response.data is Map) {
        return (response.data as Map)['data'];
      }
      return response.data;
    }
    final response = await _api.statisticsControllerGetMyDriverStats();
    return ResponseParser.parse(response);
  }

  static String _dateParam(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }
}
