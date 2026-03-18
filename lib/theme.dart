// ABOUTME: App theme definitions with light and dark palettes.
// ABOUTME: Provides CardStashColors extension for consistent theming.

import 'package:flutter/material.dart';

/// Custom color palette accessible via `context.colors`.
@immutable
class CardStashColors extends ThemeExtension<CardStashColors> {
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color error;

  const CardStashColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.error,
  });

  static const dark = CardStashColors(
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    border: Color(0xFF334155),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    accent: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
  );

  static const light = CardStashColors(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    accent: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
  );

  @override
  CardStashColors copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? error,
  }) {
    return CardStashColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      error: error ?? this.error,
    );
  }

  @override
  CardStashColors lerp(CardStashColors? other, double t) {
    if (other == null) return this;
    return CardStashColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

/// Convenience extension to access CardStashColors from BuildContext.
extension CardStashTheme on BuildContext {
  CardStashColors get colors =>
      Theme.of(this).extension<CardStashColors>() ?? CardStashColors.dark;
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: CardStashColors.dark.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CardStashColors.dark.accent,
      brightness: Brightness.dark,
      surface: CardStashColors.dark.background,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CardStashColors.dark.surface,
      indicatorColor: CardStashColors.dark.accent.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CardStashColors.dark.accent,
          );
        }
        return TextStyle(fontSize: 12, color: CardStashColors.dark.textMuted);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: CardStashColors.dark.accent);
        }
        return IconThemeData(color: CardStashColors.dark.textMuted);
      }),
    ),
    useMaterial3: true,
    extensions: const [CardStashColors.dark],
  );
}

ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: CardStashColors.light.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CardStashColors.light.accent,
      brightness: Brightness.light,
      surface: CardStashColors.light.background,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CardStashColors.light.surface,
      indicatorColor: CardStashColors.light.accent.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CardStashColors.light.accent,
          );
        }
        return TextStyle(fontSize: 12, color: CardStashColors.light.textMuted);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: CardStashColors.light.accent);
        }
        return IconThemeData(color: CardStashColors.light.textMuted);
      }),
    ),
    useMaterial3: true,
    extensions: const [CardStashColors.light],
  );
}
