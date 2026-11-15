import 'dart:convert';
import 'dart:io';

import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otlob_customer/core/router/route_paths.dart';
import 'package:otlob_customer/core/services/token_service.dart';
import 'package:otlob_customer/core/widgets/auth_prompt_dialog.dart';
import 'package:otlob_customer/core/widgets/floating_cart_overlay.dart';
import 'package:otlob_customer/features/auth/presentation/pages/login_screen.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/cart/presentation/providers/cart_controller.dart';
import 'package:otlob_customer/features/chat/presentation/pages/inbox_screen.dart';
import 'package:otlob_customer/features/legal/presentation/pages/terms_acceptance_gate_screen.dart';
import 'package:otlob_customer/features/onboarding/presentation/pages/onboarding_screen.dart';
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

class _FakeTokenService extends Fake implements TokenService {
  @override
  Future<Map<String, String>?> getSavedProfile() async => null;

  @override
  Future<void> clearTokens() async {}
}

class _FakeAuthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;
}

class _FakeCart extends Cart {
  final CartState initialState;
  _FakeCart(this.initialState);

  @override
  CartState build() => initialState;
}

Future<void> _pumpCustomerWidget(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
  Size viewport = const Size(360, 640),
  EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  TextScaler textScaler = const TextScaler.linear(1.3),
  List<dynamic> overrides = const [],
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
        overrides: [...overrides],
        child: Builder(
          builder: (context) {
            return MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: MediaQuery(
                data: MediaQueryData(
                  size: viewport,
                  padding: padding,
                  textScaler: textScaler,
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

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'FloatingCartOverlay clamps 1.6x textScaler to 1.3x and respects SafeArea on 320x568 (${locale.languageCode})',
      (tester) async {
        final fakeCartState = CartState(
          isLoading: false,
          vendorBaskets: {
            'v1': [
              CartItem(
                product: const CartProductRef(
                  id: 'p1',
                  vendorId: 'v1',
                  vendorName: 'Test Kitchen',
                  name: 'Family Grill Meal',
                  nameAr: 'وجبة مشويات عائلية',
                  price: 245.50,
                  isActive: true,
                  tracksStock: false,
                ),
                quantity: 2,
              ),
            ],
          },
        );

        await _pumpCustomerWidget(
          tester,
          locale: locale,
          viewport: const Size(320, 568),
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: const TextScaler.linear(1.6),
          overrides: [
            cartProvider.overrideWith(() => _FakeCart(fakeCartState)),
          ],
          child: const Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: SizedBox.shrink()),
                FloatingCartOverlay(),
              ],
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final overlayRect = tester.getRect(find.byType(FloatingCartOverlay));
        expect(overlayRect.left, greaterThanOrEqualTo(0));
        expect(overlayRect.right, lessThanOrEqualTo(320));
        final pillFinder = find.ancestor(
          of: find.textContaining('491.00'),
          matching: find.byType(GestureDetector),
        );
        expect(pillFinder, findsWidgets);
        final pillContext = tester.element(find.textContaining('491.00').first);
        expect(MediaQuery.textScalerOf(pillContext).scale(10), closeTo(13.0, 0.01));
      },
    );

    testWidgets(
      'OnboardingScreen renders without overflow on 320x568 at 1.3x scale with SafeArea (${locale.languageCode})',
      (tester) async {
        await _pumpCustomerWidget(
          tester,
          locale: locale,
          viewport: const Size(320, 568),
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: const TextScaler.linear(1.3),
          child: const OnboardingScreen(),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ElevatedButton), findsOneWidget);
      },
    );

    for (final entry in const [
      (viewport: Size(320, 568), scale: 0.85),
      (viewport: Size(360, 640), scale: 1.3),
      (viewport: Size(800, 900), scale: 1.3),
    ]) {
      testWidgets(
        'Customer LoginScreen renders cleanly at ${entry.viewport.width.toInt()}x${entry.viewport.height.toInt()} & ${entry.scale}x (${locale.languageCode})',
        (tester) async {
          final router = GoRouter(
            initialLocation: RoutePaths.login,
            routes: [
              GoRoute(
                path: RoutePaths.login,
                builder: (_, _) => const LoginScreen(),
              ),
            ],
          );
          addTearDown(router.dispose);

          SharedPreferences.setMockInitialValues({});
          await EasyLocalization.ensureInitialized();
          tester.view.physicalSize = entry.viewport;
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
                  authControllerProvider.overrideWith(() => _FakeAuthController()),
                  tokenServiceProvider.overrideWithValue(
                    _FakeTokenService(),
                  ),
                ],
                child: Builder(
                  builder: (context) => MaterialApp.router(
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: context.locale,
                    routerConfig: router,
                    builder: (ctx, child) => MediaQuery(
                      data: MediaQueryData(
                        size: entry.viewport,
                        padding: const EdgeInsets.only(top: 59, bottom: 34),
                        textScaler: TextScaler.linear(entry.scale),
                      ),
                      child: AppWindowConstraintGuard(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(LoginScreen), findsOneWidget);
        },
      );
    }
  }
}
