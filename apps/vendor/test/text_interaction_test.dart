import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

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

  Widget buildVendorShell({
    required Widget home,
    required TargetPlatform platform,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    final lightTheme = AppTextInteractionScope.applySelectionTheme(
      AppTheme.lightTheme,
    ).copyWith(platform: platform);
    final darkTheme = AppTextInteractionScope.applySelectionTheme(
      AppTheme.darkTheme,
    ).copyWith(platform: platform);

    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, child) {
        return AppWindowConstraintGuard(
          minWidth: 360.0,
          minHeight: 600.0,
          minTextScaleFactor: 0.85,
          maxTextScaleFactor: 1.3,
          child: AppTextInteractionScope(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: home,
    );
  }

  Offset textHitPoint(WidgetTester tester, Finder fieldFinder, {double dx = 42}) {
    final rect = tester.getRect(fieldFinder);
    return Offset(rect.left + dx, rect.center.dy);
  }

  Finder findSelectAll() {
    final titleCase = find.text('Select All');
    return titleCase.evaluate().isNotEmpty ? titleCase : find.text('Select all');
  }

  Future<Finder> ensureSelectAllVisible(WidgetTester tester) async {
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
      'TextField supports long-press menu, Select All, Copy, Cut, Paste, cursor move, and tap-outside dismiss on ${platform.name}',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        tester.view.physicalSize = const Size(430, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = TextEditingController(text: 'Hello Vendor World');
        final focusNode = FocusNode();
        addTearDown(() {
          controller.dispose();
          focusNode.dispose();
        });

        await tester.pumpWidget(
          buildVendorShell(
            platform: platform,
            home: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextFormField(
                      key: const ValueKey('editable_field'),
                      controller: controller,
                      focusNode: focusNode,
                    ),
                  ),
                  const SizedBox(height: 160),
                  const Center(
                    child: Text(
                      'Outside Area',
                      key: ValueKey('outside_area'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fieldFinder = find.byKey(const ValueKey('editable_field'));
        final onText = textHitPoint(tester, fieldFinder);

        // 1. Focus the field
        await tester.tapAt(onText);
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        // 2. Long-press directly on text -> stays focused and opens selection toolbar
        await tester.longPressAt(onText);
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);
        if (platform == TargetPlatform.android) {
          expect(controller.selection.isCollapsed, isFalse);
          expect(find.text('Copy'), findsOneWidget);
          expect(find.text('Cut'), findsOneWidget);
        }

        // 3. Tap Select All -> selects entire string and keeps focus
        final selectAll1 = await ensureSelectAllVisible(tester);
        expect(selectAll1, findsOneWidget);
        await tester.tap(selectAll1);
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);
        expect(controller.selection.baseOffset, 0);
        expect(controller.selection.extentOffset, controller.text.length);
        expect(find.text('Copy'), findsOneWidget);
        expect(find.text('Cut'), findsOneWidget);

        // 4. Tap Copy -> writes full text to clipboard
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();
        expect(mockClipboard, 'Hello Vendor World');
        expect(focusNode.hasFocus, isTrue);

        // 5. Long-press, Select All, and Cut -> copies and clears field
        await tester.longPressAt(onText);
        await tester.pumpAndSettle();
        final selectAll2 = await ensureSelectAllVisible(tester);
        expect(selectAll2, findsOneWidget);
        await tester.tap(selectAll2);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cut'));
        await tester.pumpAndSettle();
        expect(mockClipboard, 'Hello Vendor World');
        expect(controller.text, isEmpty);
        expect(focusNode.hasFocus, isTrue);

        // 6. Long-press empty focused field and Paste -> restores clipboard text
        await tester.longPressAt(onText);
        await tester.pumpAndSettle();
        expect(find.text('Paste'), findsOneWidget);
        await tester.tap(find.text('Paste'));
        await tester.pumpAndSettle();
        expect(controller.text, 'Hello Vendor World');
        expect(focusNode.hasFocus, isTrue);

        // 7. Tap inside text field to move cursor while staying focused
        await tester.tapAt(textHitPoint(tester, fieldFinder, dx: 24));
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        // 8. Tap outside -> cleanly dismisses focus / keyboard
        await tester.tap(find.byKey(const ValueKey('outside_area')));
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isFalse);

        debugDefaultTargetPlatformOverride = null;
      },
    );
  }

  testWidgets(
    'DashboardSearchBar supports long-press selection and Copy inside VendorTextInteractionScope',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final searchController = TextEditingController(text: 'Order12345');
      addTearDown(searchController.dispose);

      await tester.pumpWidget(
        buildVendorShell(
          platform: TargetPlatform.android,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(top: 140, left: 16, right: 16),
              child: DashboardSearchBar(
                controller: searchController,
                onChanged: (_) {},
                onClear: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      // Offset past the prefix search icon so we hit the actual search text
      final onSearchText = textHitPoint(tester, searchField, dx: 76);

      await tester.tapAt(onSearchText);
      await tester.pumpAndSettle();
      await tester.longPressAt(onSearchText);
      await tester.pumpAndSettle();

      expect(searchController.selection.isCollapsed, isFalse);
      expect(find.text('Copy'), findsOneWidget);

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(mockClipboard, 'Order12345');

      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'TextFormField inside AppDialog supports long-press selection and Copy without dismissing dialog',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = TextEditingController(text: 'ProductName');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildVendorShell(
          platform: TargetPlatform.android,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => AppDialog(
                        body: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            key: const ValueKey('dialog_field'),
                            controller: controller,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final dialogField = find.byKey(const ValueKey('dialog_field'));
      expect(dialogField, findsOneWidget);
      final onDialogText = textHitPoint(tester, dialogField);

      await tester.tapAt(onDialogText);
      await tester.pumpAndSettle();
      await tester.longPressAt(onDialogText);
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      expect(mockClipboard, 'ProductName');
      // Dialog remains open after interacting with text selection menu
      expect(dialogField, findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    },
  );

  test(
    'AppTextInteractionScope.applySelectionTheme configures light and dark selection colors',
    () {
      final light = AppTextInteractionScope.applySelectionTheme(
        AppTheme.lightTheme,
      );
      final dark = AppTextInteractionScope.applySelectionTheme(
        AppTheme.darkTheme,
      );

      expect(light.textSelectionTheme.cursorColor, AppColors.primaryVariant);
      expect(
        light.textSelectionTheme.selectionHandleColor,
        AppColors.primaryVariant,
      );
      expect(light.textSelectionTheme.selectionColor, isNotNull);

      expect(dark.textSelectionTheme.cursorColor, AppColors.primary);
      expect(dark.textSelectionTheme.selectionHandleColor, AppColors.primary);
      expect(dark.textSelectionTheme.selectionColor, isNotNull);
    },
  );
}
