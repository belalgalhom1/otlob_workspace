import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  Widget wrapSheet({
    required Locale locale,
    required Brightness brightness,
    required ValueChanged<ChatMediaPickerOption> onSelected,
    bool allowVideo = true,
    bool allowLocation = true,
  }) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Builder(
        builder: (context) => Localizations.override(
          context: context,
          locale: locale,
          child: Directionality(
            textDirection: locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 320,
                  child: ChatMediaPickerSheet(
                    allowVideo: allowVideo,
                    allowLocation: allowLocation,
                    onOptionSelected: onSelected,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ChatMediaPickerSheet displays Camera and Location options in English LTR and selects location', (
    tester,
  ) async {
    ChatMediaPickerOption? picked;

    await tester.pumpWidget(
      wrapSheet(
        locale: const Locale('en'),
        brightness: Brightness.light,
        allowVideo: true,
        allowLocation: true,
        onSelected: (option) => picked = option,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Share Media'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Record Video'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Share Location'), findsOneWidget);
    expect(find.byIcon(LucideIcons.camera), findsOneWidget);
    expect(find.byIcon(LucideIcons.mapPin), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Share Location'));
    await tester.pump();

    expect(picked, ChatMediaPickerOption.location);
  });

  testWidgets('ChatMediaPickerSheet displays localized Arabic RTL options cleanly without overflow', (
    tester,
  ) async {
    ChatMediaPickerOption? picked;

    await tester.pumpWidget(
      wrapSheet(
        locale: const Locale('ar'),
        brightness: Brightness.dark,
        allowVideo: true,
        allowLocation: true,
        onSelected: (option) => picked = option,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مشاركة وسائط'), findsOneWidget);
    expect(find.text('التقاط صورة'), findsOneWidget);
    expect(find.text('مشاركة الموقع'), findsOneWidget);
    expect(find.text('الموقع الحالي'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('التقاط صورة'));
    await tester.pump();

    expect(picked, ChatMediaPickerOption.cameraPhoto);
  });

  testWidgets('ChatMediaPickerSheet omits Location tile when allowLocation is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapSheet(
        locale: const Locale('en'),
        brightness: Brightness.light,
        allowVideo: false,
        allowLocation: false,
        onSelected: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Record Video'), findsNothing);
    expect(find.text('Share Location'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
