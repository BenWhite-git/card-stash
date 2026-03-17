// ABOUTME: Settings screen with export, import, and about navigation.
// ABOUTME: Entry point for device migration and app information.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF8FAFC),
                  height: 1.25,
                ),
              ),
            ),
            _SettingsRow(
              icon: Icons.upload_outlined,
              label: 'Export cards',
              onTap: () => context.push('/settings/export'),
            ),
            const Divider(
              color: Color(0xFF334155),
              height: 1,
              indent: 24,
              endIndent: 24,
            ),
            _SettingsRow(
              icon: Icons.download_outlined,
              label: 'Import cards',
              onTap: () => context.push('/settings/import'),
            ),
            const Divider(
              color: Color(0xFF334155),
              height: 1,
              indent: 24,
              endIndent: 24,
            ),
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
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: const Color(0xFFF8FAFC)),
      title: Text(
        label,
        style: const TextStyle(fontSize: 16, color: Color(0xFFF8FAFC)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
