// ABOUTME: Secure text input widget for export/import passphrase entry.
// ABOUTME: Includes show/hide toggle for passphrase visibility.

import 'package:flutter/material.dart';

import '../theme.dart';

class PassphraseField extends StatefulWidget {
  final String labelText;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const PassphraseField({
    super.key,
    required this.labelText,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<PassphraseField> createState() => _PassphraseFieldState();
}

class _PassphraseFieldState extends State<PassphraseField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      onChanged: widget.onChanged,
      obscureText: _obscured,
      style: TextStyle(fontSize: 16, color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
        errorText: widget.errorText,
        errorStyle: TextStyle(fontSize: 12, color: colors.error),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: colors.textMuted,
          ),
          tooltip: _obscured ? 'Show passphrase' : 'Hide passphrase',
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}
