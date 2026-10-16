import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/core.dart';

import 'app.dart';
import 'core/providers/app_settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await EasyLocalization.ensureInitialized();

  try {
    await Firebase.initializeApp();
    registerPushNotificationBackgroundHandler();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  // Default language is Arabic. Our own `language_code` key is only written
  // when the user explicitly picks a language, so its absence means "never
  // chose" -> drop any stale EasyLocalization-saved locale (e.g. `en`
  // resolved from the device on an old build) so guest/first-run always
  // starts in Arabic. An explicit user choice is always respected.
  const langKey = 'language_code';
  final savedLang = prefs.getString(langKey);
  if (savedLang == null) {
    await prefs.remove('locale');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
