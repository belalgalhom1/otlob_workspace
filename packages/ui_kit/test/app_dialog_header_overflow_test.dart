import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

class _ArMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _ArMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(_ArMaterialLocalizationsDelegate old) => false;
}

class _ArCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _ArCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(_ArCupertinoLocalizationsDelegate old) => false;
}

class _ArWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _ArWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<WidgetsLocalizations>(
        const DefaultWidgetsLocalizations(),
      );

  @override
  bool shouldReload(_ArWidgetsLocalizationsDelegate old) => false;
}

Widget _wrap({
  required Widget child,
  double textScale = 1.0,
  Locale locale = const Locale('en'),
  EdgeInsets padding = const EdgeInsets.only(bottom: 24, top: 24),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      _ArMaterialLocalizationsDelegate(),
      _ArCupertinoLocalizationsDelegate(),
      _ArWidgetsLocalizationsDelegate(),
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        padding: padding,
      ),
      child: Directionality(
        textDirection:
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: appChild!,
      ),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    'AppDialogHeader with badge and wide action button never wraps title letter-by-letter vertically',
    (tester) async {
      for (final config in [
        (size: const Size(320, 568), scale: 1.0, locale: const Locale('en')),
        (size: const Size(360, 640), scale: 1.3, locale: const Locale('en')),
        (size: const Size(360, 640), scale: 1.3, locale: const Locale('ar')),
        (size: const Size(800, 600), scale: 1.0, locale: const Locale('en')),
      ]) {
        await tester.binding.setSurfaceSize(config.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const titleText = 'Weekly Badge & Rank History';
        await tester.pumpWidget(
          _wrap(
            textScale: config.scale,
            locale: config.locale,
            child: AppDialog(
              scrollableBody: false,
              maxWidth: 680,
              header: AppDialogHeader(
                icon: Icons.emoji_events,
                title: titleText,
                subtitle: 'Driver Test Name',
                badge: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: const Text('Gold'),
                ),
                actions: [
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Override Badge'),
                  ),
                ],
              ),
              body: const SizedBox(height: 120),
              footer: AppDialogFooter(
                cancelLabel: 'Close',
                onCancel: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titleFinder = find.text(titleText);
        expect(titleFinder, findsOneWidget);
        final titleSize = tester.getSize(titleFinder);
        // Flutter test Ahem font uses 1em square glyphs; normal word-wrapping
        // takes ~2-4 lines (<= 145px even at 320px @ 1.3x scale), whereas the
        // squeezed 1-char-per-line bug wrapped > 400px tall.
        expect(
          titleSize.height,
          lessThan(150),
          reason:
              'Title wrapped excessively vertically (${titleSize.height}px) on ${config.size} @ ${config.scale}x',
        );
        expect(titleSize.width, greaterThan(100));

        expect(find.text('Override Badge'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
