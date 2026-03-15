// ABOUTME: Tests for BrightnessService screen brightness control.
// ABOUTME: Verifies save/restore brightness lifecycle and error handling.

import 'package:flutter_test/flutter_test.dart';

import 'package:card_stash/services/brightness_service.dart';

/// Fake implementation of ScreenBrightnessControl for testing.
class FakeBrightnessControl implements ScreenBrightnessControl {
  double _systemBrightness = 0.5;
  double? _applicationBrightness;
  bool throwOnGet = false;
  bool throwOnSet = false;
  bool throwOnReset = false;

  void setSystemBrightness(double value) {
    _systemBrightness = value;
  }

  @override
  Future<double> get systemBrightness async {
    if (throwOnGet) throw Exception('Failed to get brightness');
    return _systemBrightness;
  }

  @override
  Future<double> get applicationBrightness async {
    if (throwOnGet) throw Exception('Failed to get brightness');
    if (_applicationBrightness == null) {
      throw Exception('No application brightness set');
    }
    return _applicationBrightness!;
  }

  @override
  Future<void> setApplicationScreenBrightness(double brightness) async {
    if (throwOnSet) throw Exception('Failed to set brightness');
    _applicationBrightness = brightness;
  }

  @override
  Future<void> resetApplicationScreenBrightness() async {
    if (throwOnReset) throw Exception('Failed to reset brightness');
    _applicationBrightness = null;
  }
}

void main() {
  late BrightnessService service;
  late FakeBrightnessControl fakeBrightness;

  setUp(() {
    fakeBrightness = FakeBrightnessControl();
    service = BrightnessService(brightnessControl: fakeBrightness);
  });

  group('setMaxBrightness', () {
    test('sets brightness to 1.0', () async {
      await service.setMaxBrightness();

      expect(await fakeBrightness.applicationBrightness, 1.0);
    });

    test('calling multiple times does not throw', () async {
      await service.setMaxBrightness();
      await service.setMaxBrightness();

      expect(await fakeBrightness.applicationBrightness, 1.0);
    });

    test('does not throw when platform call fails', () async {
      fakeBrightness.throwOnSet = true;

      // Should not throw - errors are handled gracefully.
      await service.setMaxBrightness();
    });
  });

  group('restoreBrightness', () {
    test('resets application brightness after setMaxBrightness', () async {
      await service.setMaxBrightness();
      await service.restoreBrightness();

      // After reset, application brightness should throw (no override set).
      expect(
        () async => await fakeBrightness.applicationBrightness,
        throwsException,
      );
    });

    test('does not throw when called without prior set', () async {
      // Should not throw even if setMaxBrightness was never called.
      await service.restoreBrightness();
    });

    test('does not throw when platform call fails', () async {
      await service.setMaxBrightness();
      fakeBrightness.throwOnReset = true;

      // Should not throw - errors are handled gracefully.
      await service.restoreBrightness();
    });
  });

  group('lifecycle', () {
    test('set then restore is a clean round trip', () async {
      fakeBrightness.setSystemBrightness(0.3);

      await service.setMaxBrightness();
      expect(await fakeBrightness.applicationBrightness, 1.0);

      await service.restoreBrightness();
      // Application brightness override is cleared.
      expect(
        () async => await fakeBrightness.applicationBrightness,
        throwsException,
      );
    });
  });
}
