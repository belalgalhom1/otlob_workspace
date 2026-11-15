import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('SocialAuthButton', () {
    testWidgets('renders icon, label, and triggers onPressed when enabled', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialAuthButton(
              icon: const Icon(Icons.apple),
              label: 'Continue with Apple',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.apple), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.getSize(find.byType(SocialAuthButton)).height, 56);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SocialAuthButton(
              icon: Icon(Icons.apple),
              label: 'Continue with Apple',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows loading spinner instead of content when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SocialAuthButton(
              icon: Icon(Icons.apple),
              label: 'Continue with Apple',
              isLoading: true,
              height: 50,
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsNothing);
      expect(find.text('Continue with Apple'), findsNothing);
      expect(tester.getSize(find.byType(SocialAuthButton)).height, 50);
    });

    testWidgets('renders cleanly without overflow in EN/LTR and AR/RTL narrow layouts', (
      tester,
    ) async {
      for (final entry in [
        (
          direction: TextDirection.ltr,
          label: 'Continue with Apple and extra descriptive copy for narrow viewport',
        ),
        (
          direction: TextDirection.rtl,
          label: 'المتابعة عبر Apple مع نص طويل للتحقق من عدم حدوث تجاوز في العرض',
        ),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: entry.direction,
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 240,
                    child: SocialAuthButton(
                      icon: const Icon(Icons.apple),
                      label: entry.label,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.apple), findsOneWidget);
        expect(find.text(entry.label), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
