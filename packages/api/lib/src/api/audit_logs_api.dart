//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:api/src/api_util.dart';
import 'package:api/src/model/audit_logs_controller_find_all200_response.dart';

class AuditLogsApi {

  final Dio _dio;

  final Serializers _serializers;

  const AuditLogsApi(this._dio, this._serializers);

  /// List audit logs with pagination and filters
  /// 
  ///
  /// Parameters:
  /// * [page] 
  /// * [limit] 
  /// * [userId] 
  /// * [vendorId] 
  /// * [entityType] 
  /// * [entityId] 
  /// * [actionType] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AuditLogsControllerFindAll200Response] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AuditLogsControllerFindAll200Response>> auditLogsControllerFindAll({ 
    num? page,
    num? limit,
    String? userId,
    String? vendorId,
    String? entityType,
    String? entityId,
    String? actionType,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/audit-logs';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearer',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      if (page != null) r'page': encodeQueryParameter(_serializers, page, const FullType(num)),
      if (limit != null) r'limit': encodeQueryParameter(_serializers, limit, const FullType(num)),
      if (userId != null) r'userId': encodeQueryParameter(_serializers, userId, const FullType(String)),
      if (vendorId != null) r'vendorId': encodeQueryParameter(_serializers, vendorId, const FullType(String)),
      if (entityType != null) r'entityType': encodeQueryParameter(_serializers, entityType, const FullType(String)),
      if (entityId != null) r'entityId': encodeQueryParameter(_serializers, entityId, const FullType(String)),
      if (actionType != null) r'actionType': encodeQueryParameter(_serializers, actionType, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    AuditLogsControllerFindAll200Response? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(AuditLogsControllerFindAll200Response),
      ) as AuditLogsControllerFindAll200Response;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AuditLogsControllerFindAll200Response>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
