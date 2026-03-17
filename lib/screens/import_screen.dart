// ABOUTME: Import screen for restoring cards from a .cardstash file.
// ABOUTME: Supports merge and replace-all modes with passphrase verification.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/file_picker_service.dart';
import '../services/import_service.dart';
import '../widgets/passphrase_field.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  String? _filePath;
  String _passphrase = '';
  ImportMode _mode = ImportMode.replaceAll;
  bool _isImporting = false;
  ImportResult? _result;
  String? _error;

  bool get _canImport =>
      _filePath != null && _passphrase.isNotEmpty && !_isImporting;

  Future<void> _pickFile() async {
    final picker = ref.read(filePickerServiceProvider);
    final path = await picker.pickCardstashFile();
    if (path != null) {
      setState(() {
        _filePath = path;
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _import() async {
    if (!_canImport) return;
    setState(() {
      _isImporting = true;
      _error = null;
      _result = null;
    });

    try {
      final service = ref.read(importServiceProvider);
      final result = await service.importCards(_filePath!, _passphrase, _mode);
      if (mounted) {
        setState(() => _result = result);
      }
    } on ImportSignatureException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } on ImportFormatException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Import failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Import cards',
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
            // File picker.
            if (_filePath == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Select file'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else ...[
              // Selected file indicator.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _filePath!.split('/').last,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFF8FAFC),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                      tooltip: 'Remove file',
                      onPressed: () => setState(() {
                        _filePath = null;
                        _result = null;
                        _error = null;
                      }),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Passphrase field.
              PassphraseField(
                labelText: 'Enter passphrase',
                onChanged: (value) => setState(() => _passphrase = value),
              ),
              const SizedBox(height: 24),
              // Import mode.
              const Text(
                'IMPORT MODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              _ModeOption(
                label: 'Replace all',
                description:
                    'Removes your existing cards and imports everything from the file.',
                selected: _mode == ImportMode.replaceAll,
                onTap: () => setState(() => _mode = ImportMode.replaceAll),
              ),
              const SizedBox(height: 8),
              _ModeOption(
                label: 'Merge',
                description:
                    'Adds cards from the file, skipping any that already exist.',
                selected: _mode == ImportMode.merge,
                onTap: () => setState(() => _mode = ImportMode.merge),
              ),
              const SizedBox(height: 32),
              // Import button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canImport ? _import : null,
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
                  child: _isImporting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0F172A),
                          ),
                        )
                      : const Text('Import'),
                ),
              ),
            ],
            // Result display.
            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF34D399), width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_result!.importedCards} cards imported',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF34D399),
                      ),
                    ),
                    if (_result!.skippedDuplicates > 0)
                      Text(
                        '${_result!.skippedDuplicates} duplicates skipped',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            // Error display.
            if (_error != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFEF4444), width: 4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFF59E0B) : const Color(0xFF334155),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
