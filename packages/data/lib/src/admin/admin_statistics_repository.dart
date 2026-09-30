import 'package:api/api.dart';
import 'package:dio/dio.dart';
import '../shared/response_parser.dart';

class AdminStatisticsRepository {
  final StatisticsApi _api;
  final Dio? _dio;

  AdminStatisticsRepository(this._api, {Dio? dio}) : _dio = dio;

  Future<dynamic> getAppStats({
    String? period,
    int? limit = 30,
    DateTime? from,
    DateTime? to,
  }) async {
    final dio = _dio;
    if (dio != null) {
      final response = await dio.get<dynamic>(
        '/statistics/app',
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
    final response = await _api.statisticsControllerGetAppStats();
    return ResponseParser.parse(response);
  }

  Future<dynamic> statisticsGetDriverStats({
    required String driverId,
    String? period,
    int? limit = 30,
    DateTime? from,
    DateTime? to,
  }) async {
    final dio = _dio;
    if (dio != null) {
      final response = await dio.get<dynamic>(
        '/statistics/drivers/$driverId',
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
    final response =
        await _api.statisticsControllerGetDriverStats(driverId: driverId);
    return ResponseParser.parse(response);
  }

  Future<dynamic> getVendorStats(
    String vendorId, {
    String? period,
    int? limit = 30,
    DateTime? from,
    DateTime? to,
  }) async {
    final dio = _dio;
    if (dio != null) {
      final response = await dio.get<dynamic>(
        '/statistics/vendors/$vendorId',
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
    final response = await _api.statisticsControllerGetVendorStats(
      vendorId: vendorId,
      period: period,
    );
    return ResponseParser.parse(response);
  }

  Future<dynamic> getMostOrderedProduct(String vendorId) async {
    final response = await _api.statisticsControllerGetMostOrderedProduct(
      vendorId: vendorId,
    );
    return ResponseParser.parse(response);
  }

  static String _dateParam(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

}