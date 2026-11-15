import 'dart:convert';
import 'dart:io';

import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/core/theme/app_colors.dart';
import 'package:otlob_customer/core/theme/app_theme.dart';
import 'package:otlob_customer/features/legal/presentation/pages/legal_document_viewer_page.dart';
import 'package:otlob_customer/features/legal/presentation/pages/terms_acceptance_gate_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit/ui_kit.dart'
    show
        AppWindowConstraintGuard,
        LegalDocumentView,
        TermsAcceptanceDialog,
        TermsDialogVariant;

class _CatalogAssetLoader extends AssetLoader {
  const _CatalogAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final code = locale.languageCode;
    final p1 = '../../packages/core/assets/translations/$code.json';
    final p2 = 'packages/core/assets/translations/$code.json';
    final file = File(File(p1).existsSync() ? p1 : p2);
    if (!file.existsSync()) return {};
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

class _FakeLoadedLegalRepo extends Fake
    implements SharedLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getActiveDocument(String type) async {
    return {
      'id': 'doc-$type',
      'type': type,
      'version': '3.1',
      'title': type == 'PRIVACY_POLICY'
          ? 'Customer Privacy Policy'
          : 'Customer Terms & Conditions',
      'titleAr': type == 'PRIVACY_POLICY'
          ? 'سياسة الخصوصية للعملاء'
          : 'شروط وأحكام تطبيق العملاء',
      'content': '''
# Agreement Overview
### 1. Ordering & Delivery
All **customer orders** follow transparent delivery terms.
> Please keep delivery address details accurate.
- Pay cash or card at checkout.
1. Review cart summary carefully.
''',
      'contentAr': '''
# نظرة عامة على الاتفاقية
### ١. الطلبات والتوصيل
تخضع جميع **طلبات العملاء** لشروط توصيل واضحة وشفافة.
> يرجى التأكد من دقة عنوان التوصيل.
- الدفع نقداً أو بالبطاقة عند الإتمام.
1. راجع ملخص السلة بعناية.
''',
      'publishedAt': '2026-11-15T12:00:00Z',
    };
  }
}

Future<void> _pumpCustomerPage(
  WidgetTester tester, {
  required Widget child,
  required Locale locale,
  ThemeData? theme,
  Size viewport = const Size(320, 568),
  EdgeInsets padding = const EdgeInsets.only(top: 59, bottom: 34),
  TextScaler textScaler = const TextScaler.linear(1.3),
  SharedLegalDocumentsRepository? repo,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'translations',
      fallbackLocale: const Locale('en'),
      startLocale: locale,
      assetLoader: const _CatalogAssetLoader(),
      child: ProviderScope(
        overrides: [
          data_providers.sharedLegalDocumentsRepositoryProvider
              .overrideWithValue(repo ?? _FakeLoadedLegalRepo()),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            theme: theme ?? AppTheme.lightTheme,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
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
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'Customer TermsAcceptanceGateScreen loaded dialog matches Customer design, SafeArea & 1.3x (${brightness.name}/${locale.languageCode})',
        (tester) async {
          final isDark = brightness == Brightness.dark;
          await _pumpCustomerPage(
            tester,
            locale: locale,
            theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
            child: const TermsAcceptanceGateScreen(),
          );

          expect(tester.takeException(), isNull);
          final termsWidget = tester.widget<TermsAcceptanceDialog>(
            find.byType(TermsAcceptanceDialog),
          );
          expect(termsWidget.variant, TermsDialogVariant.customer);

          final dialogWidget = tester.widget<Dialog>(find.byType(Dialog));
          expect(
            dialogWidget.backgroundColor,
            isDark ? AppColors.surfaceDark : Colors.white,
          );
          final shape = dialogWidget.shape as RoundedRectangleBorder;
          expect(shape.borderRadius, BorderRadius.circular(22));
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
      'Customer LegalDocumentViewerPage uses SafeArea & Customer toggle at 320x568 1.3x (${locale.languageCode})',
      (tester) async {
        await _pumpCustomerPage(
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
    'Customer Terms decline opens Customer-themed AppConfirmDialog without overflow on 320x568 1.3x',
    (tester) async {
      await _pumpCustomerPage(
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
      expect(shape.borderRadius, BorderRadius.circular(22));
      expect(shape.side.color, AppColors.borderDark);
    },
  );
}
