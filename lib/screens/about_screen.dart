// ABOUTME: App info screen with version, Ko-fi link, licences, and attribution.
// ABOUTME: Follows the app's theme for visual consistency.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = info.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Go back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // App icon
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icon/app_icon_64.png',
                width: 64,
                height: 64,
                semanticLabel: 'Card Stash app icon',
              ),
            ),
            const SizedBox(height: 16),
            // App name
            Text(
              'Card Stash',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Version
            Text(
              _version,
              style: TextStyle(fontSize: 14, color: colors.textMuted),
            ),
            const SizedBox(height: 24),
            // Description card
            _CardContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'A simple app to stash your loyalty and membership cards. '
                  'Built in Cheshire, England.',
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Ko-fi card
            _CardContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () => _launch('https://ko-fi.com/benwhitelabs'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.accent, width: 1.5),
                    foregroundColor: colors.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Support on Ko-fi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legal rows card
            _CardContainer(
              child: Column(
                children: [
                  _AboutRow(
                    label: 'Privacy Policy',
                    onTap: () =>
                        _launch('https://benwhite.co/lab/privacy-policy.html'),
                  ),
                  Divider(
                    color: colors.border,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _AboutRow(
                    label: 'Open Source Licences',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Card Stash',
                      applicationVersion: _version,
                    ),
                  ),
                  Divider(
                    color: colors.border,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _AboutRow(
                    label: 'GitHub',
                    onTap: () =>
                        _launch('https://github.com/BenWhite-git/card-stash'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Footer
            Text(
              'Open source. MIT Licence.',
              style: TextStyle(fontSize: 13, color: colors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              '\u00a9 2026 Ben White. All rights reserved.',
              style: TextStyle(fontSize: 13, color: colors.textMuted),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;

  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AboutRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        label,
        style: TextStyle(fontSize: 16, color: colors.textPrimary),
      ),
      trailing: Icon(Icons.chevron_right, color: colors.textMuted),
      onTap: onTap,
    );
  }
}
