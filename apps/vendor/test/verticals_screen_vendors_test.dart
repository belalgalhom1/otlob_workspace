import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/vendors/presentation/vertical_provider.dart';
import 'package:vendor/features/vendors/presentation/verticals_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeVerticalNotifier extends VerticalNotifier {
  final List<dynamic> items;
  _FakeVerticalNotifier(this.items);

  @override
  AsyncValue<List<dynamic>> build() => AsyncValue.data(items);
}

List<Map<String, dynamic>> _sampleVerticals() => [
      {
        'id': 'vert-1',
        'name': 'Restaurants',
        'nameAr': 'مطاعم',
        'isActive': true,
        '_count': {'vendors': 6},
        'vendors': [
          {
            'id': 'v-1',
            'storeName': 'Koshary El Tahrir',
            'storeNameAr': 'كشري التحرير',
            'status': 'OPEN',
            'isContracted': true,
            'coverImage': '/media/vendors/covers/koshary.webp',
            '_count': {'branches': 3},
          },
          {
            'id': 'v-2',
            'storeName': 'B.Laban',
            'storeNameAr': 'بـ لبن',
            'status': 'OPEN',
            'isContracted': false,
            '_count': {'branches': 1},
          },
          {
            'id': 'v-3',
            'storeName': 'Bazooka',
            'storeNameAr': 'بازوكا',
            'status': 'CLOSED',
            'isContracted': true,
            '_count': {'branches': 2},
          },
          {
            'id': 'v-4',
            'storeName': 'Heart Attack',
            'storeNameAr': 'هارت أتاك',
            'status': 'PAUSED',
            'isContracted': false,
            '_count': {'branches': 1},
          },
          {
            'id': 'v-5',
            'storeName': 'Buffalo Burger',
            'storeNameAr': 'بافلو برجر',
            'status': 'OPEN',
            'isContracted': true,
            '_count': {'branches': 4},
          },
          {
            'id': 'v-6',
            'storeName': 'El Dahan',
            'storeNameAr': 'الدهان',
            'status': 'OPEN',
            'isContracted': true,
            '_count': {'branches': 2},
          },
        ],
      },
      {
        'id': 'vert-2',
        'name': 'Pharmacies',
        'nameAr': 'صيدليات',
        'isActive': true,
        '_count': {'vendors': 0},
        'vendors': const [],
      },
    ];

Widget _buildTestApp({
  required Locale locale,
  required List<dynamic> verticals,
}) {
  return ProviderScope(
    overrides: [
      verticalProvider.overrideWith(() => _FakeVerticalNotifier(verticals)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Directionality(
        textDirection:
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: VerticalsScreen(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'VerticalsScreen stays compact without inline vendor clutter and opens searchable modal when clicking vendors button',
    (tester) async {
      tester.view.physicalSize = const Size(430, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('en'),
          verticals: _sampleVerticals(),
        ),
      );
      await tester.pumpAndSettle();

      // Compact cards: show vendor count badges without inline vendor list clutter
      expect(find.text('6 Vendors'), findsOneWidget);
      expect(find.text('0 Vendors'), findsOneWidget);
      expect(find.text('Koshary El Tahrir'), findsNothing);
      expect(find.text('El Dahan'), findsNothing);

      // Tap "6 Vendors" button -> opens vendors modal
      await tester.tap(find.byKey(const ValueKey('vertical_vendors_toggle_vert-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('vertical_vendors_modal_vert-1')),
        findsOneWidget,
      );
      expect(find.text('Assigned Vendors (6)'), findsOneWidget);
      expect(find.text('Koshary El Tahrir'), findsOneWidget);
      expect(find.text('3 branches'), findsOneWidget);
      expect(find.text('Contracted'), findsWidgets);

      // Search inside the modal filters directly to El Dahan
      await tester.enterText(
        find.byKey(const ValueKey('vertical_vendors_modal_search_vert-1')),
        'El Dahan',
      );
      await tester.pumpAndSettle();

      final modalList = find.descendant(
        of: find.byKey(const ValueKey('vertical_vendors_modal_vert-1')),
        matching: find.byType(ListView),
      );
      expect(
        find.descendant(of: modalList, matching: find.text('El Dahan')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: modalList, matching: find.text('Koshary El Tahrir')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'VerticalsScreen opens vendors modal cleanly in Arabic RTL on narrow mobile width without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('ar'),
          verticals: _sampleVerticals(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مطاعم'), findsOneWidget);
      expect(find.text('6 متاجر'), findsOneWidget);
      expect(find.text('لا توجد متاجر'), findsOneWidget);
      expect(find.text('كشري التحرير'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('vertical_vendors_toggle_vert-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('vertical_vendors_modal_vert-1')),
        findsOneWidget,
      );
      expect(find.text('المتاجر المضافة (6)'), findsOneWidget);
      expect(find.text('كشري التحرير'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
