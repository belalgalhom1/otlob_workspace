import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AndroidScrollCaptureBridge.resetForTesting();
  });

  testWidgets('reports non-scrollable screen as scrollable: false', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Static screen')),
        ),
      ),
    );

    final metrics = await AndroidScrollCaptureBridge.handleMethodCallForTesting(
      const MethodCall('getScrollMetrics'),
    ) as Map<dynamic, dynamic>;

    expect(metrics['scrollable'], isFalse);
  });

  testWidgets(
    'discovers primary vertical scrollable, excludes pinned SliverAppBar, scrolls, and restores offset',
    (tester) async {
      final controller = ScrollController(initialScrollOffset: 120);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              controller: controller,
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  title: Text('Stores'),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => SizedBox(
                      height: 80,
                      child: ListTile(title: Text('Store #$index')),
                    ),
                    childCount: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final start = await AndroidScrollCaptureBridge.handleMethodCallForTesting(
        const MethodCall('startCapture'),
      ) as Map<dynamic, dynamic>;

      expect(start['scrollable'], isTrue);
      expect((start['maxExtentPx'] as int), greaterThan(0));
      // Pinned SliverAppBar (56 logical px) should push viewportTop > 0.
      expect((start['viewportTop'] as int), greaterThan(0));

      final dpr = (start['devicePixelRatio'] as num).toDouble();
      final targetPx = (600 * dpr).round();

      final scrollFuture =
          AndroidScrollCaptureBridge.handleMethodCallForTesting(
        MethodCall('scrollToOffset', {'offsetPx': targetPx}),
      );
      await tester.pump();
      await tester.pump();
      final scrollResult = await scrollFuture as Map<dynamic, dynamic>;

      expect(scrollResult['ok'], isTrue);
      expect(controller.offset, closeTo(600, 1.0));

      final endFuture = AndroidScrollCaptureBridge.handleMethodCallForTesting(
        const MethodCall('endCapture'),
      );
      await tester.pump();
      await tester.pump();
      expect(await endFuture, isTrue);
      expect(controller.offset, closeTo(120, 1.0));
    },
  );
}
