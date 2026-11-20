import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  testWidgets(
    'AppExpandableText hides Read more when description fits within trimLines',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: AppExpandableText(
                text: 'Freshly grilled burgers every day.',
                trimLines: 3,
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Freshly grilled burgers every day.'), findsOneWidget);
      expect(find.text('Read more'), findsNothing);
      expect(find.text('Read less'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AppExpandableText truncates long multi-line text, expands smoothly on Read more, and collapses on Read less',
    (tester) async {
      const longDescription =
          'Burger King Restaurant\n'
          'Our burgers are fresh every day, straight from the grill.\n'
          'Cleanliness, perfect taste, and affordable prices.\n'
          'We have everything you crave: burgers, crispy chicken, fries, and meals for the whole family.\n'
          'Come and try it yourself, and the taste will speak for itself.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: 320,
                child: AppExpandableText(
                  text: longDescription,
                  trimLines: 3,
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Read more'), findsOneWidget);
      expect(find.text('Read less'), findsNothing);
      final initialText = tester.widget<Text>(find.text(longDescription));
      expect(initialText.maxLines, 3);
      final collapsedHeight =
          tester.getSize(find.byType(AppExpandableText)).height;

      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();

      expect(find.text('Read less'), findsOneWidget);
      expect(find.text('Read more'), findsNothing);
      final expandedText = tester.widget<Text>(find.text(longDescription));
      expect(expandedText.maxLines, isNull);
      final expandedHeight =
          tester.getSize(find.byType(AppExpandableText)).height;
      expect(expandedHeight, greaterThan(collapsedHeight));

      await tester.tap(find.text('Read less'));
      await tester.pumpAndSettle();

      expect(find.text('Read more'), findsOneWidget);
      expect(find.text('Read less'), findsNothing);
      final recollapsedHeight =
          tester.getSize(find.byType(AppExpandableText)).height;
      expect(recollapsedHeight, collapsedHeight);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AppExpandableText supports Arabic RTL and 1.3x TextScaler cleanly',
    (tester) async {
      const arabicLong =
          'أهلاً بكم في مطعمنا المتخصص في البرجر المشوي على الفحم يومياً.\n'
          'نقدم لكم أجود أنواع اللحوم الطازجة والخبز المحضر يومياً مع البطاطس المقرمشة.\n'
          'تشكيلة متكاملة من الوجبات العائلية والسندوتشات والصوصات المميزة بأسعار مناسبة للجميع.';

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: AppExpandableText(
                    text: arabicLong,
                    trimLines: 3,
                    style: TextStyle(fontSize: 16, height: 1.45),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('اقرأ المزيد'), findsOneWidget);
      await tester.tap(find.text('اقرأ المزيد'));
      await tester.pumpAndSettle();
      expect(find.text('عرض أقل'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AppExpandableText renders nothing on empty text and resets expansion when text changes',
    (tester) async {
      const longA =
          'Line 1\nLine 2\nLine 3\nLine 4 extra text that overflows 3 lines.';
      const longB =
          'Other Store Line 1\nOther Store Line 2\nOther Store Line 3\nOther Store Line 4 overflows too.';

      Widget buildHarness(String value) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: AppExpandableText(
                  text: value,
                  trimLines: 3,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          );

      await tester.pumpWidget(buildHarness('   '));
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsNothing);

      await tester.pumpWidget(buildHarness(longA));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();
      expect(find.text('Read less'), findsOneWidget);

      await tester.pumpWidget(buildHarness(longB));
      await tester.pumpAndSettle();
      expect(find.text('Read more'), findsOneWidget);
      expect(find.text('Read less'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
