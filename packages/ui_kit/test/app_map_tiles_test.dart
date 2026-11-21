import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('AppMapTileLayer Color Matrices', () {
    test('matrices have standard 4x5 ColorFilter format (20 doubles)', () {
      expect(AppMapTileLayer.darkWhiteTextMatrix.length, 20);
      expect(AppMapTileLayer.osmDarkInversionMatrix.length, 20);
    });

    test('osmDarkInversionMatrix maps dark city/country text to pure white (#FFFFFF)', () {
      final m = AppMapTileLayer.osmDarkInversionMatrix;

      List<int> applyMatrix(int r, int g, int b) {
        final rOut = (m[0] * r + m[1] * g + m[2] * b + m[4]).clamp(0.0, 255.0).round();
        final gOut = (m[5] * r + m[6] * g + m[7] * b + m[9]).clamp(0.0, 255.0).round();
        final bOut = (m[10] * r + m[11] * g + m[12] * b + m[14]).clamp(0.0, 255.0).round();
        return [rOut, gOut, bOut];
      }

      final darkText = applyMatrix(36, 36, 36);
      expect(darkText, [255, 255, 255], reason: 'Dark text glyph must be pure white');

      final midText = applyMatrix(65, 65, 65);
      expect(midText, [255, 255, 255], reason: 'Mid text glyph must be pure white');

      final antialiasedEdge = applyMatrix(80, 80, 80);
      expect(antialiasedEdge[0], greaterThanOrEqualTo(245), reason: 'Font edges must be bright white');
      expect(antialiasedEdge[1], greaterThanOrEqualTo(245));
      expect(antialiasedEdge[2], greaterThanOrEqualTo(245));

      final land = applyMatrix(242, 239, 233);
      expect(land[0], lessThan(35), reason: 'Land must be deep dark slate');
      expect(land[1], lessThan(35));
      expect(land[2], lessThan(35));
    });

    test('darkWhiteTextMatrix boosts Carto text labels to crisp pure white', () {
      final m = AppMapTileLayer.darkWhiteTextMatrix;

      List<int> applyMatrix(int r, int g, int b) {
        final rOut = (m[0] * r + m[1] * g + m[2] * b + m[4]).clamp(0.0, 255.0).round();
        final gOut = (m[5] * r + m[6] * g + m[7] * b + m[9]).clamp(0.0, 255.0).round();
        final bOut = (m[10] * r + m[11] * g + m[12] * b + m[14]).clamp(0.0, 255.0).round();
        return [rOut, gOut, bOut];
      }

      final labelMid = applyMatrix(73, 73, 73);
      expect(labelMid, [255, 255, 255]);

      final labelBright = applyMatrix(102, 102, 102);
      expect(labelBright, [255, 255, 255]);

      final bg = applyMatrix(14, 14, 14);
      expect(bg, [0, 0, 0]);
    });
  });

  group('AppMapTileLayer Widget (Always White / Light Map)', () {
    testWidgets('uses light navigation tiles on white canvas even when app theme is dark', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(30.0444, 31.2357),
                initialZoom: 13.0,
              ),
              children: [
                AppMapTileLayer(
                  userAgentPackageName: 'com.otlob.test',
                ),
              ],
            ),
          ),
        ),
      );

      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.urlTemplate, contains('voyager'));
      expect(tileLayer.urlTemplate, isNot(contains('dark_all')));
      expect(tileLayer.tileBuilder, isNull);

      final coloredBox = tester.widget<ColoredBox>(
        find.ancestor(
          of: find.byType(TileLayer),
          matching: find.byType(ColoredBox),
        ).first,
      );
      expect(coloredBox.color, Colors.white);
    });

    testWidgets('renders standard OSM without dark inversion filter even when app theme is dark', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(30.0444, 31.2357),
                initialZoom: 13.0,
              ),
              children: [
                AppMapTileLayer(
                  style: AppMapStyle.standard,
                  userAgentPackageName: 'com.otlob.test',
                ),
              ],
            ),
          ),
        ),
      );

      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.urlTemplate, contains('tile.openstreetmap.org'));
      expect(tileLayer.tileBuilder, isNull);
    });

    testWidgets('preserves opt-in AppMapStyle.navigationDark when explicitly requested', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(30.0444, 31.2357),
                initialZoom: 13.0,
              ),
              children: [
                AppMapTileLayer(
                  style: AppMapStyle.navigationDark,
                  userAgentPackageName: 'com.otlob.test',
                ),
              ],
            ),
          ),
        ),
      );

      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.urlTemplate, contains('dark_all'));
      expect(tileLayer.tileBuilder, isNotNull);
    });

    testWidgets(
      'reuses shared keep-alive TileProvider, isolates repaint, throttles updates, and avoids unnecessary @2x/OSM simulation',
      (tester) async {
        Future<void> pumpMap({required double dpr}) async {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(devicePixelRatio: dpr),
              child: const MaterialApp(
                home: Scaffold(
                  body: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(30.0444, 31.2357),
                      initialZoom: 13.0,
                    ),
                    children: [
                      AppMapTileLayer(
                        userAgentPackageName: 'com.otlob.perf.test',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        await pumpMap(dpr: 3.0);
        final firstLayer = tester.widget<TileLayer>(find.byType(TileLayer));
        expect(firstLayer.resolvedRetinaMode, RetinaMode.server);
        expect(
          firstLayer.evictErrorTileStrategy,
          EvictErrorTileStrategy.notVisibleRespectMargin,
        );
        expect(
          identical(
            firstLayer.tileUpdateTransformer,
            TileUpdateTransformers.ignoreTapEvents,
          ),
          isFalse,
        );
        expect(
          find.ancestor(
            of: find.byType(ColoredBox),
            matching: find.byType(RepaintBoundary),
          ),
          findsWidgets,
        );

        // Rebuild with 1.0 DPR -> same shared TileProvider and transformer, @1x tiles
        await pumpMap(dpr: 1.0);
        final lowDprLayer = tester.widget<TileLayer>(find.byType(TileLayer));
        expect(identical(firstLayer.tileProvider, lowDprLayer.tileProvider), isTrue);
        expect(
          identical(
            firstLayer.tileUpdateTransformer,
            lowDprLayer.tileUpdateTransformer,
          ),
          isTrue,
        );
        expect(lowDprLayer.resolvedRetinaMode, RetinaMode.disabled);

        // OSM standard style on 3.0 DPR must NOT enable simulated 4x retina tiles
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(devicePixelRatio: 3.0),
            child: MaterialApp(
              home: Scaffold(
                body: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(30.0444, 31.2357),
                    initialZoom: 13.0,
                  ),
                  children: [
                    AppMapTileLayer(
                      style: AppMapStyle.standard,
                      userAgentPackageName: 'com.otlob.perf.test',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final osmLayer = tester.widget<TileLayer>(find.byType(TileLayer));
        expect(osmLayer.resolvedRetinaMode, RetinaMode.disabled);
      },
    );
  });
}
