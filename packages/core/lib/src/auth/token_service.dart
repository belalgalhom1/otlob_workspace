import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:api/api.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenService {
  final Api _apiClient;
  final FlutterSecureStorage _storage;

  TokenService(this._apiClient, this._storage);

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? role,
    String? name,
    List<dynamic>? vendorMemberships,
    List<dynamic>? permissions,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    if (userId != null) await _storage.write(key: 'user_id', value: userId);
    if (role != null) await _storage.write(key: 'user_role', value: role);
    if (name != null) await _storage.write(key: 'user_name', value: name);
    if (vendorMemberships != null) {
      await _storage.write(key: 'vendor_memberships', value: jsonEncode(vendorMemberships));
    }
    if (permissions != null) {
      await _storage.write(key: 'user_permissions', value: jsonEncode(permissions));
    }
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  Future<bool> hasSession() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: 'user_name');
  }

  Future<List<dynamic>> getVendorMemberships() async {
    final str = await _storage.read(key: 'vendor_memberships');
    if (str != null) {
      try {
        return jsonDecode(str) as List<dynamic>;
      } catch (_) {}
    }
    return [];
  }

  Future<List<String>> getUserPermissions() async {
    final str = await _storage.read(key: 'user_permissions');
    if (str != null) {
      try {
        final list = jsonDecode(str) as List<dynamic>;
        return list.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<bool> isTokenExpired() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return true;
    return JwtDecoder.isExpired(token);
  }

  Future<String> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) throw 'NO_REFRESH_TOKEN';

      final response = await _apiClient
          .getAuthenticationApi()
          .authControllerRefreshTokens(
            headers: {'Authorization': 'Bearer $refreshToken'},
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic responseData = (response as dynamic).data;
        Map<String, dynamic> data = {};

        if (responseData is Map) {
          data = (responseData['data'] as Map<String, dynamic>?) ?? {};
        } else if (responseData != null && responseData.data != null) {
          final payload = responseData.data!.value;
          if (payload is Map) {
            data = Map<String, dynamic>.from(payload);
          }
        }

        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        await _storage.write(key: 'access_token', value: newAccessToken);
        await _storage.write(key: 'refresh_token', value: newRefreshToken);

        return newAccessToken;
      }
      throw 'REFRESH_FAILED';
    } catch (e) {
      print('TokenService refreshToken error: $e');
      rethrow;
    }
  }
}
