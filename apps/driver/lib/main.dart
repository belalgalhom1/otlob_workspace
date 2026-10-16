import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:core/core.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp();
    registerPushNotificationBackgroundHandler();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // Default language is Arabic. `app_locale` is only written when the user
  // explicitly picks a language (see AppPreferences.setLocale), so its
  // absence means "never chose" -> drop any stale saved locale so
  // guest/first-run always starts in Arabic. Explicit choices are respected.
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('app_locale');
  if (savedLang == null) {
    await prefs.remove('locale');
  }

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'packages/core/assets/translations',
        fallbackLocale: const Locale('ar'),
        startLocale: Locale(savedLang ?? 'ar'),
        useOnlyLangCode: true,
        child: const App(),
      ),
    ),
  );
}
