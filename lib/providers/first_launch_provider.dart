// ABOUTME: Providers for app preferences stored in SharedPreferences.
// ABOUTME: First-launch flag and theme mode preference.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _firstLaunchKey = 'first_launch_completed';
const _themeModeKey = 'theme_mode';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be initialised before use. '
    'Override this provider with the initialised instance.',
  );
});

final isFirstLaunchProvider = Provider<bool>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return !(prefs.getBool(_firstLaunchKey) ?? false);
});

final completeFirstLaunchProvider = Provider<Future<void> Function()>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return () => prefs.setBool(_firstLaunchKey, true);
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_themeModeKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, value);
    state = mode;
  }
}
