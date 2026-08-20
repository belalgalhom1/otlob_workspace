import 'package:dio/dio.dart';
import '../models/analytics_models.dart';

class AnalyticsRepository {
  final Dio _dio;

  AnalyticsRepository(this._dio);

  Future<List<AnalyticsDriver>> getTopDrivers({int limit = 20}) async {
    final response = await _dio.get('/statistics/analytics/drivers', queryParameters: {'limit': limit});
    final data = response.data['data'] as List;
    return data.map((e) => AnalyticsDriver.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AnalyticsCustomer>> getTopCustomers({int limit = 20}) async {
    final response = await _dio.get('/statistics/analytics/customers', queryParameters: {'limit': limit});
    final data = response.data['data'] as List;
    return data.map((e) => AnalyticsCustomer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AnalyticsVendor>> getTopVendors({int limit = 20}) async {
    final response = await _dio.get('/statistics/analytics/vendors', queryParameters: {'limit': limit});
    final data = response.data['data'] as List;
    return data.map((e) => AnalyticsVendor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AnalyticsTopProduct>> getTopProducts({int limit = 20}) async {
    final response = await _dio.get('/statistics/analytics/products', queryParameters: {'limit': limit});
    final data = response.data['data'] as List;
    return data.map((e) => AnalyticsTopProduct.fromJson(e as Map<String, dynamic>)).toList();
  }
}
