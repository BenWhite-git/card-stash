// ABOUTME: Stub ImportService for widget tests.
// ABOUTME: Records calls and returns predefined results without real crypto.

import 'package:card_stash/services/import_service.dart';

class StubImportService implements ImportService {
  final List<String> calls = [];
  ImportResult resultToReturn;
  Exception? exceptionToThrow;

  /// Runs before the result is returned, so a test can mimic the side effects
  /// of a real import such as writing cards into the box.
  Future<void> Function()? onImport;

  StubImportService({
    this.resultToReturn = const ImportResult(
      totalCards: 3,
      importedCards: 3,
      skippedDuplicates: 0,
      skippedPaymentCards: 0,
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
    await onImport?.call();
    return resultToReturn;
  }
}
