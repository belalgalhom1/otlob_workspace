import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/app_settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  // await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'packages/core/assets/translations',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        useOnlyLangCode: true,
        child: const App(),
      ),
    ),
  );
}
