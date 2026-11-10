import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
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

      // Typical dark city / country text in standard OpenStreetMap:
      // Dark text glyphs: RGB around (36, 36, 36) to (75, 75, 75)
      final darkText = applyMatrix(36, 36, 36);
      expect(darkText, [255, 255, 255], reason: 'Dark text glyph must be pure white');

      final midText = applyMatrix(65, 65, 65);
      expect(midText, [255, 255, 255], reason: 'Mid text glyph must be pure white');

      final antialiasedEdge = applyMatrix(80, 80, 80);
      expect(antialiasedEdge[0], greaterThanOrEqualTo(245), reason: 'Font edges must be bright white');
      expect(antialiasedEdge[1], greaterThanOrEqualTo(245));
      expect(antialiasedEdge[2], greaterThanOrEqualTo(245));

      // Land background in OSM (pale beige: 242, 239, 233) should become dark
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

      // In Carto Dark Matter, labels are the brightest element (~68 to 102)
      final labelMid = applyMatrix(73, 73, 73);
      expect(labelMid, [255, 255, 255]);

      final labelBright = applyMatrix(102, 102, 102);
      expect(labelBright, [255, 255, 255]);

      // Background (14, 14, 14) stays black
      final bg = applyMatrix(14, 14, 14);
      expect(bg, [0, 0, 0]);
    });
  });

  group('AppMapTileLayer Widget', () {
    testWidgets('renders TileLayer with dark filter in dark mode', (tester) async {
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

      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(AppMapTileLayer), findsOneWidget);
    });

    testWidgets('renders TileLayer with dark filter for AppMapStyle.standard in dark mode', (tester) async {
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

      expect(find.byType(TileLayer), findsOneWidget);
    });
  });
}
