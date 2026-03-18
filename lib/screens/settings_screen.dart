// ABOUTME: Settings screen with export, import, and about navigation.
// ABOUTME: Entry point for device migration and app information.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/first_launch_provider.dart';
import '../theme.dart';

const _themeModeLabels = {
  ThemeMode.system: 'System',
  ThemeMode.light: 'Light',
  ThemeMode.dark: 'Dark',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: colors.border),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(
                  mode == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: mode == current ? colors.accent : colors.textMuted,
                ),
                title: Text(
                  _themeModeLabels[mode]!,
                  style: TextStyle(
                    color: mode == current ? colors.accent : colors.textPrimary,
                  ),
                ),
                onTap: () {
                  ref.read(themeModeProvider.notifier).setMode(mode);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  height: 1.25,
                ),
              ),
            ),
            _SettingsRow(
              icon: Icons.palette_outlined,
              label: 'Appearance',
              trailing: Text(
                _themeModeLabels[themeMode]!,
                style: TextStyle(fontSize: 14, color: colors.textMuted),
              ),
              onTap: () => _showThemePicker(context, ref),
            ),
            Divider(color: colors.border, height: 1, indent: 24, endIndent: 24),
            _SettingsRow(
              icon: Icons.upload_outlined,
              label: 'Export cards',
              onTap: () => context.push('/settings/export'),
            ),
            Divider(color: colors.border, height: 1, indent: 24, endIndent: 24),
            _SettingsRow(
              icon: Icons.download_outlined,
              label: 'Import cards',
              onTap: () => context.push('/settings/import'),
            ),
            Divider(color: colors.border, height: 1, indent: 24, endIndent: 24),
            _SettingsRow(
              icon: Icons.info_outline,
              label: 'About',
              onTap: () => context.push('/settings/about'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: colors.textPrimary),
      title: Text(
        label,
        style: TextStyle(fontSize: 16, color: colors.textPrimary),
      ),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                trailing!,
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: colors.textMuted),
              ],
            )
          : Icon(Icons.chevron_right, color: colors.textMuted),
      onTap: onTap,
    );
  }
}
