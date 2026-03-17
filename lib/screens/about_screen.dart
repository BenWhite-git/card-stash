// ABOUTME: App info screen with version, Ko-fi link, licences, and attribution.
// ABOUTME: Follows Ben White app portfolio pattern with always-light theme.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const _bgPrimary = Color(0xFFFFFBF7);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _cardBorder = Color(0xFFE7E5E4);
  static const _textPrimary = Color(0xFF1C1917);
  static const _textSecondary = Color(0xFF44403C);
  static const _textMuted = Color(0xFF78716C);
  static const _accent = Color(0xFFD97706);
  static const _accentFill = Color(0xFFF59E0B);
  static const _divider = Color(0xFFD6D3D1);

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

  ThemeData get _lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _bgPrimary,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: _textPrimary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _lightTheme,
      child: Scaffold(
        backgroundColor: _bgPrimary,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
              const Text(
                'Card Stash',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Version
              Text(
                _version,
                style: const TextStyle(fontSize: 14, color: _textMuted),
              ),
              const SizedBox(height: 24),
              // Description card
              _CardContainer(
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'A simple app to stash your loyalty and membership cards. '
                    'Built in Cheshire, England.',
                    style: TextStyle(
                      fontSize: 15,
                      color: _textSecondary,
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
                      side: const BorderSide(color: _accentFill, width: 1.5),
                      foregroundColor: _accent,
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
                      onTap: () => _launch(
                        'https://benwhite.co/lab/privacy-policy.html',
                      ),
                    ),
                    const Divider(
                      color: _divider,
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
                    const Divider(
                      color: _divider,
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
              const Text(
                'Open source. MIT Licence.',
                style: TextStyle(fontSize: 13, color: _textMuted),
              ),
              const SizedBox(height: 4),
              const Text(
                '\u00a9 2026 Ben White. All rights reserved.',
                style: TextStyle(fontSize: 13, color: _textMuted),
              ),
              const SizedBox(height: 32),
            ],
          ),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _AboutScreenState._cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AboutScreenState._cardBorder),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          color: _AboutScreenState._textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: _AboutScreenState._textMuted,
      ),
      onTap: onTap,
    );
  }
}
