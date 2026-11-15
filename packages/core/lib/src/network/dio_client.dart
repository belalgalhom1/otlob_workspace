import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_interceptor.dart';

class DioClient {
  final Dio _dio;

  DioClient(String baseUrl, FlutterSecureStorage secureStorage) 
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // Add logging in dev mode (stripped out in production)
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    // Add Auth Interceptor for JWT and Refresh Token Rotation
    _dio.interceptors.add(AuthInterceptor(_dio, secureStorage));
  }

  Dio get dio => _dio;
}
