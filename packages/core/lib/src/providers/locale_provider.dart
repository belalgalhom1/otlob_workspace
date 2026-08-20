import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core_providers.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  static const _localeKey = 'app_locale';
  FlutterSecureStorage get _secureStorage => ref.read(secureStorageProvider);

  @override
  Locale build() {
    _loadLocale();
    return const Locale('ar'); // Default to 'ar' like admin did
  }

  Future<void> _loadLocale() async {
    final languageCode = await _secureStorage.read(key: _localeKey);
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    await _secureStorage.write(key: _localeKey, value: locale.languageCode);
    state = locale;
  }

  Future<void> toggleLanguage() async {
    final newLocale = state.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(newLocale);
  }

  Future<void> setLanguage(String languageCode) async {
    await setLocale(Locale(languageCode));
  }
}
