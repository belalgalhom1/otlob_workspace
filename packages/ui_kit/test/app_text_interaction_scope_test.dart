import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  String? mockClipboard;

  setUp(() {
    mockClipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              final args = call.arguments as Map<dynamic, dynamic>?;
              mockClipboard = args?['text'] as String?;
              return null;
            case 'Clipboard.getData':
              return mockClipboard == null ? null : {'text': mockClipboard};
            case 'Clipboard.hasStrings':
              return {
                'value': mockClipboard != null && mockClipboard!.isNotEmpty,
              };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<Finder> ensureSelectAllVisible(WidgetTester tester) async {
    Finder findSelectAll() {
      final titleCase = find.text('Select All');
      return titleCase.evaluate().isNotEmpty
          ? titleCase
          : find.text('Select all');
    }

    var finder = findSelectAll();
    if (finder.evaluate().isEmpty) {
      final overflow = find.byIcon(Icons.more_vert);
      if (overflow.evaluate().isNotEmpty) {
        await tester.tap(overflow.first);
        await tester.pumpAndSettle();
        finder = findSelectAll();
      }
    }
    return finder;
  }

  for (final platform in const [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'AppTextInteractionScope preserves selection, clipboard actions, cursor edit, and outside dismiss on ${platform.name}',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        tester.view.physicalSize = const Size(430, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = TextEditingController(text: 'Otlob Delivery');
        final focusNode = FocusNode();
        addTearDown(() {
          controller.dispose();
          focusNode.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTextInteractionScope.applySelectionTheme(
              AppTheme.lightTheme,
            ).copyWith(platform: platform),
            builder: (context, child) => AppTextInteractionScope(
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      key: const ValueKey('shared_field'),
                      controller: controller,
                      focusNode: focusNode,
                    ),
                  ),
                  const SizedBox(height: 160),
                  const Center(
                    child: Text('Outside', key: ValueKey('outside_tap')),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fieldFinder = find.byKey(const ValueKey('shared_field'));
        final rect = tester.getRect(fieldFinder);
        final onText = Offset(rect.left + 42, rect.center.dy);

        await tester.tapAt(onText);
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        await tester.longPressAt(onText);
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        final selectAll = await ensureSelectAllVisible(tester);
        expect(selectAll, findsOneWidget);
        await tester.tap(selectAll);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();
        expect(mockClipboard, 'Otlob Delivery');
        expect(focusNode.hasFocus, isTrue);

        await tester.longPressAt(onText);
        await tester.pumpAndSettle();
        final selectAllCut = await ensureSelectAllVisible(tester);
        await tester.tap(selectAllCut);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cut'));
        await tester.pumpAndSettle();
        expect(controller.text, isEmpty);

        await tester.longPressAt(onText);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Paste'));
        await tester.pumpAndSettle();
        expect(controller.text, 'Otlob Delivery');

        await tester.tap(find.byKey(const ValueKey('outside_tap')));
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isFalse);

        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
