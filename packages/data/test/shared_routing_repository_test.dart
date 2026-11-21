import 'dart:convert';
import 'dart:typed_data';

import 'package:api/api.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAdapter implements HttpClientAdapter {
  int calls = 0;
  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  _MockAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    calls++;
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _okJson(Map<String, dynamic> payload) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('SharedRoutingRepository', () {
    test('getOrderRoute deserializes backend road route via OrdersApi', () async {
      const roadPoints = [
        RoadRoutePoint(30.0444, 31.2357),
        RoadRoutePoint(30.0490, 31.2410),
        RoadRoutePoint(30.0550, 31.2480),
      ];
      final encoded = PolylineCodec.encode(roadPoints);

      final apiAdapter = _MockAdapter((options) async {
        expect(options.path, '/orders/ord-123/route');
        expect(options.method, 'GET');
        return _okJson({
          'success': true,
          'statusCode': 200,
          'message': 'OK',
          'timestamp': '2026-11-21T08:00:00Z',
          'data': {
            'orderId': 'ord-123',
            'orderStatus': 'DRIVER_ASSIGNED',
            'encodedPolyline': encoded,
            'coordinates': [
              {'latitude': 30.0444, 'longitude': 31.2357},
              {'latitude': 30.0490, 'longitude': 31.2410},
              {'latitude': 30.0550, 'longitude': 31.2480},
            ],
            'waypoints': [
              {'latitude': 30.0444, 'longitude': 31.2357},
              {'latitude': 30.0550, 'longitude': 31.2480},
            ],
            'distanceMeters': 1850,
            'durationSeconds': 240,
            'isRoadRoute': true,
            'source': 'osrm',
            'driverLocation': {'latitude': 30.0444, 'longitude': 31.2357},
            'destination': {'latitude': 30.0550, 'longitude': 31.2480},
          },
        });
      });

      final apiDio = Dio()..httpClientAdapter = apiAdapter;
      final repo = SharedRoutingRepository(
        OrdersApi(apiDio, standardSerializers),
      );

      final route = await repo.getOrderRoute(orderId: 'ord-123');
      expect(route.isRoadRoute, isTrue);
      expect(route.source, 'osrm');
      expect(route.points, hasLength(3));
      expect(route.distanceMeters, 1850);
      expect(route.durationSeconds, 240);
      expect(route.driverLocation, const RoadRoutePoint(30.0444, 31.2357));
      expect(route.destination, const RoadRoutePoint(30.0550, 31.2480));
    });

    test('falls back cleanly to client OSRM when backend returns fallback chord', () async {
      final apiAdapter = _MockAdapter((options) async {
        return _okJson({
          'success': true,
          'statusCode': 200,
          'message': 'OK',
          'timestamp': '2026-11-21T08:00:00Z',
          'data': {
            'orderId': 'ord-fb',
            'orderStatus': 'PENDING',
            'encodedPolyline': '',
            'coordinates': [
              {'latitude': 30.0700, 'longitude': 31.2700},
              {'latitude': 30.0800, 'longitude': 31.2800},
            ],
            'waypoints': [
              {'latitude': 30.0700, 'longitude': 31.2700},
              {'latitude': 30.0800, 'longitude': 31.2800},
            ],
            'distanceMeters': 1400,
            'durationSeconds': 0,
            'isRoadRoute': false,
            'source': 'fallback',
          },
        });
      });

      final externalAdapter = _MockAdapter((options) async {
        return _okJson({
          'code': 'Ok',
          'routes': [
            {
              'geometry': {
                'coordinates': [
                  [31.2700, 30.0700],
                  [31.2750, 30.0730],
                  [31.2780, 30.0770],
                  [31.2800, 30.0800],
                ],
              },
            },
          ],
        });
      });

      final repo = SharedRoutingRepository(
        OrdersApi(Dio()..httpClientAdapter = apiAdapter, standardSerializers),
        externalDio: Dio()..httpClientAdapter = externalAdapter,
      );

      final route = await repo.getOrderRoute(orderId: 'ord-fb');
      expect(route.isRoadRoute, isTrue);
      expect(route.source, 'client_osrm');
      expect(route.points, hasLength(4));
      expect(externalAdapter.calls, 1);
    });

    test('computeWaypointsRoute caches backend road geometry and returns non-cached straight chord offline', () async {
      final apiAdapter = _MockAdapter((options) async {
        expect(options.path, '/orders/route');
        expect(options.method, 'POST');
        return _okJson({
          'success': true,
          'statusCode': 200,
          'message': 'OK',
          'timestamp': '2026-11-21T08:00:00Z',
          'data': {
            'encodedPolyline': '',
            'coordinates': [
              {'latitude': 30.0900, 'longitude': 31.2900},
              {'latitude': 30.0940, 'longitude': 31.2920},
              {'latitude': 30.0990, 'longitude': 31.2990},
            ],
            'waypoints': [
              {'latitude': 30.0900, 'longitude': 31.2900},
              {'latitude': 30.0990, 'longitude': 31.2990},
            ],
            'distanceMeters': 1500,
            'durationSeconds': 210,
            'isRoadRoute': true,
            'source': 'osrm',
          },
        });
      });

      final repo = SharedRoutingRepository(
        OrdersApi(Dio()..httpClientAdapter = apiAdapter, standardSerializers),
      );

      const wps = [
        RoadRoutePoint(30.0900, 31.2900),
        RoadRoutePoint(30.0990, 31.2990),
      ];
      final res1 = await repo.computeWaypointsRoute(wps);
      final res2 = await repo.computeWaypointsRoute(wps);

      expect(res1.isRoadRoute, isTrue);
      expect(res1.points, hasLength(3));
      expect(res2.points, hasLength(3));
      expect(apiAdapter.calls, 1);

      // Offline failure falls back to straight chord with isRoadRoute=false
      final failingAdapter = _MockAdapter(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        ),
      );
      final offlineRepo = SharedRoutingRepository(
        OrdersApi(Dio()..httpClientAdapter = failingAdapter, standardSerializers),
      );
      final offline = await offlineRepo.computeWaypointsRoute(const [
        RoadRoutePoint(30.1100, 31.3100),
        RoadRoutePoint(30.1200, 31.3200),
      ]);
      expect(offline.isRoadRoute, isFalse);
      expect(offline.source, 'fallback');
      expect(offline.points, hasLength(2));
    });
  });
}
