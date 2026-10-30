import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('403 only_drivers_app_allowed maps to a translatable key', () {
    final body = {
      'success': false,
      'statusCode': 403,
      'message': 'auth.error.only_drivers_app_allowed',
      'data': null,
      'errors': null,
      'timestamp': '2026-10-06T04:39:33.126Z',
    };
    final exception = DioException(
      requestOptions: RequestOptions(path: '/auth/social'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/social'),
        statusCode: 403,
        data: body,
      ),
      type: DioExceptionType.badResponse,
    );

    final key = ApiErrorMapper.fromError(exception);
    debugPrint('mapped key: $key');
    expect(key, 'auth_error_only_drivers_app_allowed');
  });

  test('key resolves in both locale catalogs', () {
    for (final locale in ['en', 'ar']) {
      final p1 = '../../packages/core/assets/translations/$locale.json';
      final p2 = 'packages/core/assets/translations/$locale.json';
      final file = File(File(p1).existsSync() ? p1 : p2);
      final raw = file.readAsStringSync();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final value = map['auth_error_only_drivers_app_allowed'];
      debugPrint('$locale: $value');
      expect(value, isNotNull);
      expect(value.toString(), isNot('auth_error_only_drivers_app_allowed'));
    }
  });
}
