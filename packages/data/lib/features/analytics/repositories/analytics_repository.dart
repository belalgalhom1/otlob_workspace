import 'package:dio/dio.dart';
import '../models/analytics_models.dart';

class AnalyticsRepository {
  final Dio _dio;

  AnalyticsRepository(this._dio);

  Map<String, dynamic> _rangeParams(DateTime? from, DateTime? to) => {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      };

  Future<List<AnalyticsDriver>> getTopDrivers({
    int limit = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _dio.get('/statistics/analytics/drivers',
        queryParameters: {'limit': limit, ..._rangeParams(from, to)});
    final data = response.data['data'] as List;
    return data.map((e) => AnalyticsDriver.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AnalyticsCustomer>> getTopCustomers({
    int limit = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _dio.get('/statistics/analytics/customers',
        queryParameters: {'limit': limit, ..._rangeParams(from, to)});
    final data = response.data['data'] as List;
    return data.map((e) => AnalyticsCustomer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AnalyticsVendor>> getTopVendors({
    int limit = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _dio.get('/statistics/analytics/vendors',
        queryParameters: {'limit': limit, ..._rangeParams(from, to)});
    final data = response.data['data'] as List;
    return data.map((e) => AnalyticsVendor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AnalyticsTopProduct>> getTopProducts({
    int limit = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _dio.get('/statistics/analytics/products',
        queryParameters: {'limit': limit, ..._rangeParams(from, to)});
    final data = response.data['data'] as List;
    return data.map((e) => AnalyticsTopProduct.fromJson(e as Map<String, dynamic>)).toList();
  }
}
