import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/token_service.dart';

final StreamController<void> unauthenticatedEventStream =
    StreamController<void>.broadcast();

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._dio, this._storage);

  static const _refreshWaitTimeout = Duration(seconds: 20);

  Future<void> _clearAuthData() async {
    for (final key in TokenService.authStorageKeys) {
      await SecureStorageHelper.deleteSafely(_storage, key);
    }
  }

  bool _isGuestAuthPath(String path) {
    if (path == '/auth/login' ||
        path == '/auth/refresh' ||
        path == '/auth/register' ||
        path == '/auth/social' ||
        path.startsWith('/auth/verify/') ||
        path.startsWith('/auth/password/')) {
      return true;
    }
    return false;
  }

  /// 401s on these endpoints must never re-arm the refresh/stream cycle.
  /// `/auth/logout` is called when auth data was already cleared, so retrying
  /// it just re-emits the unauthenticated event and loops back into logout.
  bool _isTerminalAuthPath(String path) => path == '/auth/logout';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Public or guest/public auth endpoints should never have access token attached
    final requiresAuth = options.extra['requiresAuth'] ?? true;
    if (requiresAuth == false || _isGuestAuthPath(options.path)) {
      return handler.next(options);
    }

    // If a refresh is actively running (from AuthInterceptor or TokenService),
    // await the new token to avoid doomed 401s.
    if (AuthRefreshCoordinator.isRefreshing) {
      try {
        final newToken =
            await AuthRefreshCoordinator.waitForInFlight(_refreshWaitTimeout);
        if (newToken != null && newToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $newToken';
          return handler.next(options);
        }
      } catch (_) {
        // Fall through to whatever token is currently persisted safely.
      }
    }

    final token =
        await SecureStorageHelper.readSafely(_storage, 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requiresAuth = err.requestOptions.extra['requiresAuth'] ?? true;
    if (err.response?.statusCode == 401 &&
        requiresAuth != false &&
        !_isGuestAuthPath(err.requestOptions.path) &&
        !_isTerminalAuthPath(err.requestOptions.path)) {
      // Don't retry if already retried
      if (err.requestOptions.extra['retried'] == true) {
        return handler.next(err);
      }

      String? refreshedToken;
      try {
        refreshedToken = await AuthRefreshCoordinator.run(() async {
          final refreshToken =
              await SecureStorageHelper.readSafely(_storage, 'refresh_token');
          if (refreshToken == null || refreshToken.isEmpty) {
            await _clearAuthData();
            unauthenticatedEventStream.add(null);
            throw err;
          }

          final refreshDio = Dio(
            BaseOptions(
              baseUrl: _dio.options.baseUrl,
              connectTimeout: _refreshWaitTimeout,
              receiveTimeout: _refreshWaitTimeout,
            ),
          );
          refreshDio.options.headers['Authorization'] = 'Bearer $refreshToken';

          final response = await refreshDio.post('/auth/refresh');
          if (response.statusCode == 200 || response.statusCode == 201) {
            final body = response.data;
            Map<String, dynamic> data = const {};
            if (body is Map<String, dynamic>) {
              final raw = body['data'];
              if (raw is Map<String, dynamic>) {
                data = raw;
              } else if (raw is Map) {
                data = Map<String, dynamic>.from(raw);
              }
            } else if (body is Map) {
              final raw = body['data'];
              if (raw is Map) {
                data = Map<String, dynamic>.from(raw);
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

            if (newAccessToken is! String || newAccessToken.isEmpty) {
              throw DioException(
                requestOptions: err.requestOptions,
                response: response,
              );
            }

            await SecureStorageHelper.writeSafely(
              _storage,
              'access_token',
              newAccessToken,
            );
            if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
              await SecureStorageHelper.writeSafely(
                _storage,
                'refresh_token',
                newRefreshToken,
              );
            }

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
          throw DioException(
            requestOptions: err.requestOptions,
            response: response,
          );
        }).timeout(_refreshWaitTimeout);
      } catch (e) {
        // Only clear auth data if refresh token is genuinely invalid (401/403).
        if (e is DioException &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          await _clearAuthData();
          unauthenticatedEventStream.add(null);
        }
        return handler.next(err);
      }

      // Retry current request with new token outside the refresh block so a
      // 403/404 on the target business endpoint does not clear auth tokens.
      try {
        final requestOptions = err.requestOptions;
        requestOptions.extra['retried'] = true;
        final latestToken = refreshedToken.isNotEmpty
            ? refreshedToken
            : await SecureStorageHelper.readSafely(_storage, 'access_token');
        if (latestToken != null && latestToken.isNotEmpty) {
          requestOptions.headers['Authorization'] = 'Bearer $latestToken';
          final retryResponse = await _dio.fetch(requestOptions);
          return handler.resolve(retryResponse);
        }
      } catch (retryErr) {
        if (retryErr is DioException) {
          return handler.next(retryErr);
        }
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
