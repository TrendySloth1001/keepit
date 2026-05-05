import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/inline_message.dart';
import '../../shared/widgets/keepit_app_bar.dart';
import '../../shared/widgets/settings_tile.dart';
import '../auth/data/auth_models.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/auth_notifier.dart';

class PrivacySettingsPage extends ConsumerStatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  ConsumerState<PrivacySettingsPage> createState() =>
      _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends ConsumerState<PrivacySettingsPage> {
  bool _telemetry = false;
  bool _crashReports = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: const KeepItAppBar(title: 'Privacy Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.heroGreen,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You\'re in control',
                          style: TextStyle(
                            color: AppTheme.fg,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Vault data is end-to-end encrypted. Only you have the key.',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionLabel(text: 'Data'),
            SettingsTile(
              icon: Icons.analytics_outlined,
              title: 'Anonymous usage analytics',
              subtitle: _telemetry
                  ? 'Helping improve KeepIt'
                  : 'No usage data leaves your device',
              trailing: Switch(
                value: _telemetry,
                onChanged: (v) => setState(() => _telemetry = v),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.bug_report_outlined,
              title: 'Crash reports',
              subtitle: 'Send error stack traces (no vault content)',
              trailing: Switch(
                value: _crashReports,
                onChanged: (v) => setState(() => _crashReports = v),
              ),
            ),
            const SectionLabel(text: 'Policy'),
            SettingsTile(
              icon: Icons.description_outlined,
              title: 'View Privacy Policy',
              subtitle: 'Read the current document',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _PolicyViewerPage()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsTile(
              icon: Icons.history_toggle_off,
              title: 'Acceptance history',
              subtitle: () {
                final user = ref.watch(authProvider).user;
                if (user?.policyAcceptedAt == null) return 'Not accepted yet';
                final v = user?.policyAcceptedVersion ?? '—';
                return 'Accepted v$v on ${_fmtDate(user!.policyAcceptedAt!)}';
              }(),
            ),
            const SectionLabel(text: 'Danger zone'),
            const InlineMessage(
              message:
                  'Deleting your account is permanent and removes every encrypted item.',
              kind: InlineMessageKind.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Delete account',
              icon: Icons.delete_forever_outlined,
              variant: AppButtonVariant.danger,
              onPressed: () => _confirmDelete(context),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete account?',
      message:
          'This permanently deletes your account and all encrypted items. We cannot recover them.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !context.mounted) return;
    showAppSnack(
      context,
      'Email support@keepit.app to confirm account deletion',
      kind: AppSnackKind.info,
    );
  }
}

class _PolicyViewerPage extends StatefulWidget {
  const _PolicyViewerPage();

  @override
  State<_PolicyViewerPage> createState() => _PolicyViewerPageState();
}

class _PolicyViewerPageState extends State<_PolicyViewerPage> {
  late final Future<PrivacyPolicyDocument> _future;

  @override
  void initState() {
    super.initState();
    _future = AuthRepository.instance.getCurrentPrivacyPolicy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: const KeepItAppBar(title: 'Privacy Policy'),
      body: SafeArea(
        child: FutureBuilder<PrivacyPolicyDocument>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }
            if (snap.hasError || snap.data == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: InlineMessage(
                    message: 'Could not load the policy.',
                    kind: InlineMessageKind.error,
                  ),
                ),
              );
            }
            final p = snap.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(
                      color: AppTheme.fg,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v${p.version}',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    p.content,
                    style: const TextStyle(
                      color: AppTheme.fg,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.huge),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
