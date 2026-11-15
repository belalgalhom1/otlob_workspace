import 'dart:convert';
import 'dart:io';

import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/core/widgets/auth_prompt_dialog.dart';
import 'package:otlob_customer/features/chat/presentation/pages/inbox_screen.dart';
import 'package:otlob_customer/features/legal/presentation/pages/terms_acceptance_gate_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit/ui_kit.dart';

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

class _FakeSharedInbox extends data_providers.SharedInbox {
  @override
  data_providers.InboxState build() {
    return data_providers.InboxState(
      conversations: const [],
      isLoading: false,
      hasMore: false,
    );
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}

class _FailingLegalDocsRepo extends Fake
    implements SharedLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getActiveDocument(String type) async {
    throw Exception('network error');
  }
}

Future<void> _pumpCustomerWidget(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
  List<dynamic> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  tester.view.physicalSize = const Size(360, 640);
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
        overrides: [...overrides],
        child: Builder(
          builder: (context) {
            return MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(360, 640),
                  padding: EdgeInsets.only(top: 47, bottom: 34),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: AppWindowConstraintGuard(child: child),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'AuthPromptDialog renders without overflow under SafeArea & 1.3x text scale (${locale.languageCode})',
      (tester) async {
        await _pumpCustomerWidget(
          tester,
          locale: locale,
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => AuthPromptDialog.show(context),
                  child: const Text('OPEN_SHEET'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('OPEN_SHEET'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AuthPromptDialog), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      },
    );

    testWidgets(
      'InboxScreen filter chips wrap cleanly under 1.3x text scale on 360px (${locale.languageCode})',
      (tester) async {
        await _pumpCustomerWidget(
          tester,
          locale: locale,
          overrides: [
            data_providers.sharedInboxProvider.overrideWith(
              _FakeSharedInbox.new,
            ),
          ],
          child: const InboxScreen(),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ChoiceChip), findsNWidgets(3));
        expect(find.byType(Wrap), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Customer TermsAcceptanceGateScreen error view respects SafeArea & 1.3x scale',
    (tester) async {
      await _pumpCustomerWidget(
        tester,
        locale: const Locale('ar'),
        overrides: [
          sharedLegalDocumentsRepositoryProvider.overrideWithValue(
            _FailingLegalDocsRepo(),
          ),
        ],
        child: const TermsAcceptanceGateScreen(),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.text('تسجيل الخروج'), findsOneWidget);

      final scrollRect = tester.getRect(find.byType(SingleChildScrollView));
      expect(scrollRect.top, greaterThanOrEqualTo(47.0));
      expect(scrollRect.bottom, lessThanOrEqualTo(640.0 - 34.0));
    },
  );
}
