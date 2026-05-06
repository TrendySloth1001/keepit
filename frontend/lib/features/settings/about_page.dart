import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../shared/widgets/keepit_app_bar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchFlaticonUrl() async {
    final url = Uri.parse('https://www.flaticon.com/free-icons/wallet');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchUnsplashUrl() async {
    final url = Uri.parse(
      'https://unsplash.com/photos/a-white-abstract-background-with-wavy-lines-p0j-mE6mGo4',
    );
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.bg,
      appBar: const KeepItAppBar(title: ''),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1080&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.95),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/logo/wallet-passes-app-logo.png',
                      width: 50,
                      height: 50,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'KeepIt',
                    style: TextStyle(
                      color: AppTheme.fg,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: AppTheme.muted, fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const Text(
                    'A secure, end-to-end encrypted vault for all your secrets.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.fg,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  const Divider(color: AppTheme.hairline),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Attributions',
                    style: TextStyle(
                      color: AppTheme.fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: _launchFlaticonUrl,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Wallet icons created by Freepik - Flaticon',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: _launchUnsplashUrl,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Background image by Milad Fakurian - Unsplash',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
