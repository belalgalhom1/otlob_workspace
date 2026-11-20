import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/notifications/presentation/announcements_screen.dart';
import 'package:vendor/features/promotions/presentation/widgets/add_promotion_dialog.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeAdminVendorsRepo extends Fake implements AdminVendorsRepository {
  @override
  Future<dynamic> getVendors({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
    String? verticalId,
  }) async {
    return [
      {'id': 'v-1', 'name': 'Burger King', 'storeName': 'Burger King'},
    ];
  }
}

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      data_providers.adminVendorsRepositoryProvider
          .overrideWithValue(_FakeAdminVendorsRepo()),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'AddPromotionDialog renders within scrollable AppDialog and allows vertical dragging across entire screen (EN)',
    (tester) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddPromotionDialog(),
              ),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.byType(AddPromotionDialog), findsOneWidget);
      expect(find.byType(AppDialog), findsOneWidget);

      final scrollFinder = find.byType(SingleChildScrollView);
      expect(scrollFinder, findsAtLeastNWidgets(1));

      final scrollable = tester.widget<SingleChildScrollView>(scrollFinder.first);
      expect(scrollable.physics, isA<AlwaysScrollableScrollPhysics>());

      // Get initial scroll offset
      final scrollState =
          tester.state<ScrollableState>(find.byType(Scrollable).first);
      final initialOffset = scrollState.position.pixels;

      // 1. Drag on the dialog card
      await tester.drag(find.byType(Dialog), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(scrollState.position.pixels, greaterThan(initialOffset));

      // 2. Drag again on the dialog card
      final currentOffset = scrollState.position.pixels;
      await tester.drag(find.byType(Dialog), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(scrollState.position.pixels, greaterThan(currentOffset));

      // 3. Drag over description multiline text field without gesture lock
      final beforeFieldDragOffset = scrollState.position.pixels;
      final descFieldFinder = find.widgetWithText(TextFormField, 'Optional...');
      if (descFieldFinder.evaluate().isNotEmpty) {
        await tester.drag(descFieldFinder.first, const Offset(0, -80));
        await tester.pumpAndSettle();
        expect(scrollState.position.pixels, greaterThan(beforeFieldDragOffset));
      }

      // 4. Drag back down on the dialog card
      final scrolledOffset = scrollState.position.pixels;
      await tester.drag(find.byType(Dialog), const Offset(0, 250));
      await tester.pumpAndSettle();
      expect(scrollState.position.pixels, lessThan(scrolledOffset));
    },
  );

  testWidgets(
    'AddPromotionDialog scrolls smoothly with simulated keyboard bottom insets and supports Arabic RTL',
    (tester) async {
      tester.view.physicalSize = const Size(400, 750);
      tester.view.devicePixelRatio = 1.0;
      // Simulate soft keyboard taking 280px at bottom
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('ar'),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddPromotionDialog(),
              ),
              child: const Text('افتح'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      expect(find.byType(AddPromotionDialog), findsOneWidget);
      expect(find.byType(AppDialog), findsOneWidget);

      final scrollFinder = find.byType(SingleChildScrollView);
      expect(scrollFinder, findsAtLeastNWidgets(1));

      // Drag up to reveal the bottom action buttons
      await tester.drag(scrollFinder.first, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Action buttons (Cancel / Create in Arabic) should be visible and reachable
      expect(find.byType(AppDialogFooter), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AnnouncementsScreen renders with AlwaysScrollable physics and allows scrolling over multiline fields without gesture lock',
    (tester) async {
      tester.view.physicalSize = const Size(380, 680);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          child: const AnnouncementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnnouncementsScreen), findsOneWidget);

      final scrollFinder = find.byType(SingleChildScrollView);
      expect(scrollFinder, findsOneWidget);

      final scrollable =
          tester.widget<SingleChildScrollView>(scrollFinder.first);
      expect(scrollable.physics, isA<AlwaysScrollableScrollPhysics>());

      final scrollState =
          tester.state<ScrollableState>(find.byType(Scrollable).first);
      final initialOffset = scrollState.position.pixels;

      // Drag over multiline Message Body (EN)
      final bodyField = find.widgetWithText(TextFormField, 'Message Body (EN)');
      expect(bodyField, findsOneWidget);

      await tester.drag(bodyField, const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(scrollState.position.pixels, greaterThan(initialOffset));

      // Drag back down
      final scrolledOffset = scrollState.position.pixels;
      await tester.drag(scrollFinder, const Offset(0, 100));
      await tester.pumpAndSettle();

      expect(scrollState.position.pixels, lessThan(scrolledOffset));
      expect(tester.takeException(), isNull);
    },
  );
}
