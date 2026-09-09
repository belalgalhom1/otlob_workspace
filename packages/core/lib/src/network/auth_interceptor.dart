import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final StreamController<void> unauthenticatedEventStream =
    StreamController<void>.broadcast();

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  Completer<String?>? _refreshCompleter;

  AuthInterceptor(this._dio, this._storage);

  static const _authStorageKeys = [
    'access_token',
    'refresh_token',
    'user_id',
    'user_role',
    'user_name',
    'vendor_memberships',
    'user_permissions',
  ];

  Future<void> _clearAuthData() async {
    for (final key in _authStorageKeys) {
      await _storage.delete(key: key);
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

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Guest/public auth endpoints should never have access token attached
    if (_isGuestAuthPath(options.path)) {
      return handler.next(options);
    }

    // If a refresh is actively running, await the new token to avoid doomed 401s
    if (_refreshCompleter != null) {
      try {
        final newToken = await _refreshCompleter!.future;
        if (newToken != null) {
          options.headers['Authorization'] = 'Bearer $newToken';
        }
        return handler.next(options);
      } catch (_) {
        return handler.next(options);
      }
    }

    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        !_isGuestAuthPath(err.requestOptions.path)) {
      // Don't retry if already retried
      if (err.requestOptions.extra['retried'] == true) {
        return handler.next(err);
      }

      // If another request is already refreshing, wait on its completer
      if (_refreshCompleter != null) {
        try {
          final newToken = await _refreshCompleter!.future;
          if (newToken != null) {
            final requestOptions = err.requestOptions;
            requestOptions.extra['retried'] = true;
            requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final response = await _dio.fetch(requestOptions);
            return handler.resolve(response);
          }
        } catch (_) {
          return handler.next(err);
        }
      }

      // Begin refresh mutex queue
      final completer = Completer<String?>();
      _refreshCompleter = completer;

      try {
        final refreshToken = await _storage.read(key: 'refresh_token');
        if (refreshToken == null) {
          await _clearAuthData();
          unauthenticatedEventStream.add(null);
          completer.completeError(err);
          _refreshCompleter = null;
          return handler.next(err);
        }

        final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
        refreshDio.options.headers['Authorization'] = 'Bearer $refreshToken';

        final response = await refreshDio.post('/auth/refresh');
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseMap = response.data as Map<String, dynamic>;
          final data = responseMap['data'] as Map<String, dynamic>;
          final newAccessToken = data['access_token'] as String?;
          final newRefreshToken = data['refresh_token'] as String?;
          final user = data['user'] as Map<String, dynamic>?;

          if (newAccessToken != null) {
            await _storage.write(key: 'access_token', value: newAccessToken);
          }
          if (newRefreshToken != null) {
            await _storage.write(key: 'refresh_token', value: newRefreshToken);
          }

          if (user != null) {
            if (user['role'] != null) {
              await _storage.write(
                key: 'user_role',
                value: user['role'].toString(),
              );
            }
            if (user['name'] != null) {
              await _storage.write(
                key: 'user_name',
                value: user['name'].toString(),
              );
            }
            if (user['permissions'] != null) {
              await _storage.write(
                key: 'user_permissions',
                value: jsonEncode(user['permissions']),
              );
            }
          }

          completer.complete(newAccessToken);
          _refreshCompleter = null;

          // Retry current request with new token
          final requestOptions = err.requestOptions;
          requestOptions.extra['retried'] = true;
          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await _dio.fetch(requestOptions);
          return handler.resolve(retryResponse);
        } else {
          throw DioException(
            requestOptions: err.requestOptions,
            response: response,
          );
        }
      } catch (e) {
        // Only clear auth data if refresh token is genuinely invalid
        if (e is DioException &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          await _clearAuthData();
          unauthenticatedEventStream.add(null);
        }

        completer.completeError(e);
        _refreshCompleter = null;
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
