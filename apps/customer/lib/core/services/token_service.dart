import 'package:core/core.dart' show SecureStorageHelper;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../providers/secure_storage_provider.dart';

part 'token_service.g.dart';

@Riverpod(keepAlive: true)
TokenService tokenService(Ref ref) {
  final storage = ref.read(secureStorageProvider);
  return TokenService(storage);
}

class TokenService {
  final FlutterSecureStorage _storage;

  TokenService(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';
  static const _userPhoneKey = 'user_phone';
  static const _userAvatarKey = 'user_avatar';
  static const _savedEmailKey = 'saved_email';
  static const _savedPasswordKey = 'saved_password';
  static const _savedNameKey = 'saved_name';
  static const _savedRoleKey = 'saved_role';

  Future<String?> getAccessToken() async {
    return SecureStorageHelper.readSafely(_storage, _accessTokenKey);
  }

  Future<String?> getUserEmail() async {
    return SecureStorageHelper.readSafely(_storage, _userEmailKey);
  }

  Future<String?> getUserName() async {
    return SecureStorageHelper.readSafely(_storage, _userNameKey);
  }

  Future<String?> getUserPhone() async {
    return SecureStorageHelper.readSafely(_storage, _userPhoneKey);
  }

  Future<String?> getUserAvatar() async {
    return SecureStorageHelper.readSafely(_storage, _userAvatarKey);
  }

  Future<String?> getRefreshToken() async {
    return SecureStorageHelper.readSafely(_storage, _refreshTokenKey);
  }

  Future<Map<String, String?>> getTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();

    return {
      'access_token': access,
      'refresh_token': refresh,
    };
  }

  Future<void> saveAccessToken(String token) async {
    await SecureStorageHelper.writeSafely(_storage, _accessTokenKey, token);
  }

  Future<void> saveUserEmail(String email) async {
    await SecureStorageHelper.writeSafely(_storage, _userEmailKey, email);
  }

  Future<void> saveUserName(String name) async {
    await SecureStorageHelper.writeSafely(_storage, _userNameKey, name);
  }

  Future<void> saveUserPhone(String phone) async {
    await SecureStorageHelper.writeSafely(_storage, _userPhoneKey, phone);
  }

  Future<void> saveUserAvatar(String avatar) async {
    await SecureStorageHelper.writeSafely(_storage, _userAvatarKey, avatar);
  }

  Future<void> saveRefreshToken(String token) async {
    await SecureStorageHelper.writeSafely(_storage, _refreshTokenKey, token);
  }

  Future<void> saveSavedProfile({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    await SecureStorageHelper.writeSafely(_storage, _savedEmailKey, email);
    await SecureStorageHelper.writeSafely(_storage, _savedPasswordKey, password);
    await SecureStorageHelper.writeSafely(_storage, _savedNameKey, name);
    await SecureStorageHelper.writeSafely(_storage, _savedRoleKey, role);
  }

  Future<Map<String, String>?> getSavedProfile() async {
    final email = await SecureStorageHelper.readSafely(_storage, _savedEmailKey);
    final password = await SecureStorageHelper.readSafely(_storage, _savedPasswordKey);
    final name = await SecureStorageHelper.readSafely(_storage, _savedNameKey);
    final role = await SecureStorageHelper.readSafely(_storage, _savedRoleKey);

    if (email != null) {
      return {
        'email': email,
        'password': password ?? '',
        'name': name ?? '',
        'role': role ?? '',
      };
    }
    return null;
  }

  Future<void> deleteSavedProfile() async {
    await SecureStorageHelper.deleteSafely(_storage, _savedEmailKey);
    await SecureStorageHelper.deleteSafely(_storage, _savedPasswordKey);
    await SecureStorageHelper.deleteSafely(_storage, _savedNameKey);
    await SecureStorageHelper.deleteSafely(_storage, _savedRoleKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  Future<void> deleteAccessToken() async {
    await SecureStorageHelper.deleteSafely(_storage, _accessTokenKey);
  }

  Future<void> deleteUserEmail() async {
    await SecureStorageHelper.deleteSafely(_storage, _userEmailKey);
  }

  Future<void> deleteRefreshToken() async {
    await SecureStorageHelper.deleteSafely(_storage, _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    // Save these before deleting auth session keys
    final savedEmail = await SecureStorageHelper.readSafely(_storage, _savedEmailKey);
    final savedPassword = await SecureStorageHelper.readSafely(_storage, _savedPasswordKey);
    final savedName = await SecureStorageHelper.readSafely(_storage, _savedNameKey);
    final savedRole = await SecureStorageHelper.readSafely(_storage, _savedRoleKey);

    // Explicitly delete all session keys first so a deleteAll() failure
    // on iOS Keychain cannot leave access/refresh tokens behind.
    const sessionKeys = [
      _accessTokenKey,
      _refreshTokenKey,
      _userEmailKey,
      _userNameKey,
      _userPhoneKey,
      _userAvatarKey,
      'user_id',
      'user_role',
      'vendor_memberships',
      'user_permissions',
    ];
    for (final key in sessionKeys) {
      await SecureStorageHelper.deleteSafely(_storage, key);
    }

    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('TokenService.clearTokens deleteAll warning: $e');
    }

    // Restore saved profile if it existed
    if (savedEmail != null) {
      try {
        await saveSavedProfile(
          email: savedEmail,
          password: savedPassword ?? '',
          name: savedName ?? '',
          role: savedRole ?? '',
        );
      } catch (e) {
        debugPrint('TokenService.clearTokens restore savedProfile warning: $e');
      }
    }
  }

  Future<bool> isAccessTokenExpired() async {
    final access = await getAccessToken();

    if (access == null || access.isEmpty) return true;

    try {
      return JwtDecoder.isExpired(access);
    } catch (_) {
      return true;
    }
  }

  Future<String?> getUserId() async {
    final access = await getAccessToken();
    if (access == null) return null;
    try {
      final decodedToken = JwtDecoder.decode(access);
      return decodedToken['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isUserVerified() async {
    final access = await getAccessToken();
    if (access == null) return false;
    
    try {
      final decodedToken = JwtDecoder.decode(access);
      return decodedToken['verified'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasValidTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();

    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      return false;
    }

    try {
      if (JwtDecoder.isExpired(refresh)) {
        return false;
      }
    } catch (_) {
      return false;
    }

    return true;
  }
}

final accessTokenProvider = FutureProvider<String?>((ref) async {
  return ref.watch(tokenServiceProvider).getAccessToken();
});
