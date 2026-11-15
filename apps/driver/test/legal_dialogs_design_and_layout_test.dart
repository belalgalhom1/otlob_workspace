import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:driver/features/legal/presentation/pages/legal_document_viewer_page.dart';
import 'package:driver/features/legal/presentation/pages/terms_acceptance_gate_screen.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

class _FakeDriverLegalRepo extends Fake
    implements SharedLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getActiveDocument(String type) async {
    return {
      'id': 'drv-doc-$type',
      'type': type,
      'version': '2.0',
      'title': type == 'PRIVACY_POLICY'
          ? 'Driver Privacy Policy'
          : 'Driver Service Agreement',
      'titleAr': type == 'PRIVACY_POLICY'
          ? 'سياسة خصوصية السائقين'
          : 'اتفاقية خدمة السائقين',
      'content': '''
# Driver Operations Agreement
### 1. Shift & Dispatch Rules
Review your **cash settlement and delivery obligations** carefully.
> Maintain valid license & vehicle documentation at all times.
- Accept or decline dispatch offers responsibly.
1. Collect accurate COD totals.
''',
      'contentAr': '''
# اتفاقية عمليات السائقين
### ١. قواعد الورديات والتوصيل
راجع **التزامات التحصيل النقدي والتوصيل** بعناية.
> حافظ على صلاحية رخصة القيادة والمركبة في جميع الأوقات.
- تعامل مع طلبات التوصيل بمسؤولية.
1. تحصيل المبالغ النقدية بدقة.
''',
      'publishedAt': '2026-11-15T12:00:00Z',
    };
  }
}

Future<void> _pumpDriverPage(
  WidgetTester tester, {
  required Widget child,
  required Locale locale,
  ThemeData? theme,
  Size viewport = const Size(320, 568),
  EdgeInsets padding = const EdgeInsets.only(top: 59, bottom: 34),
  TextScaler textScaler = const TextScaler.linear(1.3),
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
            .overrideWithValue(_FakeDriverLegalRepo()),
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
      testWidgets(
        'Driver TermsAcceptanceGateScreen loaded dialog matches Driver Slate design, SafeArea & 1.3x (${brightness.name}/${locale.languageCode})',
        (tester) async {
          final isDark = brightness == Brightness.dark;
          await _pumpDriverPage(
            tester,
            locale: locale,
            theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
            child: const TermsAcceptanceGateScreen(),
          );

          expect(tester.takeException(), isNull);
          final termsWidget = tester.widget<TermsAcceptanceDialog>(
            find.byType(TermsAcceptanceDialog),
          );
          expect(termsWidget.variant, TermsDialogVariant.driver);

          final dialogWidget = tester.widget<Dialog>(find.byType(Dialog));
          expect(
            dialogWidget.backgroundColor,
            isDark ? AppColors.surfaceDark : Colors.white,
          );
          final shape = dialogWidget.shape as RoundedRectangleBorder;
          expect(shape.borderRadius, BorderRadius.circular(16));
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
          expect(cardRect.top, greaterThanOrEqualTo(59.0));
          expect(cardRect.bottom, lessThanOrEqualTo(568.0 - 34.0));
        },
      );
    }

    testWidgets(
      'Driver LegalDocumentViewerPage uses SafeArea & Slate toggle pill at 320x568 1.3x (${locale.languageCode})',
      (tester) async {
        await _pumpDriverPage(
          tester,
          locale: locale,
          child: const LegalDocumentViewerPage(type: 'PRIVACY_POLICY'),
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
    'Driver Terms decline opens Driver Slate AppConfirmDialog without overflow on 320x568 1.3x',
    (tester) async {
      await _pumpDriverPage(
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
      final shape = confirmDialog.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(18));
      expect(shape.side.color, AppColors.borderDark);
    },
  );
}
