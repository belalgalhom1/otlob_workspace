import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('AppWindowConstraintGuard', () {
    testWidgets(
      'clamps textScaler to [0.85, 1.3] on standard windows while preserving insets and size',
      (tester) async {
        late double scaledHigh;
        late double scaledLow;
        late EdgeInsets observedPadding;
        late Size observedSize;

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(400, 800),
                padding: EdgeInsets.only(top: 47, bottom: 34),
                textScaler: TextScaler.linear(2.0),
              ),
              child: AppWindowConstraintGuard(
                child: Builder(
                  builder: (context) {
                    scaledHigh = MediaQuery.textScalerOf(context).scale(10);
                    observedPadding = MediaQuery.paddingOf(context);
                    observedSize = MediaQuery.sizeOf(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );

        expect(scaledHigh, closeTo(13.0, 0.001));
        expect(observedPadding, const EdgeInsets.only(top: 47, bottom: 34));
        expect(observedSize, const Size(400, 800));

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(400, 800),
                textScaler: TextScaler.linear(0.5),
              ),
              child: AppWindowConstraintGuard(
                child: Builder(
                  builder: (context) {
                    scaledLow = MediaQuery.textScalerOf(context).scale(10);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );

        expect(scaledLow, closeTo(8.5, 0.001));
      },
    );

    testWidgets(
      'preserves simulated minimum size AND clamps textScaler on tiny desktop/split windows',
      (tester) async {
        late double observedScaled;
        late Size observedSize;
        late EdgeInsets observedPadding;

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(280, 500),
                padding: EdgeInsets.only(top: 47, bottom: 34),
                textScaler: TextScaler.linear(1.8),
              ),
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 500,
                  child: AppWindowConstraintGuard(
                    child: Builder(
                      builder: (context) {
                        observedScaled = MediaQuery.textScalerOf(
                          context,
                        ).scale(10);
                        observedSize = MediaQuery.sizeOf(context);
                        observedPadding = MediaQuery.paddingOf(context);
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(observedSize, const Size(360, 600));
        expect(observedScaled, closeTo(13.0, 0.001));
        expect(observedPadding, const EdgeInsets.only(top: 47, bottom: 34));
      },
    );
  });

  group('SafeArea and TextScaler responsive shared widgets', () {
    for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
        'MaintenanceScreen & ForceUpdateScreen respect SafeArea and 1.3x textScaler (${direction.name})',
        (tester) async {
          tester.view.physicalSize = const Size(360, 600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MaterialApp(
              home: Directionality(
                textDirection: direction,
                child: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(360, 600),
                    padding: EdgeInsets.only(top: 47, bottom: 34),
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: AppWindowConstraintGuard(
                    child: MaintenanceScreen(
                      title: direction == TextDirection.rtl
                          ? 'تطبيق تحت الصيانة المجدولة'
                          : 'System Under Scheduled Maintenance',
                      message: direction == TextDirection.rtl
                          ? 'نعمل حالياً على تحسين الأداء وسنعود للعمل خلال دقائق قليلة.'
                          : 'We are currently performing scheduled upgrades and will be back shortly.',
                      retryLabel: direction == TextDirection.rtl
                          ? 'إعادة المحاولة الآن'
                          : 'Try Again Now',
                      onRetry: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final safeBox = tester.getRect(find.byType(SingleChildScrollView));
          expect(safeBox.top, greaterThanOrEqualTo(47.0));
          expect(safeBox.bottom, lessThanOrEqualTo(600.0 - 34.0));

          await tester.pumpWidget(
            MaterialApp(
              home: Directionality(
                textDirection: direction,
                child: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(360, 600),
                    padding: EdgeInsets.only(top: 47, bottom: 34),
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: AppWindowConstraintGuard(
                    child: ForceUpdateScreen(
                      title: direction == TextDirection.rtl
                          ? 'تحديث إجباري مطلوب'
                          : 'Required Update Available',
                      message: direction == TextDirection.rtl
                          ? 'يرجى تحديث التطبيق للحصول على أحدث الميزات والتحسينات الأمنية.'
                          : 'Please update the app to continue using all features safely.',
                      updateLabel: direction == TextDirection.rtl
                          ? 'تحديث التطبيق الآن'
                          : 'Update App Now',
                      onUpdate: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final updateSafeBox = tester.getRect(
            find.byType(SingleChildScrollView),
          );
          expect(updateSafeBox.top, greaterThanOrEqualTo(47.0));
          expect(updateSafeBox.bottom, lessThanOrEqualTo(600.0 - 34.0));
        },
      );
    }

    testWidgets(
      'QuickReplyChips scales height smoothly under 1.3x text scaling without clipping',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: Scaffold(
                body: Center(
                  child: QuickReplyChips(
                    chips: const [
                      QuickReplyChipItem(
                        text: 'وصلت عند العنوان المحدد الآن',
                        icon: LucideIcons.mapPin,
                      ),
                      QuickReplyChipItem(
                        text: 'I have arrived outside',
                        icon: LucideIcons.check,
                      ),
                    ],
                    onSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final listHeight = tester.getSize(find.byType(QuickReplyChips)).height;
        expect(listHeight, greaterThan(42.0));
      },
    );
  });
}
