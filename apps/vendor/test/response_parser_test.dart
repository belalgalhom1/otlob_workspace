import 'package:flutter_test/flutter_test.dart';
import 'package:api/api.dart';
import 'package:built_value/json_object.dart';
import 'package:dio/dio.dart';
import 'package:data/data.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('Test ResponseParser with BuiltValue', () {
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
    expect(result, isA<Map<String, dynamic>>());
  });

  test('Test ResponseParser with Raw Dio Map - List', () {
    final rawDio = {
      'success': true,
      'statusCode': 200,
      'message': 'Operation successful',
      'data': [
        {'id': 'cat_1', 'name': 'Sweets'},
        {'id': 'cat_2', 'name': 'Ice Cream'}
      ],
      'timestamp': '2026-10-24T19:50:00Z',
    };

    final response = Response(data: rawDio, requestOptions: RequestOptions(path: '/'));
    final parsed = ResponseParser.parse(response);
    final parsedList = ResponseParser.parseList(response);

    expect(parsed, isA<List>());
    expect((parsed as List).length, 2);
    expect(parsed[0]['name'], 'Sweets');

    expect(parsedList, isA<List>());
    expect((parsedList as List).length, 2);
    expect(parsedList[1]['name'], 'Ice Cream');
  });

  test('Test ResponseParser with Raw Dio Map - Object', () {
    final rawDio = {
      'success': true,
      'statusCode': 200,
      'message': 'Operation successful',
      'data': {
        'id': 'v_1',
        'storeName': 'Blaban Mansoura',
      },
      'timestamp': '2026-10-24T19:50:00Z',
    };

    final response = Response(data: rawDio, requestOptions: RequestOptions(path: '/'));
    final parsed = ResponseParser.parse(response);

    expect(parsed, isA<Map>());
    expect((parsed as Map)['storeName'], 'Blaban Mansoura');
  });
}
