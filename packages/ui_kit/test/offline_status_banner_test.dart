import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('OfflineStatusBanner Widget', () {
    testWidgets('renders red offline banner with retry button when offline', (tester) async {
      bool retryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineStatusBanner(
              isOnline: false,
              offlineMessage: 'No Internet Connection',
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retryTapped, isTrue);
    });

    testWidgets('transitions to green back online banner when connection is restored', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStatusBanner(
              isOnline: false,
              offlineMessage: 'No Internet Connection',
              onlineMessage: 'Back Online',
            ),
          ),
        ),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);

      // Transition to online
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStatusBanner(
              isOnline: true,
              offlineMessage: 'No Internet Connection',
              onlineMessage: 'Back Online',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Back Online'), findsOneWidget);

      // Fast-forward past 2.2s toast delay + 300ms animation
      await tester.pump(const Duration(milliseconds: 2300));
      await tester.pump(const Duration(milliseconds: 350));

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('renders Arabic localization properly without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: OfflineStatusBanner(
                isOnline: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    });
  });
}
