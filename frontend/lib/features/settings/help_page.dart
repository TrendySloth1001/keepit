import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../shared/widgets/icon_badge.dart';
import '../../shared/widgets/keepit_app_bar.dart';
import '../../shared/widgets/settings_tile.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: const KeepItAppBar(title: 'Help & Support'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _NeedHelpCard(onAction: (l) => _comingSoon(context, l)),
            const SizedBox(height: AppSpacing.lg),
            SettingsTile(
              icon: Icons.help_outline,
              title: 'FAQs',
              onTap: () => _comingSoon(context, 'FAQs'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.description_outlined,
              title: 'Documentation',
              onTap: () => _comingSoon(context, 'Documentation'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.videocam_outlined,
              title: 'Video Tutorials',
              onTap: () => _comingSoon(context, 'Tutorials'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.bug_report_outlined,
              title: 'Report a Bug',
              onTap: () => _comingSoon(context, 'Bug report'),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon')),
    );
  }
}

class _NeedHelpCard extends StatelessWidget {
  const _NeedHelpCard({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              IconBadge(icon: Icons.question_mark, size: 44),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        color: AppTheme.fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "We're here to assist you",
                      style: TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.menu_book_outlined,
                  label: 'Guides',
                  onTap: () => onAction('Guides'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  onTap: () => onAction('Live chat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  onTap: () => onAction('Email support'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionButton(
                  icon: Icons.phone_outlined,
                  label: 'Call',
                  onTap: () => onAction('Phone support'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.hairline),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.fg, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
