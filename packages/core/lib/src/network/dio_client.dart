import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../debug/mv_debug_logger.dart';
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

    // Temporary Multi-Vendor Order File Trace Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_shouldTracePath(options.path)) {
            options.extra['_mvStartMs'] = DateTime.now().millisecondsSinceEpoch;
            MvDebugLogger.log(
              'HTTP_REQ',
              '${options.method} ${options.path}',
              data: {
                if (options.queryParameters.isNotEmpty)
                  'query': options.queryParameters,
                if (options.data != null)
                  'body': options.data is FormData
                      ? '<FormData fields=${(options.data as FormData).fields.length} files=${(options.data as FormData).files.length}>'
                      : options.data,
              },
            );
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final path = response.requestOptions.path;
          if (_shouldTracePath(path)) {
            final startMs = response.requestOptions.extra['_mvStartMs'] as int?;
            final elapsedMs = startMs != null
                ? DateTime.now().millisecondsSinceEpoch - startMs
                : null;
            MvDebugLogger.log(
              'HTTP_RES',
              '${response.requestOptions.method} $path -> ${response.statusCode}${elapsedMs != null ? " (${elapsedMs}ms)" : ""}',
              data: _summarizeHttpResponse(response.data),
            );
          }
          handler.next(response);
        },
        onError: (err, handler) {
          final path = err.requestOptions.path;
          if (_shouldTracePath(path)) {
            MvDebugLogger.log(
              'HTTP_ERR',
              '${err.requestOptions.method} $path -> ${err.response?.statusCode ?? err.type.name}',
              data: {
                'message': err.message,
                if (err.response?.data != null) 'errorBody': err.response?.data,
              },
            );
          }
          handler.next(err);
        },
      ),
    );

    // Add Auth Interceptor for JWT and Refresh Token Rotation
    _dio.interceptors.add(AuthInterceptor(_dio, secureStorage));
  }

  static bool _shouldTracePath(String path) {
    final p = path.toLowerCase();
    return p.contains('/orders') ||
        p.contains('/cart') ||
        p.contains('/vendor-decisions') ||
        p.contains('/dispatch') ||
        p.contains('/reviews');
  }

  static Map<String, dynamic> _summarizeHttpResponse(dynamic body) {
    if (body is! Map) {
      return {'raw': body};
    }
    final payload = body['data'] is Map ? body['data'] as Map : body;
    final summary = <String, dynamic>{};
    for (final key in const [
      'id',
      'orderNumber',
      'status',
      'paymentMethod',
      'paymentStatus',
      'subtotal',
      'deliveryFee',
      'serviceFee',
      'driverBonusFee',
      'driverBonusPaidByCustomer',
      'tax',
      'discount',
      'grandTotal',
      'total',
      'upfrontAmount',
      'activeDeliveryGroupId',
      'deliveryGroupsCount',
      'branchCount',
    ]) {
      if (payload.containsKey(key)) {
        summary[key] = payload[key];
      }
    }
    if (payload['vendorFulfillments'] is List) {
      summary['vendorFulfillments'] = (payload['vendorFulfillments'] as List)
          .whereType<Map>()
          .map(
            (f) => {
              'id': f['id'],
              'vendorId': f['vendorId'],
              'vendorBranchId': f['vendorBranchId'],
              'status': f['status'],
              'subtotal': f['subtotal'],
              'pickedUpAt': f['pickedUpAt'],
            },
          )
          .toList();
    }
    if (payload['deliveryGroups'] is List) {
      summary['deliveryGroups'] = (payload['deliveryGroups'] as List)
          .whereType<Map>()
          .map(
            (g) => {
              'id': g['id'],
              'sequence': g['sequence'],
              'status': g['status'],
              'primaryDriverId': g['primaryDriverId'],
              'deliveryFee': g['deliveryFee'],
              'isPaymentCollector': g['isPaymentCollector'],
              'items': (g['items'] is List)
                  ? (g['items'] as List)
                      .whereType<Map>()
                      .map(
                        (it) => {
                          'sequence': it['sequence'],
                          'fulfillmentId': it['fulfillmentId'],
                        },
                      )
                      .toList()
                  : null,
            },
          )
          .toList();
    }
    if (payload['financials'] is Map) {
      summary['financials'] = payload['financials'];
    }
    if (summary.isEmpty) {
      return Map<String, dynamic>.from(payload);
    }
    return summary;
  }

  Dio get dio => _dio;
}
