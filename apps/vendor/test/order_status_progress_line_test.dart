import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('OrderTypeHelper progress lifecycle', () {
    test('standard order includes all 8 canonical backend stages in order', () {
      final steps = OrderTypeHelper.progressSteps(
        AppOrderType.standard,
        isArabic: false,
      );
      expect(
        steps.map((s) => s.key).toList(),
        [
          'PENDING',
          'ACCEPTED',
          'LOOKING_FOR_DRIVER',
          'DRIVER_ASSIGNED',
          'PREPARING',
          'READY_FOR_PICKUP',
          'PICKED_UP',
          'DELIVERED',
        ],
      );

      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.standard,
          'PENDING',
        ),
        0,
      );
      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.standard,
          'ACCEPTED',
        ),
        1,
      );
      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.standard,
          'LOOKING_FOR_DRIVER',
        ),
        2,
      );
      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.standard,
          'DRIVER_ASSIGNED',
        ),
        3,
      );
      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.standard,
          'PREPARING',
        ),
        4,
      );
      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.standard,
          'READY_FOR_PICKUP',
        ),
        5,
      );
      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.standard,
          'PICKED_UP',
        ),
        6,
      );
      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.standard,
          'DELIVERED',
        ),
        7,
      );
      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.standard,
          'CANCELLED',
        ),
        -1,
      );
    });

    test('ride and custom delivery expose 6 service-aware stages', () {
      final rideSteps = OrderTypeHelper.progressSteps(
        AppOrderType.ride,
        isArabic: true,
      );
      final customSteps = OrderTypeHelper.progressSteps(
        AppOrderType.customDelivery,
        isArabic: false,
      );
      expect(rideSteps.length, 6);
      expect(customSteps.length, 6);
      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.ride,
          'LOOKING_FOR_DRIVER',
        ),
        1,
      );
      expect(
        OrderTypeHelper.currentProgressStepIndex(
          AppOrderType.customDelivery,
          'PICKED_UP',
        ),
        4,
      );
    });
  });

  group('OrderStatusProgressLine widget', () {
    Widget buildHarness({
      required double width,
      required TextDirection direction,
      required String status,
      required bool isArabic,
      Brightness brightness = Brightness.dark,
    }) {
      final steps = OrderTypeHelper.progressSteps(
        AppOrderType.standard,
        isArabic: isArabic,
      )
          .map(
            (s) => OrderProgressStepItem(
              label: s.label,
              icon: OrderStatusProgressLine.iconForStageKey(s.key),
            ),
          )
          .toList();
      final currentStep = OrderTypeHelper.currentProgressStepIndex(
        AppOrderType.standard,
        status,
      );

      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: OrderStatusProgressLine(
                  steps: steps,
                  currentStep: currentStep,
                  activeStatusLabel: OrderTypeHelper.customerStatusLabel(
                    AppOrderType.standard,
                    status,
                    isArabic: isArabic,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders cleanly with horizontal scroll on mobile phone (340px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          width: 340,
          direction: TextDirection.ltr,
          status: 'PICKED_UP',
          isArabic: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('7 / 8'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Finding Driver'), findsOneWidget);
      expect(find.text('Picked Up'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders full-width balanced row on desktop/tablet (800px) in Arabic RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          width: 800,
          direction: TextDirection.rtl,
          status: 'LOOKING_FOR_DRIVER',
          isArabic: true,
          brightness: Brightness.light,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.text('3 / 8'), findsOneWidget);
      expect(find.text('تم القبول'), findsOneWidget);
      expect(find.text('بحث عن سائق'), findsOneWidget);
      expect(find.text('تم الاستلام'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
