import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';

class UpgradePage extends StatelessWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppTheme.fg),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.workspace_premium,
                size: 80,
                color: AppTheme.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Upgrade to Premium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.fg,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Get 2GB of encrypted storage and save unlimited items across all your devices.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _Feature(
                icon: Icons.cloud_done_outlined,
                text: '2GB Secure Storage',
              ),
              const SizedBox(height: AppSpacing.md),
              _Feature(
                icon: Icons.all_inclusive,
                text: 'Unlimited Passwords & Notes',
              ),
              const SizedBox(height: AppSpacing.md),
              _Feature(icon: Icons.devices, text: 'Cross-device Sync'),
              const Spacer(flex: 2),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'We are working hard to bring you premium features. Stay tuned!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: null, // Disabled to show coming soon
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.surfaceAlt,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.fg,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
