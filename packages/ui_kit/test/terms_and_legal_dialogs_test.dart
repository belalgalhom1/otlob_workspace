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

ThemeData _mockCustomerTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
    dividerColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEEEEEE),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
    ),
    extensions: [
      AppDialogTheme(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEEEEEE),
        subtleSurfaceColor:
            isDark ? const Color(0xFF141416) : const Color(0xFFF8F9FA),
        sectionCardColor:
            isDark ? const Color(0xFF242426) : const Color(0xFFF8F9FA),
        accentColor: AppColors.primary,
        onAccentColor: Colors.black,
        badgeBackgroundColor: AppColors.primary.withValues(alpha: 0.14),
        badgeForegroundColor: isDark
            ? AppColors.primary
            : const Color(0xFFB45309),
        dialogRadius: 22,
        cardRadius: 16,
        buttonRadius: 16,
        buttonMinHeight: 50,
        showHeaderDivider: false,
      ),
    ],
  );
}

Widget _wrapWithMedia({
  required Widget child,
  required ThemeData theme,
  Locale locale = const Locale('en'),
  Size size = const Size(360, 640),
  EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  TextScaler textScaler = const TextScaler.linear(1.0),
}) {
  return MaterialApp(
    theme: theme,
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: const [
      _ArMaterialLocalizationsDelegate(),
      _ArCupertinoLocalizationsDelegate(),
      _ArWidgetsLocalizationsDelegate(),
    ],
    builder: (context, appChild) => MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: padding,
        textScaler: textScaler,
      ),
      child: Directionality(
        textDirection:
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: appChild ?? const SizedBox.shrink(),
      ),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  const sampleMarkdownEn = '''
# Terms of Service Agreement
### 1. Eligibility & Conduct
Please review our **key service terms** before continuing to use the platform.
> Important notice for all users across Egypt.
- Must be 18+ years old.
1. Maintain accurate account details.
2. Follow safety guidelines.
''';

  const sampleMarkdownAr = '''
# اتفاقية شروط الاستخدام
### ١. الأهلية والاستخدام
يرجى مراجعة **الشروط الأساسية للخدمة** بعناية قبل المتابعة.
> تنبيه هام لجميع المستخدمين.
- يجب أن يكون العمر ١٨ عاماً فأكثر.
1. الحفاظ على صحة بيانات الحساب.
2. الالتزام بإرشادات السلامة.
''';

  group('TermsAcceptanceDialog per-app design & responsiveness', () {
    for (final variant in const [
      TermsDialogVariant.customer,
      TermsDialogVariant.driver,
      TermsDialogVariant.vendor,
    ]) {
      for (final brightness in Brightness.values) {
        for (final locale in const [Locale('en'), Locale('ar')]) {
          for (final config in const [
            (size: Size(320, 568), scale: 0.85, pad: EdgeInsets.only(top: 59, bottom: 34)),
            (size: Size(360, 640), scale: 1.3, pad: EdgeInsets.only(top: 47, bottom: 34)),
            (size: Size(320, 568), scale: 1.6, pad: EdgeInsets.only(top: 47, bottom: 34)),
            (size: Size(800, 900), scale: 1.3, pad: EdgeInsets.zero),
          ]) {
            testWidgets(
              '${variant.name} renders without overflow & respects SafeArea at ${config.size.width.toInt()}x${config.size.height.toInt()} ${config.scale}x (${brightness.name}/${locale.languageCode})',
              (tester) async {
                tester.view.physicalSize = config.size;
                tester.view.devicePixelRatio = 1.0;
                addTearDown(() {
                  tester.view.resetPhysicalSize();
                  tester.view.resetDevicePixelRatio();
                });

                var acceptCount = 0;
                var declineCount = 0;
                var langCount = 0;
                var privacyCount = 0;
                final isAr = locale.languageCode == 'ar';
                final theme = variant == TermsDialogVariant.customer
                    ? _mockCustomerTheme(brightness)
                    : (brightness == Brightness.dark
                        ? AppTheme.darkTheme
                        : AppTheme.lightTheme);

                await tester.pumpWidget(
                  _wrapWithMedia(
                    theme: theme,
                    locale: locale,
                    size: config.size,
                    padding: config.pad,
                    textScaler: TextScaler.linear(config.scale),
                    child: Center(
                      child: TermsAcceptanceDialog(
                        variant: variant,
                        title: isAr
                            ? 'الشروط والأحكام للتطبيق'
                            : 'Platform Terms of Use',
                        subtitle: isAr
                            ? 'يرجى قراءة الشروط والموافقة للمتابعة.'
                            : 'Please review and accept to continue.',
                        version: '2.4',
                        content: isAr ? sampleMarkdownAr : sampleMarkdownEn,
                        isArabic: isAr,
                        onLanguageToggle: () => langCount++,
                        acceptCheckboxLabel: isAr
                            ? 'لقد قرأت وأوافق على جميع الشروط والأحكام المذكورة أعلاه'
                            : 'I have read and agree to the Terms & Conditions above',
                        acceptButtonLabel:
                            isAr ? 'موافقة ومتابعة' : 'Accept & Continue',
                        declineButtonLabel:
                            isAr ? 'رفض وتسجيل الخروج' : 'Decline',
                        onAccept: () => acceptCount++,
                        onDecline: () => declineCount++,
                        onViewPrivacyPolicy: () => privacyCount++,
                        privacyPolicyLabel: isAr
                            ? 'عرض سياسة الخصوصية وحماية البيانات'
                            : 'View Privacy Policy & Data Protection',
                      ),
                    ),
                  ),
                );
                await tester.pumpAndSettle();

                expect(tester.takeException(), isNull);

                // Dialog card surface must strictly stay inside SafeArea insets.
                final cardFinder = find
                    .descendant(
                      of: find.byType(Dialog),
                      matching: find.byType(Material),
                    )
                    .first;
                final dialogRect = tester.getRect(cardFinder);
                expect(dialogRect.top, greaterThanOrEqualTo(config.pad.top));
                expect(
                  dialogRect.bottom,
                  lessThanOrEqualTo(config.size.height - config.pad.bottom),
                );
                expect(dialogRect.left, greaterThanOrEqualTo(config.pad.left));
                expect(
                  dialogRect.right,
                  lessThanOrEqualTo(config.size.width - config.pad.right),
                );

                // Action buttons must NOT squeeze text with FittedBox.
                expect(
                  find.descendant(
                    of: find.byType(TermsAcceptanceDialog),
                    matching: find.byType(FittedBox),
                  ),
                  findsNothing,
                );

                // Language & Privacy callbacks fire cleanly.
                await tester.tap(find.text(isAr ? 'EN' : 'عربي'));
                await tester.pump();
                expect(langCount, 1);

                final privacyFinder = find.text(
                  isAr
                      ? 'عرض سياسة الخصوصية وحماية البيانات'
                      : 'View Privacy Policy & Data Protection',
                );
                await tester.ensureVisible(privacyFinder);
                await tester.tap(privacyFinder);
                await tester.pump();
                expect(privacyCount, 1);

                // Accept disabled before checkbox tap.
                final acceptText = isAr ? 'موافقة ومتابعة' : 'Accept & Continue';
                await tester.ensureVisible(find.text(acceptText));
                await tester.tap(find.text(acceptText));
                await tester.pump();
                expect(acceptCount, 0);

                // Toggle consent checkbox then accept.
                final checkboxLabel = isAr
                    ? 'لقد قرأت وأوافق على جميع الشروط والأحكام المذكورة أعلاه'
                    : 'I have read and agree to the Terms & Conditions above';
                await tester.ensureVisible(find.text(checkboxLabel));
                await tester.tap(find.text(checkboxLabel));
                await tester.pumpAndSettle();
                await tester.ensureVisible(find.text(acceptText));
                await tester.tap(find.text(acceptText));
                await tester.pump();
                expect(acceptCount, 1);

                // Decline callback fires.
                final declineText = isAr ? 'رفض وتسجيل الخروج' : 'Decline';
                await tester.ensureVisible(find.text(declineText));
                await tester.tap(find.text(declineText));
                await tester.pump();
                expect(declineCount, 1);
              },
            );
          }
        }
      }
    }

    testWidgets(
      'distinct variants preserve per-app shape and color identity (Customer neutral vs Driver/Vendor Slate)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        Future<Dialog> pumpVariant(
          TermsDialogVariant variant,
          ThemeData theme,
        ) async {
          await tester.pumpWidget(
            KeyedSubtree(
              key: ValueKey(variant),
              child: _wrapWithMedia(
                theme: theme,
                size: const Size(800, 900),
                padding: EdgeInsets.zero,
                child: TermsAcceptanceDialog(
                  variant: variant,
                  title: 'Terms',
                  subtitle: 'Subtitle',
                  version: '1.0',
                  content: sampleMarkdownEn,
                  acceptCheckboxLabel: 'I agree',
                  acceptButtonLabel: 'Accept',
                  declineButtonLabel: 'Decline',
                  onAccept: () {},
                  onDecline: () {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          return tester.widget<Dialog>(find.byType(Dialog));
        }

        final customerDialog = await pumpVariant(
          TermsDialogVariant.customer,
          _mockCustomerTheme(Brightness.dark),
        );
        expect(customerDialog.backgroundColor, const Color(0xFF1C1C1E));
        final customerShape = customerDialog.shape as RoundedRectangleBorder;
        expect(
          customerShape.borderRadius,
          BorderRadius.circular(22),
        );
        expect(customerShape.side.color, const Color(0xFF2E2E2E));

        final driverDialog = await pumpVariant(
          TermsDialogVariant.driver,
          AppTheme.darkTheme,
        );
        expect(driverDialog.backgroundColor, AppColors.surfaceDark);
        final driverShape = driverDialog.shape as RoundedRectangleBorder;
        expect(driverShape.borderRadius, BorderRadius.circular(16));
        expect(driverShape.side.color, AppColors.borderDark);

        final vendorDialog = await pumpVariant(
          TermsDialogVariant.vendor,
          AppTheme.darkTheme,
        );
        expect(vendorDialog.backgroundColor, AppColors.surfaceDark);
        final vendorShape = vendorDialog.shape as RoundedRectangleBorder;
        expect(vendorShape.borderRadius, BorderRadius.circular(18));
        expect(vendorShape.side.color, AppColors.borderDark);
      },
    );

    testWidgets(
      'AppDialogStyles and AppConfirmDialog honor AppDialogTheme in Customer vs Slate in ui_kit',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithMedia(
            theme: _mockCustomerTheme(Brightness.light),
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppConfirmDialog.show(
                    context,
                    title: 'Confirm',
                    message: 'Are you sure?',
                    confirmLabel: 'Confirm',
                    cancelLabel: 'Cancel',
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('OPEN'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        expect(dialog.backgroundColor, Colors.white);
        final shape = dialog.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(22));
        expect(shape.side.color, const Color(0xFFEEEEEE));
      },
    );

    testWidgets(
      'LegalDocumentView renders readable accent colors in Light mode without overflow at 1.3x scale',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithMedia(
            theme: _mockCustomerTheme(Brightness.light),
            textScaler: const TextScaler.linear(1.3),
            size: const Size(320, 568),
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            child: SafeArea(
              child: LegalDocumentView(
                title: 'Customer Terms & Conditions of Service',
                version: '3.0',
                lastUpdated: 'Last updated: 2026-11-15',
                content: sampleMarkdownEn,
                onLanguageToggle: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final versionText = tester.widget<Text>(find.text('v3.0'));
        expect(versionText.style?.color, const Color(0xFFB45309));
      },
    );
  });
}
