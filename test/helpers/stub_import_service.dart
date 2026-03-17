// ABOUTME: Stub ImportService for widget tests.
// ABOUTME: Records calls and returns predefined results without real crypto.

import 'package:card_stash/services/import_service.dart';

class StubImportService implements ImportService {
  final List<String> calls = [];
  ImportResult resultToReturn;
  Exception? exceptionToThrow;

  StubImportService({
    this.resultToReturn = const ImportResult(
      totalCards: 3,
      importedCards: 3,
      skippedDuplicates: 0,
    ),
  });

  @override
  Future<ImportResult> importCards(
    String filePath,
    String passphrase,
    ImportMode mode,
  ) async {
    calls.add('importCards:$filePath:$mode');
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return resultToReturn;
  }
}
