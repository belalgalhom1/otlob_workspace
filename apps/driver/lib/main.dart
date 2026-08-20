import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await dotenv.load(fileName: ".env");
  // await Firebase.initializeApp();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'packages/core/assets/translations',
        fallbackLocale: const Locale('en'),
        useOnlyLangCode: true,
        child: const App(),
      ),
    ),
  );
}
