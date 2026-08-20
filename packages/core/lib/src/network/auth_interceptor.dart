import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final StreamController<void> unauthenticatedEventStream = StreamController<void>.broadcast();

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;
  final _requestsQueue = <Map<String, dynamic>>[];

  AuthInterceptor(this._dio, this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Don't add token for login or refresh requests
    if (options.path == '/auth/login' || options.path == '/auth/refresh') {
      return handler.next(options);
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
        err.requestOptions.path != '/auth/login' &&
        err.requestOptions.path != '/auth/refresh') {
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await _storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            // Use a separate dio instance or directly fetch to avoid loop
            final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
            refreshDio.options.headers['Authorization'] =
                'Bearer $refreshToken';

            final response = await refreshDio.post('/auth/refresh');
            if (response.statusCode == 200 || response.statusCode == 201) {
              final responseMap = response.data as Map<String, dynamic>;
              final data = responseMap['data'] as Map<String, dynamic>;
              final newAccessToken = data['access_token'];
              final newRefreshToken = data['refresh_token'];

              if (newAccessToken != null) {
                await _storage.write(
                  key: 'access_token',
                  value: newAccessToken,
                );
              }
              if (newRefreshToken != null) {
                await _storage.write(
                  key: 'refresh_token',
                  value: newRefreshToken,
                );
              }

              // Retry failed request
              err.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';

              // Process queued requests
              for (var request in _requestsQueue) {
                final options = request['options'] as RequestOptions;
                final requestHandler =
                    request['handler'] as ErrorInterceptorHandler;
                options.headers['Authorization'] = 'Bearer $newAccessToken';
                try {
                  final retryResponse = await _dio.fetch(options);
                  requestHandler.resolve(retryResponse);
                } catch (e) {
                  requestHandler.next(
                    e is DioException
                        ? e
                        : DioException(requestOptions: options, error: e),
                  );
                }
              }
              _requestsQueue.clear();

              _isRefreshing = false;

              // Retry current request
              final retryResponse = await _dio.fetch(err.requestOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (e) {
          print('AuthInterceptor Refresh Error: $e');

          for (var request in _requestsQueue) {
            final requestHandler =
                request['handler'] as ErrorInterceptorHandler;
            requestHandler.next(err);
          }
          _requestsQueue.clear();

          // Only clear tokens if the refresh token itself is definitely invalid (401/403)
          if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
            await _storage.deleteAll();
            unauthenticatedEventStream.add(null);
          }

          _isRefreshing = false;
          return handler.next(err);
        }

        // If we reach here, it means refreshToken was null or session is gone
        for (var request in _requestsQueue) {
          final requestHandler = request['handler'] as ErrorInterceptorHandler;
          requestHandler.next(err);
        }
        _requestsQueue.clear();

        await _storage.deleteAll();
        unauthenticatedEventStream.add(null);

        _isRefreshing = false;
        return handler.next(err);
      } else {
        // Queue this request while refreshing
        _requestsQueue.add({'options': err.requestOptions, 'handler': handler});
        return;
      }
    }

    return handler.next(err);
  }
}
