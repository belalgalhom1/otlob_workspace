import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

// Valid 1x1 transparent PNG bytes so Image.asset renders cleanly in pure ui_kit tests.
final Uint8List _kTransparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _FakePngAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec()
          .encodeMessage(<Object, Object>{})!;
    }
    if (key == 'AssetManifest.json') {
      return ByteData.sublistView(Uint8List.fromList(utf8.encode('{}')));
    }
    return ByteData.sublistView(_kTransparentPng);
  }
}

void main() {
  tearDown(OtlobLoginEntranceCoordinator.reset);

  test('OtlobLoginEntranceCoordinator marks, reads, consumes, and resets cleanly', () {
    expect(OtlobLoginEntranceCoordinator.isPendingFromSplash, isFalse);
    OtlobLoginEntranceCoordinator.markFromSplash();
    expect(OtlobLoginEntranceCoordinator.isPendingFromSplash, isTrue);
    expect(OtlobLoginEntranceCoordinator.consumeFromSplash(), isTrue);
    expect(OtlobLoginEntranceCoordinator.isPendingFromSplash, isFalse);
    expect(OtlobLoginEntranceCoordinator.consumeFromSplash(), isFalse);
  });

  testWidgets(
    'Splash spins upright -> Hero moves continuously -> Celebration starts INSIDE Login only after Hero finishes -> Preserves original login child',
    (tester) async {
      final spinKey = GlobalKey<OtlobSplashSpinLogoState>();

      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakePngAssetBundle(),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OtlobSplashSpinLogo(
                        key: spinKey,
                        child: Image.asset(
                          'assets/logo_without_background.png',
                          width: 130,
                          height: 130,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          OtlobLoginEntranceCoordinator.markFromSplash();
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder<void>(
                              transitionDuration:
                                  OtlobSplashToLoginTransition.heroFlightDuration,
                              pageBuilder: (ctx, anim, secAnim) => Scaffold(
                                body: OtlobLoginWelcomeOverlay(
                                  child: SafeArea(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          OtlobBrandHeroLogo(
                                            child: Image.asset(
                                              'assets/logo.png',
                                              height: 120,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          const TextField(
                                            key: ValueKey('email-field'),
                                          ),
                                          ElevatedButton(
                                            key: const ValueKey('login-btn'),
                                            onPressed: () {},
                                            child: const Text('Sign In'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              transitionsBuilder: OtlobSplashToLoginTransition
                                  .buildPageTransition,
                            ),
                          );
                        },
                        child: const Text('GO'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Step 1: Wait for Splash spin animation to finish (~3.9s) and settle upright.
      final settleFuture =
          spinKey.currentState!.waitForSpinAndSettle(Future<void>.value());
      await tester.pumpAndSettle();
      await settleFuture;

      // Step 2: Trigger Splash -> Login transition while Hero flies across screen.
      await tester.tap(find.text('GO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Mid-Hero flight: overlay exists, Hero logo is moving, and celebration
      // has NOT started yet because the Hero transition is still in progress.
      final overlayState = tester.state<OtlobLoginWelcomeOverlayState>(
        find.byType(OtlobLoginWelcomeOverlay),
      );
      expect(overlayState.entranceController.value, 0.0);
      expect(overlayState.effectsController.value, 0.0);
      expect(find.byType(Hero), findsWidgets);

      // Step 3 -> Step 4: Finish Hero transition cleanly, then let the
      // compact WELCOME TO OTLOB sign, velvet ropes, full-screen confetti &
      // sparkles start while interactive controls remain usable above background effects.
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        overlayState.entranceController.isAnimating ||
            overlayState.entranceController.value > 0.0,
        isTrue,
      );

      await tester.pump(const Duration(milliseconds: 900));
      expect(overlayState.effectsController.isAnimating, isTrue);

      // Verify full-screen celebration layer covers entire viewport and sits BEHIND form child.
      final overlayStack = tester.widget<Stack>(
        find.descendant(
          of: find.byType(OtlobLoginWelcomeOverlay),
          matching: find.byType(Stack),
        ).first,
      );
      expect(overlayStack.children.first, isA<Positioned>());
      final bgPaintSize = tester.getSize(
        find.descendant(
          of: find.byType(OtlobLoginWelcomeOverlay),
          matching: find.byType(CustomPaint),
        ).first,
      );
      expect(bgPaintSize, const Size(360, 740));

      // Verify typing & tapping work seamlessly while full-screen confetti/sparkles run.
      await tester.enterText(
        find.byKey(const ValueKey('email-field')),
        'user@otlob.com',
      );
      await tester.tap(find.byKey(const ValueKey('login-btn')));
      await tester.pump();
      expect(find.text('user@otlob.com'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(overlayState.entranceController.value, 1.0);
      expect(overlayState.effectsController.value, 1.0);
      expect(find.text('WELCOME TO OTLOB'), findsOneWidget);
      expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-btn')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'OtlobLoginWelcomeOverlay pauses active animations on app lifecycle pause and skips motion when disableAnimations is true',
    (tester) async {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakePngAssetBundle(),
          child: MaterialApp(
            home: Scaffold(
              body: OtlobLoginWelcomeOverlay(
                forceAnimateCelebration: true,
                child: Center(
                  child: OtlobBrandHeroLogo(
                    child: Image.asset('assets/logo.png', height: 120),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final overlayState = tester.state<OtlobLoginWelcomeOverlayState>(
        find.byType(OtlobLoginWelcomeOverlay),
      );
      expect(overlayState.entranceController.isAnimating, isTrue);

      TestWidgetsFlutterBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(overlayState.entranceController.isAnimating, isFalse);

      TestWidgetsFlutterBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(overlayState.entranceController.value, 1.0);

      // Reduced motion settles immediately without animating.
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakePngAssetBundle(),
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: OtlobLoginWelcomeOverlay(
                  forceAnimateCelebration: true,
                  child: Center(child: Text('Login Form')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final reducedState = tester.state<OtlobLoginWelcomeOverlayState>(
        find.byType(OtlobLoginWelcomeOverlay),
      );
      expect(reducedState.entranceController.value, 1.0);
      expect(reducedState.effectsController.value, 1.0);
      expect(reducedState.entranceController.isAnimating, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
    for (final viewport in [const Size(320, 568), const Size(360, 740)]) {
      testWidgets(
        'OtlobLoginWelcomeOverlay renders cleanly at ${viewport.width.toInt()}x${viewport.height.toInt()} (${themeMode.name}) with 1.3x TextScaler',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            DefaultAssetBundle(
              bundle: _FakePngAssetBundle(),
              child: MaterialApp(
                themeMode: themeMode,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: viewport,
                    padding: const EdgeInsets.only(top: 44, bottom: 34),
                    textScaler: const TextScaler.linear(1.3),
                  ),
                  child: Scaffold(
                    body: Builder(
                      builder: (ctx) {
                        final topClearance =
                            OtlobLoginWelcomeOverlay.recommendedTopClearance(
                          ctx,
                          gap: 16,
                        );
                        return OtlobLoginWelcomeOverlay(
                          forceAnimateCelebration: true,
                          child: SafeArea(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                topClearance,
                                16,
                                16,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OtlobBrandHeroLogo(
                                      child: Image.asset(
                                        'assets/logo.png',
                                        height: 120,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const TextField(),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {},
                                      child: const Text('Sign In'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('WELCOME TO OTLOB'), findsOneWidget);
          expect(find.text('Sign In'), findsOneWidget);

          final signRect = tester.getRect(
            find
                .ancestor(
                  of: find.text('WELCOME TO OTLOB'),
                  matching: find.byType(Container),
                )
                .first,
          );
          final logoRect = tester.getRect(find.byType(OtlobBrandHeroLogo));
          expect(signRect.bottom, lessThanOrEqualTo(logoRect.top));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
