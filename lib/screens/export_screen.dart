// ABOUTME: Export screen for passphrase entry and share sheet trigger.
// ABOUTME: Encrypts all cards with user passphrase for device migration.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/export_service.dart';
import '../widgets/passphrase_field.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String _passphrase = '';
  String _confirmation = '';
  bool _isExporting = false;

  static const _minPassphraseLength = 8;

  bool get _passphrasesMatch =>
      _passphrase.isNotEmpty &&
      _confirmation.isNotEmpty &&
      _passphrase == _confirmation;

  bool get _passphraseLongEnough => _passphrase.length >= _minPassphraseLength;

  bool get _canExport =>
      _passphrasesMatch && _passphraseLongEnough && !_isExporting;

  String? get _mismatchError {
    if (_confirmation.isEmpty) return null;
    if (_passphrase == _confirmation) return null;
    return 'Passphrases do not match';
  }

  String? get _lengthError {
    if (_passphrase.isEmpty) return null;
    if (_passphrase.length >= _minPassphraseLength) return null;
    return 'Must be at least 8 characters';
  }

  Future<void> _export() async {
    if (!_canExport) return;
    setState(() => _isExporting = true);

    try {
      final service = ref.read(exportServiceProvider);
      final file = await service.buildExportFile(_passphrase);
      await service.shareExportFile(file);
      await service.cleanupExportFile(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cards exported.'),
            backgroundColor: Color(0xFF34D399),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Export cards',
          style: TextStyle(color: Color(0xFFF8FAFC)),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Color(0xFFF8FAFC)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning card.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: Color(0xFFF59E0B), width: 4),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You'll need this passphrase to restore your cards. "
                      "There's no way to recover it if you forget it.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFF8FAFC),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // AirDrop tip on iOS.
            if (Platform.isIOS) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF312E81).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF312E81), width: 4),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      color: Color(0xFF312E81),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Use AirDrop to send the file directly to your new iPhone.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFF8FAFC),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            PassphraseField(
              labelText: 'Enter passphrase',
              onChanged: (value) => setState(() => _passphrase = value),
              errorText: _lengthError,
            ),
            const SizedBox(height: 20),
            PassphraseField(
              labelText: 'Confirm passphrase',
              onChanged: (value) => setState(() => _confirmation = value),
              errorText: _mismatchError,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canExport ? _export : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF0F172A),
                  disabledBackgroundColor: const Color(
                    0xFF94A3B8,
                  ).withValues(alpha: 0.2),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isExporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0F172A),
                        ),
                      )
                    : const Text('Export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
