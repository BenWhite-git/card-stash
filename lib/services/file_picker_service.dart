// ABOUTME: Thin wrapper around file_picker for testability.
// ABOUTME: Allows provider override in widget tests.

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return FilePickerService();
});

class FilePickerService {
  /// Picks a .cardstash file and returns its local path, or null if cancelled.
  ///
  /// Android and iOS copy the picked file into the app cache, so the path
  /// is always a readable local file.
  Future<String?> pickCardstashFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['cardstash'],
    );
    return file?.path;
  }
}
