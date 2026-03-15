// ABOUTME: Screen brightness control for card display.
// ABOUTME: Saves current brightness, forces max, and restores on dismiss.

import 'package:screen_brightness/screen_brightness.dart';

/// Abstraction over screen brightness for testability.
abstract class ScreenBrightnessControl {
  Future<double> get systemBrightness;
  Future<double> get applicationBrightness;
  Future<void> setApplicationScreenBrightness(double brightness);
  Future<void> resetApplicationScreenBrightness();
}

/// Production implementation wrapping the screen_brightness package.
class ScreenBrightnessControlImpl implements ScreenBrightnessControl {
  final ScreenBrightness _screenBrightness = ScreenBrightness();

  @override
  Future<double> get systemBrightness => _screenBrightness.system;

  @override
  Future<double> get applicationBrightness => _screenBrightness.application;

  @override
  Future<void> setApplicationScreenBrightness(double brightness) =>
      _screenBrightness.setApplicationScreenBrightness(brightness);

  @override
  Future<void> resetApplicationScreenBrightness() =>
      _screenBrightness.resetApplicationScreenBrightness();
}

class BrightnessService {
  final ScreenBrightnessControl _control;

  BrightnessService({ScreenBrightnessControl? brightnessControl})
    : _control = brightnessControl ?? ScreenBrightnessControlImpl();

  /// Forces screen brightness to maximum (1.0).
  Future<void> setMaxBrightness() async {
    try {
      await _control.setApplicationScreenBrightness(1.0);
    } catch (_) {
      // Platform call can fail on unsupported devices. Degrade gracefully.
    }
  }

  /// Resets application brightness override, returning to system default.
  Future<void> restoreBrightness() async {
    try {
      await _control.resetApplicationScreenBrightness();
    } catch (_) {
      // Platform call can fail. Degrade gracefully.
    }
  }
}
