import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_preferences_provider.g.dart';

class AppPreferencesState {
  final ThemeMode themeMode;
  final Locale locale;

  AppPreferencesState({
    required this.themeMode,
    required this.locale,
  });

  AppPreferencesState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return AppPreferencesState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

@Riverpod(keepAlive: true)
class AppPreferences extends _$AppPreferences {
  static const _themeKey = 'app_theme_mode';
  static const _localeKey = 'app_locale';

  @override
  AppPreferencesState build() {
    _loadPreferences();
    return AppPreferencesState(
      themeMode: ThemeMode.dark, // Default to dark mode for Driver
      locale: const Locale('ar'), // Default to ar
    );
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme
    final themeString = prefs.getString(_themeKey);
    ThemeMode mode = ThemeMode.dark;
    if (themeString != null) {
      if (themeString == 'light') mode = ThemeMode.light;
      if (themeString == 'system') mode = ThemeMode.system;
    }
    
    // Locale
    final localeString = prefs.getString(_localeKey);
    Locale locale = const Locale('ar');
    if (localeString != null) {
      locale = Locale(localeString);
    }
    
    state = state.copyWith(themeMode: mode, locale: locale);
  }

  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = state.copyWith(themeMode: newMode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, newMode.name);
  }

  Future<void> setLocale(String languageCode) async {
    final newLocale = Locale(languageCode);
    state = state.copyWith(locale: newLocale);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }
}
