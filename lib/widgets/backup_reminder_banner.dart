// ABOUTME: Home screen banner nudging the user to export an encrypted backup.
// ABOUTME: Offers Back up (opens export) and Later (snoozes the reminder).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/backup_reminder_provider.dart';
import '../theme.dart';

class BackupReminderBanner extends ConsumerWidget {
  const BackupReminderBanner({super.key});

  String _message(DateTime? lastExportAt, DateTime now) {
    if (lastExportAt == null) {
      return 'If this phone is lost, your cards go with it. Export an '
          'encrypted backup and keep it somewhere safe.';
    }
    final days = now.difference(lastExportAt).inDays;
    return 'Your last backup was $days days ago and you have added cards '
        'since.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final reminder = ref.watch(backupReminderProvider);
    final now = ref.read(clockProvider)();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: colors.accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.backup_outlined, color: colors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Back up your cards',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              _message(reminder.lastExportAt, now),
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () =>
                    ref.read(backupReminderProvider.notifier).snooze(),
                child: Text('Later', style: TextStyle(color: colors.textMuted)),
              ),
              TextButton(
                onPressed: () => context.push('/settings/export'),
                child: Text(
                  'Back up',
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
