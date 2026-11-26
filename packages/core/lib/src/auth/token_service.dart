import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:api/api.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Coordinates token refresh calls across [AuthInterceptor] and [TokenService]
/// so concurrent refreshes share a single in-flight `/auth/refresh` request
/// instead of colliding on backend single-use refresh token rotation.
class AuthRefreshCoordinator {
  AuthRefreshCoordinator._();

  static Completer<String>? _completer;

  static bool get isRefreshing => _completer != null;

  static Future<String?> waitForInFlight(Duration timeout) async {
    final existing = _completer;
    if (existing == null) return null;
    return existing.future.timeout(timeout);
  }

  static Future<String> run(Future<String> Function() action) async {
    final existing = _completer;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<String>();
    _completer = completer;
    try {
      final token = await action();
      if (!completer.isCompleted) {
        completer.complete(token);
      }
      return token;
    } catch (e, st) {
      if (!completer.isCompleted) {
        completer.future.ignore();
        completer.completeError(e, st);
      }
      rethrow;
    } finally {
      if (identical(_completer, completer)) {
        _completer = null;
      }
    }
  }
}

/// Shared helper for resilient [FlutterSecureStorage] reads and writes on iOS/macOS Keychain.
class SecureStorageHelper {
  const SecureStorageHelper._();

  static bool _isDuplicateItemError(PlatformException e) {
    final text = '${e.code} ${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
    return text.contains('-25299') ||
        text.contains('duplicate') ||
        text.contains('already exists');
  }

  /// Writes [value] for [key], recovering from Keychain attribute conflicts (-25299)
  /// and surfacing a canonical error key if Keychain access is unavailable (-34018).
  static Future<void> writeSafely(
    FlutterSecureStorage storage,
    String key,
    String value,
  ) async {
    try {
      await storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      debugPrint(
        'SecureStorageHelper.writeSafely error for "$key": '
        'code=${e.code}, message=${e.message}, details=${e.details}',
      );
      if (_isDuplicateItemError(e)) {
        try {
          await storage.delete(key: key);
          await storage.write(key: key, value: value);
          return;
        } on PlatformException catch (retryError) {
          debugPrint(
            'SecureStorageHelper.writeSafely retry failed for "$key": '
            'code=${retryError.code}, message=${retryError.message}',
          );
        }
      }
      throw Exception('auth.error.secure_storage_unavailable');
    }
  }

  /// Reads [key] from [storage], returning `null` if Keychain access fails cleanly.
  static Future<String?> readSafely(
    FlutterSecureStorage storage,
    String key,
  ) async {
    try {
      return await storage.read(key: key);
    } on PlatformException catch (e) {
      debugPrint(
        'SecureStorageHelper.readSafely error for "$key": '
        'code=${e.code}, message=${e.message}, details=${e.details}',
      );
      return null;
    }
  }

  /// Deletes [key] from [storage], swallowing Keychain [PlatformException]s so
  /// session teardown / logout never aborts mid-cleanup.
  static Future<void> deleteSafely(
    FlutterSecureStorage storage,
    String key,
  ) async {
    try {
      await storage.delete(key: key);
    } on PlatformException catch (e) {
      debugPrint(
        'SecureStorageHelper.deleteSafely error for "$key": '
        'code=${e.code}, message=${e.message}, details=${e.details}',
      );
    }
  }
}

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
    String? email,
    String? phone,
    String? avatar,
    List<dynamic>? vendorMemberships,
    List<dynamic>? permissions,
  }) async {
    if (accessToken.trim().isEmpty || refreshToken.trim().isEmpty) {
      throw Exception('auth.error.invalid_credentials');
    }
    // Persist refresh_token before access_token so any concurrent request that
    // reads the new access_token is guaranteed to also see its refresh_token.
    await SecureStorageHelper.writeSafely(_storage, 'refresh_token', refreshToken);
    await SecureStorageHelper.writeSafely(_storage, 'access_token', accessToken);

    // Confirm tokens can actually be read back from secure storage before
    // persisting profile metadata or establishing an authenticated session.
    final persistedAccess =
        await SecureStorageHelper.readSafely(_storage, 'access_token');
    final persistedRefresh =
        await SecureStorageHelper.readSafely(_storage, 'refresh_token');
    if (persistedAccess == null ||
        persistedAccess.isEmpty ||
        persistedRefresh == null ||
        persistedRefresh.isEmpty) {
      await clearSession();
      throw Exception('auth.error.secure_storage_unavailable');
    }

    if (userId != null) {
      await SecureStorageHelper.writeSafely(_storage, 'user_id', userId);
    }
    if (role != null) {
      await SecureStorageHelper.writeSafely(_storage, 'user_role', role);
    }
    if (name != null) {
      await SecureStorageHelper.writeSafely(_storage, 'user_name', name);
    }
    if (email != null && email.isNotEmpty) {
      await SecureStorageHelper.writeSafely(_storage, 'user_email', email);
    }
    if (phone != null && phone.isNotEmpty) {
      await SecureStorageHelper.writeSafely(_storage, 'user_phone', phone);
    }
    if (avatar != null && avatar.isNotEmpty) {
      await SecureStorageHelper.writeSafely(_storage, 'user_avatar', avatar);
    }
    if (vendorMemberships != null) {
      await SecureStorageHelper.writeSafely(
        _storage,
        'vendor_memberships',
        jsonEncode(vendorMemberships),
      );
    }
    if (permissions != null) {
      await SecureStorageHelper.writeSafely(
        _storage,
        'user_permissions',
        jsonEncode(permissions),
      );
    }
  }

  static const authStorageKeys = [
    'access_token',
    'refresh_token',
    'user_id',
    'user_role',
    'user_name',
    'user_email',
    'user_phone',
    'user_avatar',
    'vendor_memberships',
    'user_permissions',
  ];

  Future<void> clearSession() async {
    for (final key in authStorageKeys) {
      await SecureStorageHelper.deleteSafely(_storage, key);
    }
  }

  Future<bool> hasSession() async {
    final access = await SecureStorageHelper.readSafely(_storage, 'access_token');
    final refresh = await SecureStorageHelper.readSafely(_storage, 'refresh_token');
    return access != null &&
        access.isNotEmpty &&
        refresh != null &&
        refresh.isNotEmpty;
  }

  Future<String?> getUserId() async {
    return SecureStorageHelper.readSafely(_storage, 'user_id');
  }

  Future<String?> getUserRole() async {
    return SecureStorageHelper.readSafely(_storage, 'user_role');
  }

  Future<String?> getUserName() async {
    return SecureStorageHelper.readSafely(_storage, 'user_name');
  }

  Future<List<dynamic>> getVendorMemberships() async {
    final str = await SecureStorageHelper.readSafely(_storage, 'vendor_memberships');
    if (str != null) {
      try {
        return jsonDecode(str) as List<dynamic>;
      } catch (_) {}
    }
    return [];
  }

  Future<List<String>> getUserPermissions() async {
    final str = await SecureStorageHelper.readSafely(_storage, 'user_permissions');
    if (str != null) {
      try {
        final list = jsonDecode(str) as List<dynamic>;
        return list.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<bool> isTokenExpired() async {
    final token = await SecureStorageHelper.readSafely(_storage, 'access_token');
    if (token == null || token.isEmpty) return true;
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  Future<bool> isRefreshTokenExpired() async {
    final token = await SecureStorageHelper.readSafely(_storage, 'refresh_token');
    if (token == null || token.isEmpty) return true;
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  Future<String> refreshToken() {
    return AuthRefreshCoordinator.run(() async {
      try {
        final refreshToken =
            await SecureStorageHelper.readSafely(_storage, 'refresh_token');
        if (refreshToken == null || refreshToken.isEmpty) {
          throw 'NO_REFRESH_TOKEN';
        }

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
          final rawUser = data['user'];
          final user = rawUser is Map<String, dynamic>
              ? rawUser
              : rawUser is Map
                  ? Map<String, dynamic>.from(rawUser)
                  : null;

          if (newAccessToken is! String ||
              newAccessToken.isEmpty ||
              newRefreshToken is! String ||
              newRefreshToken.isEmpty) {
            throw 'REFRESH_FAILED';
          }

          await SecureStorageHelper.writeSafely(
            _storage,
            'access_token',
            newAccessToken,
          );
          await SecureStorageHelper.writeSafely(
            _storage,
            'refresh_token',
            newRefreshToken,
          );

          if (user != null) {
            if (user['role'] != null) {
              await SecureStorageHelper.writeSafely(
                _storage,
                'user_role',
                user['role'].toString(),
              );
            }
            if (user['name'] != null) {
              await SecureStorageHelper.writeSafely(
                _storage,
                'user_name',
                user['name'].toString(),
              );
            }
            if (user['permissions'] != null) {
              await SecureStorageHelper.writeSafely(
                _storage,
                'user_permissions',
                jsonEncode(user['permissions']),
              );
            }
          }

          return newAccessToken;
        }
        throw 'REFRESH_FAILED';
      } catch (e) {
        debugPrint('TokenService refreshToken error: $e');
        rethrow;
      }
    });
  }
}
