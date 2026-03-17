// ABOUTME: Thin wrapper around file_picker for testability.
// ABOUTME: Allows provider override in widget tests.

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return FilePickerService();
});

class FilePickerService {
  /// Picks a .cardstash file and returns its path, or null if cancelled.
  Future<String?> pickCardstashFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['cardstash'],
    );
    return result?.files.single.path;
  }
}
