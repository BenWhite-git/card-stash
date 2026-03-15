// ABOUTME: Provider for first-launch flag stored in SharedPreferences.
// ABOUTME: Used to show onboarding screen exactly once on first app launch.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _firstLaunchKey = 'first_launch_completed';

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
