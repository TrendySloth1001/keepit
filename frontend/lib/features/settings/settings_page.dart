import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../shared/auth/biometric_service.dart';
import '../../shared/storage/settings_service.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/keepit_app_bar.dart';
import '../../shared/widgets/settings_tile.dart';
import '../auth/presentation/auth_notifier.dart';
import 'settings_notifier.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: const KeepItAppBar(title: 'Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (user != null)
              _ProfileSummary(
                name: user.name,
                email: user.email,
                avatarUrl: user.avatarUrl,
                onTap: () => context.push('/vault/account'),
              ),
            const SectionLabel(text: 'Account'),
            SettingsTile(
              icon: Icons.person_outline,
              title: 'Profile & subscription',
              subtitle: 'Plan, member info, sign out',
              onTap: () => context.push('/vault/account'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.lock_reset_outlined,
              title: 'Change Master Password',
              subtitle: 'Re-encrypts your vault locally',
              onTap: () => context.push('/vault/account/master-password'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Settings',
              subtitle: 'Data, telemetry, account deletion',
              onTap: () => context.push('/vault/account/privacy'),
            ),

            const SectionLabel(text: 'Security'),
            SettingsTile(
              icon: Icons.fingerprint,
              title: 'Biometric Lock',
              subtitle: settings.biometricLock
                  ? 'Unlock with biometrics — no master password'
                  : 'Master password required',
              trailing: Switch(
                value: settings.biometricLock,
                onChanged: (v) => _toggleBiometric(context, ref, v),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.timer_outlined,
              title: 'Auto-lock',
              subtitle: settings.autoLock.label,
              onTap: () => _pickAutoLock(context, ref, settings.autoLock),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Two-Factor Auth',
              subtitle: 'Authenticator app · coming soon',
              onTap: () => _comingSoon(context, 'Two-factor auth'),
            ),

            const SectionLabel(text: 'Sharing & Backup'),
            SettingsTile(
              icon: Icons.group_outlined,
              title: 'Shared with me',
              subtitle: 'View items others shared with you',
              onTap: () => context.push('/vault/shared'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.download_outlined,
              title: 'Export Data',
              subtitle: 'Download a decrypted JSON backup',
              onTap: () => context.push('/vault/account/export'),
            ),

            const SectionLabel(text: 'Notifications'),
            SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Security alerts',
              subtitle: 'Login notifications · coming soon',
              onTap: () => _comingSoon(context, 'Notifications'),
            ),

            const SectionLabel(text: 'Support'),
            SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Guides, FAQs, contact us',
              onTap: () => context.push('/vault/help'),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    bool desired,
  ) async {
    if (desired) {
      final supported = await BiometricService.instance.isSupported();
      if (!context.mounted) return;
      if (!supported) {
        showAppSnack(
          context,
          'No biometrics enrolled on this device',
          kind: AppSnackKind.error,
        );
        return;
      }
      final ok = await BiometricService.instance.authenticate(
        reason: 'Confirm to enable biometric unlock',
      );
      if (!context.mounted) return;
      if (!ok) {
        showAppSnack(
          context,
          'Biometric verification failed',
          kind: AppSnackKind.error,
        );
        return;
      }
      // Vault must be unlocked so we have a master key to persist.
      final masterKey = ref.read(authProvider.notifier).masterKey;
      if (masterKey == null) {
        showAppSnack(
          context,
          'Unlock the vault first',
          kind: AppSnackKind.error,
        );
        return;
      }
      await ref.read(settingsProvider.notifier).setBiometricLock(true);
      await SettingsService.instance.writeMasterKey(masterKey);
      if (!context.mounted) return;
      showAppSnack(
        context,
        'Biometric lock enabled',
        kind: AppSnackKind.success,
      );
    } else {
      await ref.read(settingsProvider.notifier).setBiometricLock(false);
      if (!context.mounted) return;
      showAppSnack(context, 'Biometric lock disabled');
    }
  }

  Future<void> _pickAutoLock(
    BuildContext context,
    WidgetRef ref,
    AutoLockOption current,
  ) async {
    final option = await showModalBottomSheet<AutoLockOption>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Auto-lock vault',
                  style: TextStyle(
                    color: AppTheme.fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              for (final o in AutoLockOption.values)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  title: Text(o.label),
                  trailing: o == current
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, o),
                ),
            ],
          ),
        ),
      ),
    );
    if (option != null) {
      await ref.read(settingsProvider.notifier).setAutoLock(option);
    }
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon')),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.onTap,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primarySoft,
                backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
