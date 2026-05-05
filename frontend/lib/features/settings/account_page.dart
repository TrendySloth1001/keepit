import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/keepit_app_bar.dart';
import '../../shared/widgets/settings_tile.dart';
import '../auth/presentation/auth_notifier.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: const KeepItAppBar(title: 'Account'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (user != null) _ProfileCard(name: user.name, email: user.email, avatarUrl: user.avatarUrl),
            const SectionLabel(text: 'Account'),
            SettingsTile(
              icon: Icons.lock_reset_outlined,
              title: 'Change Master Password',
              subtitle: 'Re-encrypts your vault locally',
              onTap: () => context.push('/vault/account/master-password'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.download_outlined,
              title: 'Export Data',
              subtitle: 'Download a decrypted JSON backup',
              onTap: () => context.push('/vault/account/export'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Manage Subscription',
              subtitle: 'Plans and billing',
              onTap: () => _comingSoon(context, 'Subscriptions'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Settings',
              subtitle: 'Data, telemetry & sharing',
              onTap: () => context.push('/vault/account/privacy'),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Sign Out',
              variant: AppButtonVariant.secondary,
              icon: Icons.logout,
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Sign out?',
                  message: 'Your encrypted vault will stay on the server.',
                  confirmLabel: 'Sign out',
                  destructive: true,
                );
                if (ok == true) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.avatarUrl,
  });
  final String name;
  final String email;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final firstInitial = name.isEmpty ? '?' : name[0].toUpperCase();
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
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primarySoft,
                backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? Text(
                        firstInitial,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppTheme.fg,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: const Text(
                        'Free Plan',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(color: AppTheme.hairline, height: 1),
          ),
          const Row(
            children: [
              Expanded(
                child: _MetaCol(label: 'Member Since', value: '—'),
              ),
              Expanded(
                child: _MetaCol(label: 'Last Login', value: 'Today'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaCol extends StatelessWidget {
  const _MetaCol({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.fg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
