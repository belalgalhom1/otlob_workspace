import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/legal/presentation/legal_document_viewer_page.dart';
import 'package:vendor/features/legal/presentation/legal_documents_provider.dart';
import 'package:vendor/features/legal/presentation/legal_documents_screen.dart';
import 'package:vendor/features/legal/presentation/terms_acceptance_gate_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeVendorLegalRepo extends Fake
    implements SharedLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getActiveDocument(String type) async {
    return {
      'id': 'vnd-doc-$type',
      'type': type,
      'version': '2.1',
      'title': 'Vendor Partner Terms',
      'titleAr': 'شروط شركاء التجار',
      'content': '''
# Vendor Merchant Terms
### 1. Commission & Settlement
Review **commission deductions and payout cycles** carefully.
> Orders must be confirmed within SLA timeouts.
- Keep menu stock accurate.
1. Verify invoice totals.
''',
      'contentAr': '''
# شروط شركاء التجار
### ١. العمولات والتسويات
راجع **خصومات العمولة ودورات التحويل** بعناية.
> يجب تأكيد الطلبات ضمن المدة المحددة.
- حافظ على دقة المخزون والأسعار.
1. راجع تفاصيل الفواتير.
''',
      'publishedAt': '2026-11-15T12:00:00Z',
    };
  }
}

class _FakeAdminLegalRepo extends Fake
    implements AdminLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getDocumentById(String id) async {
    return {
      'id': id,
      'type': 'TERMS_OF_USE',
      'version': '2.1',
      'title': 'Vendor Platform Terms 2.1',
      'titleAr': 'شروط منصة التجار 2.1',
      'content':
          '# Terms\n### Clause 1\n**Platform terms content** for verification.',
      'contentAr': '# الشروط\n### البند ١\n**محتوى شروط المنصة** للمراجعة.',
      'isPublished': true,
      'acceptanceCount': 482,
      'publishedAt': '2026-11-15T10:00:00Z',
    };
  }
}

class _FakeLegalDocsNotifier extends LegalDocumentsNotifier {
  @override
  LegalDocumentsState build() => const LegalDocumentsState(
        isLoading: false,
        termsDocuments: [
          {
            'id': 'doc-terms-1',
            'type': 'TERMS_OF_USE',
            'title': 'Vendor Platform Terms 2.1',
            'titleAr': 'شروط منصة التجار 2.1',
            'content': '### Clause 1\n**Platform terms content.**',
            'contentAr': '### البند ١\n**محتوى شروط المنصة.**',
            'version': '2.1',
            'isPublished': true,
            'acceptanceCount': 482,
            'publishedAt': '2026-11-15T10:00:00Z',
          },
        ],
        privacyDocuments: [],
      );

  @override
  Future<void> fetchAllDocuments() async {}

  @override
  Future<Map<String, dynamic>?> fetchDocumentStats(String id) async {
    return {
      'totalAcceptances': 482,
      'roleBreakdown': {
        'CUSTOMER': 150,
        'DRIVER': 20,
        'VENDOR_MEMBER': 300,
        'ADMIN': 10,
        'SUPER_ADMIN': 2,
      },
    };
  }
}

Future<void> _pumpVendorPage(
  WidgetTester tester, {
  required Widget child,
  required Locale locale,
  ThemeData? theme,
  Size viewport = const Size(320, 568),
  EdgeInsets padding = const EdgeInsets.only(top: 59, bottom: 34),
  TextScaler textScaler = const TextScaler.linear(1.3),
  List<dynamic> extraOverrides = const [],
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        data_providers.sharedLegalDocumentsRepositoryProvider
            .overrideWithValue(_FakeVendorLegalRepo()),
        ...extraOverrides,
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (_, appChild) => MediaQuery(
          data: MediaQueryData(
            size: viewport,
            padding: padding,
            textScaler: textScaler,
          ),
          child: AppWindowConstraintGuard(
            child: appChild ?? const SizedBox.shrink(),
          ),
        ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final brightness in Brightness.values) {
      for (final viewport in const [Size(320, 568), Size(800, 900)]) {
        testWidgets(
          'Vendor TermsAcceptanceGateScreen matches AppDialog Slate style & SafeArea at ${viewport.width.toInt()}x${viewport.height.toInt()} (${brightness.name}/${locale.languageCode})',
          (tester) async {
            final isDark = brightness == Brightness.dark;
            final pad = viewport.width < 600
                ? const EdgeInsets.only(top: 59, bottom: 34)
                : EdgeInsets.zero;

            await _pumpVendorPage(
              tester,
              locale: locale,
              viewport: viewport,
              padding: pad,
              theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
              child: const TermsAcceptanceGateScreen(),
            );

            expect(tester.takeException(), isNull);
            final termsWidget = tester.widget<TermsAcceptanceDialog>(
              find.byType(TermsAcceptanceDialog),
            );
            expect(termsWidget.variant, TermsDialogVariant.vendor);

            final dialogWidget = tester.widget<Dialog>(find.byType(Dialog));
            expect(
              dialogWidget.backgroundColor,
              isDark ? AppColors.surfaceDark : Colors.white,
            );
            final shape = dialogWidget.shape as RoundedRectangleBorder;
            expect(shape.borderRadius, BorderRadius.circular(18));
            expect(
              shape.side.color,
              isDark ? AppColors.borderDark : AppColors.borderLight,
            );

            final cardRect = tester.getRect(
              find
                  .descendant(
                    of: find.byType(Dialog),
                    matching: find.byType(Material),
                  )
                  .first,
            );
            expect(cardRect.top, greaterThanOrEqualTo(pad.top));
            expect(cardRect.bottom, lessThanOrEqualTo(viewport.height - pad.bottom));
          },
        );
      }
    }

    testWidgets(
      'Vendor LegalDocumentViewerPage uses SafeArea & Slate toggle pill at 320x568 1.3x (${locale.languageCode})',
      (tester) async {
        await _pumpVendorPage(
          tester,
          locale: locale,
          child: const LegalDocumentViewerPage(type: 'TERMS_OF_USE'),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(LegalDocumentView), findsOneWidget);
        final safeAreaFinder = find.ancestor(
          of: find.byType(LegalDocumentView),
          matching: find.byType(SafeArea),
        );
        expect(safeAreaFinder, findsWidgets);
      },
    );
  }

  testWidgets(
    'Vendor Terms decline opens AppConfirmDialog in Slate dark theme without overflow on 320x568 1.3x',
    (tester) async {
      await _pumpVendorPage(
        tester,
        locale: const Locale('en'),
        theme: AppTheme.darkTheme,
        child: const TermsAcceptanceGateScreen(),
      );

      final declineFinder = find.descendant(
        of: find.byType(OutlinedButton),
        matching: find.byType(Text),
      );
      await tester.ensureVisible(declineFinder.first);
      await tester.tap(declineFinder.first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Dialog), findsNWidgets(2));
      final confirmDialog = tester.widget<Dialog>(find.byType(Dialog).last);
      expect(confirmDialog.backgroundColor, AppColors.surfaceDark);
    },
  );

  testWidgets(
    'Vendor LegalDocumentsScreen admin Preview, Metrics, and New Draft dialogs render cleanly at 320x640 and 1.3x scale',
    (tester) async {
      await _pumpVendorPage(
        tester,
        locale: const Locale('en'),
        viewport: const Size(320, 640),
        padding: const EdgeInsets.only(top: 47, bottom: 34),
        theme: AppTheme.darkTheme,
        extraOverrides: [
          data_providers.adminLegalDocumentsRepositoryProvider
              .overrideWithValue(_FakeAdminLegalRepo()),
          legalDocumentsProvider.overrideWith(_FakeLegalDocsNotifier.new),
        ],
        child: const Scaffold(
          body: SafeArea(child: LegalDocumentsScreen()),
        ),
      );

      final firstEx = tester.takeException();
      expect(firstEx, isNull, reason: firstEx?.toString());

      // 1. Open New Version Draft form dialog while header is visible
      final draftBtn = find.text('New Version Draft');
      expect(draftBtn, findsOneWidget);
      await tester.ensureVisible(draftBtn);
      await tester.tap(draftBtn);
      await tester.pumpAndSettle();
      final formEx = tester.takeException();
      expect(formEx, isNull, reason: formEx?.toString());
      expect(find.byType(AppDialog), findsOneWidget);
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      // 2. Collapse NestedScrollView header so active banner buttons are in view
      await tester.drag(
        find.byType(NestedScrollView),
        const Offset(0, -450),
      );
      await tester.pumpAndSettle();

      // 3. Open Preview dialog
      final previewBtn = find.text('Preview');
      expect(previewBtn, findsWidgets);
      await tester.ensureVisible(previewBtn.first);
      await tester.pumpAndSettle();
      await tester.tap(previewBtn.first);
      await tester.pumpAndSettle();
      final previewEx = tester.takeException();
      expect(previewEx, isNull, reason: previewEx?.toString());
      expect(find.byType(AppDialog), findsOneWidget);
      await tester.tap(find.text('Close').last);
      await tester.pumpAndSettle();

      // 4. Open Metrics / Stats dialog
      final metricsBtn = find.text('Metrics');
      expect(metricsBtn, findsOneWidget);
      await tester.ensureVisible(metricsBtn);
      await tester.tap(metricsBtn);
      await tester.pumpAndSettle();
      final statsEx = tester.takeException();
      expect(statsEx, isNull, reason: statsEx?.toString());
      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text('482'), findsOneWidget);
      await tester.tap(find.text('Close').last);
      await tester.pumpAndSettle();

      // 5. Scroll header back into view and switch to Privacy Policy tab (empty state)
      await tester.drag(
        find.byType(NestedScrollView),
        const Offset(0, 450),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      final tabEx = tester.takeException();
      expect(tabEx, isNull, reason: tabEx?.toString());
    },
  );
}
