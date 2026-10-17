// ABOUTME: Decides when to nudge the user to export an encrypted backup.
// ABOUTME: Tracks last export time and snooze state in SharedPreferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card_provider.dart';
import 'first_launch_provider.dart';

/// SharedPreferences key holding the ISO-8601 time of the last export.
const lastExportKey = 'last_export_at';
const _snoozedUntilKey = 'backup_reminder_snoozed_until';

/// A wallet this small is not worth nagging about yet.
const minCardsBeforeFirstReminder = 3;

/// A backup older than this with new cards since counts as stale.
const staleBackupAge = Duration(days: 30);

/// How long "Later" hides the reminder for.
const snoozeDuration = Duration(days: 7);

/// Source of the current time, overridable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class BackupReminderState {
  final DateTime? lastExportAt;
  final DateTime? snoozedUntil;

  const BackupReminderState({this.lastExportAt, this.snoozedUntil});
}

final backupReminderProvider =
    NotifierProvider<BackupReminderNotifier, BackupReminderState>(
      BackupReminderNotifier.new,
    );

class BackupReminderNotifier extends Notifier<BackupReminderState> {
  @override
  BackupReminderState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return BackupReminderState(
      lastExportAt: _readDate(prefs.getString(lastExportKey)),
      snoozedUntil: _readDate(prefs.getString(_snoozedUntilKey)),
    );
  }

  static DateTime? _readDate(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso);

  /// Marks now as the last successful export and clears any snooze.
  Future<void> recordExport() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final now = ref.read(clockProvider)();
    await prefs.setString(lastExportKey, now.toIso8601String());
    await prefs.remove(_snoozedUntilKey);
    state = BackupReminderState(lastExportAt: now);
  }

  /// Hides the reminder for [snoozeDuration].
  Future<void> snooze() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final until = ref.read(clockProvider)().add(snoozeDuration);
    await prefs.setString(_snoozedUntilKey, until.toIso8601String());
    state = BackupReminderState(
      lastExportAt: state.lastExportAt,
      snoozedUntil: until,
    );
  }
}

/// True when the home screen should show the backup reminder banner.
final backupReminderDueProvider = Provider<bool>((ref) {
  final cards = ref.watch(cardListProvider);
  final reminder = ref.watch(backupReminderProvider);
  final now = ref.read(clockProvider)();

  if (cards.isEmpty) return false;
  final snoozedUntil = reminder.snoozedUntil;
  if (snoozedUntil != null && now.isBefore(snoozedUntil)) return false;

  final lastExport = reminder.lastExportAt;
  if (lastExport == null) return cards.length >= minCardsBeforeFirstReminder;
  if (now.difference(lastExport) < staleBackupAge) return false;
  return cards.any((card) => card.createdAt.isAfter(lastExport));
});
