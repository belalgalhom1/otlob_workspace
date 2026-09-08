import 'package:flutter_test/flutter_test.dart';
import 'package:api/api.dart';
import 'package:built_value/json_object.dart';
import 'package:dio/dio.dart';
import 'package:data/data.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('Test ResponseParser', () {
    final res = ApiControllerRoot200Response((b) => b
      ..success = true
      ..statusCode = 200
      ..message = 'Test'
      ..timestamp = '2022'
      ..data = JsonObject({'users': [{'name': 'Otlob'}], 'total': 1})
    );

    final response = Response(data: res, requestOptions: RequestOptions(path: '/'));
    final result = ResponseParser.parseList(response);
    
    debugPrint('RESULT: $result');
    debugPrint('RESULT TYPE: ${result.runtimeType}');
    if (result is Map) {
      debugPrint('KEYS: ${result.keys}');
      debugPrint('USERS: ${result['users']}');
    }
  });
}
