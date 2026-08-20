import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final storage = ref.read(secureStorageProvider);
    final themeName = await storage.read(key: 'theme_mode');
    if (themeName != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> toggleTheme() async {
    final storage = ref.read(secureStorageProvider);
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await storage.write(key: 'theme_mode', value: newMode.name);
    state = newMode;
  }

  Future<void> setTheme(ThemeMode mode) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: 'theme_mode', value: mode.name);
    state = mode;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
