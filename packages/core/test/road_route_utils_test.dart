import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubHttpClientAdapter implements HttpClientAdapter {
  int calls = 0;
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _StubHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    calls++;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Map<String, dynamic> data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('PolylineCodec', () {
    test('matches Google Encoded Polyline precision-5 reference vector', () {
      const sample = [
        RoadRoutePoint(38.5, -120.2),
        RoadRoutePoint(40.7, -120.95),
        RoadRoutePoint(43.252, -126.453),
      ];
      const expected = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final encoded = PolylineCodec.encode(sample);
      expect(encoded, expected);

      final decoded = PolylineCodec.decode(encoded);
      expect(decoded, hasLength(3));
      for (int i = 0; i < sample.length; i++) {
        expect(decoded[i].latitude, closeTo(sample[i].latitude, 1e-4));
        expect(decoded[i].longitude, closeTo(sample[i].longitude, 1e-4));
      }
    });

    test('handles empty input gracefully', () {
      expect(PolylineCodec.encode(const []), isEmpty);
      expect(PolylineCodec.decode(''), isEmpty);
    });
  });

  group('GeoPointUtils & trimRouteToDriverPosition', () {
    test('extractPoint parses GeoJSON, maps, tuples and rejects (0,0) / out-of-range', () {
      expect(
        GeoPointUtils.extractPoint({
          'type': 'Point',
          'coordinates': [31.2357, 30.0444],
        }),
        const RoadRoutePoint(30.0444, 31.2357),
      );
      expect(
        GeoPointUtils.extractPoint({'latitude': 30.05, 'longitude': 31.24}),
        const RoadRoutePoint(30.05, 31.24),
      );
      expect(
        GeoPointUtils.extractPoint([31.25, 30.06]),
        const RoadRoutePoint(30.06, 31.25),
      );
      expect(GeoPointUtils.extractPoint({'coordinates': [0, 0]}), isNull);
      expect(GeoPointUtils.extractPoint({'lat': 95.0, 'lng': 31.0}), isNull);
    });

    test('trims completed vertices behind driver along active road polyline', () {
      const route = [
        RoadRoutePoint(30.0400, 31.2300),
        RoadRoutePoint(30.0450, 31.2300),
        RoadRoutePoint(30.0450, 31.2380),
        RoadRoutePoint(30.0500, 31.2380),
      ];
      // Driver halfway along second segment (turning east on 30.0450)
      const driverPos = RoadRoutePoint(30.0451, 31.2340);
      final res = trimRouteToDriverPosition(route, driverPos);

      expect(res.isOffRoute, isFalse);
      expect(res.points.first, driverPos);
      // Already-passed vertices (index 0 & 1) are trimmed; upcoming turn vertex (index 2) & destination remain.
      expect(res.points, contains(const RoadRoutePoint(30.0450, 31.2380)));
      expect(res.points.last, const RoadRoutePoint(30.0500, 31.2380));
      expect(res.points, isNot(contains(const RoadRoutePoint(30.0400, 31.2300))));
    });

    test('flags off-route when driver deviates beyond threshold without corrupting route', () {
      const route = [
        RoadRoutePoint(30.0400, 31.2300),
        RoadRoutePoint(30.0500, 31.2300),
      ];
      // ~1km off-route east
      const offRouteDriver = RoadRoutePoint(30.0450, 31.2450);
      final res = trimRouteToDriverPosition(route, offRouteDriver);
      expect(res.isOffRoute, isTrue);
      expect(res.points.first, offRouteDriver);
      expect(res.points.length, 3);
    });
  });

  group('OsrmClientFallback', () {
    test('fetches multi-waypoint OSRM geometry and caches subsequent lookup', () async {
      final adapter = _StubHttpClientAdapter((options) async {
        expect(
          options.path,
          contains('31.21,30.01;31.22,30.02;31.23,30.03'),
        );
        return _jsonBody({
          'code': 'Ok',
          'routes': [
            {
              'geometry': {
                'coordinates': [
                  [31.21, 30.01],
                  [31.215, 30.016],
                  [31.22, 30.02],
                  [31.227, 30.024],
                  [31.23, 30.03],
                ],
              },
            },
          ],
        });
      });
      final dio = Dio()..httpClientAdapter = adapter;

      const wps = [
        RoadRoutePoint(30.01, 31.21),
        RoadRoutePoint(30.02, 31.22),
        RoadRoutePoint(30.03, 31.23),
      ];
      final first = await OsrmClientFallback.fetchMultiWaypointRoute(dio, wps);
      final second = await OsrmClientFallback.fetchMultiWaypointRoute(dio, wps);

      expect(first, isNotNull);
      expect(first!.length, 5);
      expect(second, hasLength(5));
      expect(adapter.calls, 1);
    });
  });
}
