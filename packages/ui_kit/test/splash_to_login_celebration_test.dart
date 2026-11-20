import 'dart:convert';
import 'dart:typed_data';

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
    'Splash spins upright -> Hero moves continuously -> Celebration starts INSIDE Login only after Hero finishes -> Form appears cleanly',
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
                        assetPath: 'assets/logo_without_background.png',
                        size: 130,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          OtlobLoginEntranceCoordinator.markFromSplash();
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder<void>(
                              transitionDuration:
                                  OtlobSplashToLoginTransition.heroFlightDuration,
                              pageBuilder: (ctx, anim, secAnim) => Scaffold(
                                body: OtlobWelcomeLoginShell(
                                  logoAssetPath:
                                      'assets/logo_without_background.png',
                                  appLabel: 'OTLOB',
                                  welcomeSubLabel: 'Welcome',
                                  formChild: Column(
                                    children: [
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

      // Step 1: Wait for Splash spin animation to finish and settle upright.
      final settleFuture =
          spinKey.currentState!.waitForSpinAndSettle(Future<void>.value());
      await tester.pumpAndSettle();
      await settleFuture;

      // Step 2: Trigger Splash -> Login transition while Hero flies across screen.
      await tester.tap(find.text('GO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Mid-Hero flight: Login shell exists, Hero logo is moving, and celebration
      // has NOT started yet because the Hero transition is still in progress.
      final shellState = tester.state<OtlobWelcomeLoginShellState>(
        find.byType(OtlobWelcomeLoginShell),
      );
      expect(shellState.celebrationController.value, 0.0);
      expect(find.byType(Hero), findsWidgets);

      // Step 3 -> Step 4 -> Step 5: Finish Hero transition cleanly, then let
      // Welcome Celebration ("WELCOME TO OTLOB" sign, ropes, podium, balloons,
      // confetti/sparkles) & Login Form settle inside Login screen.
      await tester.pump(const Duration(milliseconds: 600));
      expect(shellState.celebrationController.isAnimating ||
          shellState.celebrationController.value > 0.0, isTrue);

      await tester.pumpAndSettle();
      expect(shellState.celebrationController.value, 1.0);
      expect(find.text('WELCOME TO OTLOB'), findsOneWidget);
      expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-btn')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
    for (final viewport in [const Size(320, 568), const Size(360, 740)]) {
      testWidgets(
        'OtlobWelcomeLoginShell renders cleanly at ${viewport.width.toInt()}x${viewport.height.toInt()} (${themeMode.name}) with 1.3x TextScaler',
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
                    body: OtlobWelcomeLoginShell(
                      logoAssetPath: 'assets/logo_without_background.png',
                      appLabel: 'Otlob Driver',
                      welcomeSubLabel: 'بوابة السائقين',
                      formChild: Column(
                        children: [
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
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('WELCOME TO OTLOB'), findsOneWidget);
          expect(find.text('Sign In'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
