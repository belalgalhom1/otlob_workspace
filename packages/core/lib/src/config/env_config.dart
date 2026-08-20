import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  /// Ensures dotenv is loaded and all critical variables are present.
  /// Throws an exception if something is missing, crashing the app early
  /// rather than failing silently later.
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');

    final requiredKeys = ['API_URL', 'WS_URL'];
    for (final key in requiredKeys) {
      if (!dotenv.env.containsKey(key) || dotenv.env[key]!.isEmpty) {
        throw Exception('CRITICAL ERROR: Missing $key in .env file');
      }
    }
    debugPrint('✅ EnvConfig initialized successfully.');
  }

  static String get apiUrl => dotenv.env['API_URL']!;
  static String get wsUrl => dotenv.env['WS_URL']!;
}
