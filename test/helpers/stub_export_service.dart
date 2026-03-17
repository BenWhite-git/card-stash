// ABOUTME: Stub ExportService for widget tests.
// ABOUTME: Records calls without real crypto or file I/O.

import 'dart:io';

import 'package:card_stash/services/export_service.dart';

/// Standalone stub that doesn't need a real Hive box.
/// Override [exportServiceProvider] with this in widget tests.
class StubExportService implements ExportService {
  final List<String> calls = [];
  bool shouldFail = false;
  String? failMessage;

  @override
  List<Map<String, dynamic>> serialiseCards() => [];

  @override
  Future<File> buildExportFile(String passphrase) async {
    calls.add('buildExportFile:$passphrase');
    if (shouldFail) {
      throw Exception(failMessage ?? 'Export failed');
    }
    final tempDir = await Directory.systemTemp.createTemp('stub_export_');
    final file = File('${tempDir.path}/stub.cardstash');
    await file.writeAsString('{"stub": true}');
    return file;
  }

  @override
  Future<void> shareExportFile(File file) async {
    calls.add('shareExportFile:${file.path}');
  }

  @override
  Future<void> cleanupExportFile(File file) async {
    calls.add('cleanupExportFile:${file.path}');
  }
}
