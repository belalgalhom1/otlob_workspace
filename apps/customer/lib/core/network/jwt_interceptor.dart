import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/providers.dart';
import 'package:core/core.dart' hide tokenServiceProvider;
import '../services/token_service.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';

class JwtInterceptor extends Interceptor {
  final Ref ref;
  final Dio dio;

  JwtInterceptor(this.ref, this.dio);

  Future<String?>? _refreshTokenFuture;

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
    final requiresAuth = options.extra['requiresAuth'] ?? true;
    if (!requiresAuth || _isGuestAuthPath(options.path)) {
      return handler.next(options);
    }

    final tokenService = ref.read(tokenServiceProvider);

    if (await tokenService.isAccessTokenExpired()) {
      await _refreshTokenIfNeeded();
    }

    final accessToken = await tokenService.getAccessToken();

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (is401 &&
        !alreadyRetried &&
        !_isGuestAuthPath(err.requestOptions.path)) {
      try {
        final newToken = await _refreshTokenIfNeeded();

        if (newToken != null) {
          final requestOptions = err.requestOptions;

          requestOptions.extra['retried'] = true;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';

          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {
        _handleLogout();
      }
    }

    return handler.next(err);
  }

  Future<String?> _refreshTokenIfNeeded() async {
    if (_refreshTokenFuture != null) {
      return await _refreshTokenFuture;
    }

    _refreshTokenFuture = _refresh();

    try {
      return await _refreshTokenFuture;
    } finally {
      _refreshTokenFuture = null;
    }
  }

  Future<String?> _refresh() async {
    try {
      final authRepository = ref.read(sharedAuthRepositoryProvider);

      return await authRepository.refreshToken();
    } catch (e) {
      _handleLogout();
      throw ApiErrorMapper.fromError(e);
    }
  }

  void _handleLogout() {
    ref.read(authControllerProvider.notifier).logout();
  }
}
