import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test/test.dart';

class _InMemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

class _StubAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  _StubAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      onFetch(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AuthInterceptor stale/unauthenticated 401 protection', () {
    late _InMemorySecureStorage storage;
    late Dio dio;
    late List<void> unauthEvents;
    late StreamSubscription<void> unauthSub;

    setUp(() {
      storage = _InMemorySecureStorage();
      dio = Dio(BaseOptions(baseUrl: 'https://api.otlob.test'));
      dio.interceptors.add(AuthInterceptor(dio, storage));
      unauthEvents = [];
      unauthSub = unauthenticatedEventStream.stream.listen(unauthEvents.add);
    });

    tearDown(() async {
      await unauthSub.cancel();
    });

    test(
      '401 on an unauthenticated request does not clear newly saved session or emit logout event',
      () async {
        // Request starts before login (no tokens in storage), and login finishes
        // before the 401 response comes back.
        dio.httpClientAdapter = _StubAdapter((options) async {
          storage.values['access_token'] = 'fresh-access-token';
          storage.values['refresh_token'] = 'fresh-refresh-token';
          return ResponseBody.fromString(
            '{"message":"common.error.unauthorized"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        await expectLater(
          () => dio.post('/devices', data: {'token': 'fcm-1'}),
          throwsA(isA<DioException>()),
        );
        await Future<void>.delayed(Duration.zero);

        expect(unauthEvents, isEmpty);
        expect(storage.values['access_token'], 'fresh-access-token');
        expect(storage.values['refresh_token'], 'fresh-refresh-token');
      },
    );

    test(
      '401 on a request carrying a stale token retries with the newly logged-in token without logging out',
      () async {
        storage.values['access_token'] = 'old-access-token';
        storage.values['refresh_token'] = 'old-refresh-token';
        final seenAuthHeaders = <String?>[];

        dio.httpClientAdapter = _StubAdapter((options) async {
          final authHeader = options.headers['Authorization']?.toString();
          seenAuthHeaders.add(authHeader);
          if (authHeader == 'Bearer old-access-token') {
            // Simulate user completing a fresh login before this stale 401 returns.
            storage.values['access_token'] = 'new-access-token';
            storage.values['refresh_token'] = 'new-refresh-token';
            return ResponseBody.fromString(
              '{"message":"auth.error.session_expired"}',
              401,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString(
            '{"data":{"status":"OFFLINE"}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final response = await dio.get('/drivers/me');
        await Future<void>.delayed(Duration.zero);

        expect(response.statusCode, 200);
        expect(seenAuthHeaders, [
          'Bearer old-access-token',
          'Bearer new-access-token',
        ]);
        expect(unauthEvents, isEmpty);
        expect(storage.values['access_token'], 'new-access-token');
      },
    );

    test(
      '401 on a stale DELETE /devices/:token call never clears or retries under a fresh login',
      () async {
        storage.values['access_token'] = 'old-access-token';
        storage.values['refresh_token'] = 'old-refresh-token';
        var calls = 0;

        dio.httpClientAdapter = _StubAdapter((options) async {
          calls++;
          storage.values['access_token'] = 'new-access-token';
          storage.values['refresh_token'] = 'new-refresh-token';
          return ResponseBody.fromString(
            '{"message":"auth.error.session_expired"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        await expectLater(
          () => dio.delete('/devices/fcm-token-old'),
          throwsA(isA<DioException>()),
        );
        await Future<void>.delayed(Duration.zero);

        expect(calls, 1);
        expect(unauthEvents, isEmpty);
        expect(storage.values['access_token'], 'new-access-token');
      },
    );
  });
}
