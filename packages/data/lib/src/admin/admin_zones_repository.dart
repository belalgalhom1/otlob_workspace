import 'package:api/api.dart';
import '../shared/response_parser.dart';

import 'package:dio/dio.dart';

class AdminZonesRepository {
  final LogisticsZonesApi _api;
  final Dio? _dio;
  AdminZonesRepository(this._api, {Dio? dio}) : _dio = dio;

  Future<List<dynamic>> getZones() async {
    final response = await _api.zonesControllerFindAll();
    return ResponseParser.parseList(response);
  }

  Future<dynamic> zonesUpdate({required String id, required UpdateZoneDto updateZoneDto}) async {
    final response = await _api.zonesControllerUpdate(id: id, updateZoneDto: updateZoneDto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> zonesRemove({required String id}) async {
    final response = await _api.zonesControllerRemove(id: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> zonesFindOne({required String id}) async {
    final response = await _api.zonesControllerFindOne(id: id);
    return ResponseParser.parse(response);
  }

  Future<dynamic> zonesCheckLocation({required CheckLocationDto checkLocationDto}) async {
    final response = await _api.zonesControllerCheckLocation(checkLocationDto: checkLocationDto);
    return ResponseParser.parse(response);
  }

  Future<dynamic> zonesCreate({required CreateZoneDto createZoneDto}) async {
    final response = await _api.zonesControllerCreate(createZoneDto: createZoneDto);
    return ResponseParser.parse(response);
  }
  Future<dynamic> zonesCreateRaw(Map<String, dynamic> data) async {
    if (_dio != null) {
      final response = await _dio.post('/zones', data: data);
      // Fallback response parser logic since we bypass generated API
      return response.data['data'] ?? response.data;
    }
    throw Exception('Dio is not configured for raw requests');
  }

  Future<dynamic> zonesUpdateRaw(String id, Map<String, dynamic> data) async {
    if (_dio != null) {
      final response = await _dio.patch('/zones/$id', data: data);
      return response.data['data'] ?? response.data;
    }
    throw Exception('Dio is not configured for raw requests');
  }

  Future<dynamic> searchCustomersInPolygon(List<dynamic> polygon) async {
    if (_dio != null) {
      final response = await _dio.post('/zones/customers/search', data: {
        'polygon': polygon,
      });
      return response.data['data'] ?? response.data;
    }
    throw Exception('Dio is not configured for raw requests');
  }
}