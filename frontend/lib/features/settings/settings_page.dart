import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/sketch.dart';
import '../../app/theme/tokens.dart';
import '../../shared/storage/settings_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/keepit_app_bar.dart';
import '../auth/presentation/auth_notifier.dart';
import 'settings_notifier.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: KeepItAppBar(title: 'Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (user != null) ...[
              _SectionHeader('Account'),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.patrickHand(
                        color: AppTheme.fg,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: AppType.caption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _SectionHeader('Privacy policy'),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _SketchBadgePainter(
                              accepted: user.policyAcceptedCurrent,
                            ),
                            child: Center(
                              child: Icon(
                                user.policyAcceptedCurrent
                                    ? Icons.verified
                                    : Icons.error_outline,
                                color: user.policyAcceptedCurrent
                                    ? AppTheme.onPrimary
                                    : AppTheme.fg,
                                size: AppIconSize.md,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.policyAcceptedCurrent
                                    ? 'Privacy policy accepted'
                                    : 'Privacy policy not yet accepted',
                                style: GoogleFonts.patrickHand(
                                  color: AppTheme.fg,
                                  fontSize: AppType.subtitle,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.policyAcceptedCurrent
                                    ? 'The current policy version has been accepted for this account.'
                                    : 'The vault stays blocked until you accept the latest policy version.',
                                style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: AppType.caption,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _DetailRow(
                      label: 'Current version',
                      value: user.currentPolicyVersion,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow(
                      label: 'Accepted version',
                      value: user.policyAcceptedVersion ?? 'Not accepted yet',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow(
                      label: 'Accepted at',
                      value: user.policyAcceptedAt == null
                          ? 'Pending'
                          : _formatDateTime(user.policyAcceptedAt!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            _SectionHeader('Auto-lock'),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lock the vault after this much idle time. '
                    'In-app inactivity and time spent in the background both count.',
                    style: TextStyle(
                      color: AppTheme.fg,
                      fontSize: AppType.caption,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final option in AutoLockOption.values)
                    _RadioRow(
                      label: option.label,
                      selected: settings.autoLock == option,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAutoLock(option),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _SectionHeader('Master password'),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skip the master password prompt by storing the '
                    'derived key in this device’s OS-encrypted secure '
                    'storage (Android Keystore / iOS Keychain). The server '
                    'still never sees the key.',
                    style: TextStyle(
                      color: AppTheme.fg,
                      fontSize: AppType.caption,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Trade-off: anyone with access to your unlocked phone '
                    'gains access to your vault.',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: AppType.micro,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTheme.fg,
                    activeTrackColor: AppTheme.primary,
                    title: Text(
                      'Remember on this device',
                      style: GoogleFonts.patrickHand(
                        color: AppTheme.fg,
                        fontSize: AppType.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    value: settings.rememberMasterKey,
                    onChanged: (v) => _toggleRemember(context, ref, v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _SectionHeader('Session'),
            AppButton(
              label: 'Sign out',
              icon: Icons.logout,
              variant: AppButtonVariant.danger,
              onPressed: () => _signOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRemember(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final notifier = ref.read(settingsProvider.notifier);
    final auth = ref.read(authProvider.notifier);

    if (value) {
      final ok = await showConfirmDialog(
        context,
        title: 'Remember master password?',
        message:
            'Your master key will be stored on this device. You will not be '
            'asked for the master password until you sign out.',
        confirmLabel: 'Enable',
      );
      if (!ok) return;
      await notifier.setRememberMasterKey(true);
      await auth.persistCurrentKey();
      if (context.mounted) {
        showAppSnack(
          context,
          'Master password remembered',
          kind: AppSnackKind.success,
        );
      }
    } else {
      await notifier.setRememberMasterKey(false);
      if (context.mounted) {
        showAppSnack(
          context,
          'Stored master key cleared',
          kind: AppSnackKind.info,
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message:
          'You will need your Google account and master password to sign back '
          'in. Encrypted items remain in the cloud.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(authProvider.notifier).logout();
  }

  String _formatDateTime(DateTime dateTime) {
    final date =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.patrickHand(
          color: AppTheme.muted,
          fontSize: AppType.micro,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SketchBox(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: 18,
      fill: AppTheme.surface,
      seed: identityHashCode(child),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.patrickHand(
              color: AppTheme.muted,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.patrickHand(
              color: AppTheme.fg,
              fontSize: AppType.body,
              fontWeight: label == 'Accepted at'
                  ? FontWeight.w600
                  : FontWeight.w800,
              fontStyle: label == 'Accepted at' && value != 'Pending'
                  ? FontStyle.italic
                  : FontStyle.normal,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(
                size: Size.infinite,
                painter: _RadioPainter(
                  selected: selected,
                  seed: label.hashCode,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: GoogleFonts.patrickHand(
                color: AppTheme.fg,
                fontSize: AppType.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioPainter extends CustomPainter {
  _RadioPainter({required this.selected, required this.seed});
  final bool selected;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final border = RoughCircleBorder(
        color: AppTheme.fg, strokeWidth: 1.4, seed: seed);
    border.paint(canvas, rect);
    if (selected) {
      final inner = rect.deflate(5);
      final fill = SketchPaint.roughRRect(inner, inner.width / 2,
          seed: seed + 1, jitter: 0.6);
      canvas.drawPath(
        fill,
        Paint()..color = AppTheme.fg..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RadioPainter old) =>
      old.selected != selected || old.seed != seed;
}

class _SketchBadgePainter extends CustomPainter {
  _SketchBadgePainter({required this.accepted});
  final bool accepted;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (accepted) {
      final path = const RoughCircleBorder(seed: 51).getOuterPath(rect);
      canvas.drawPath(
        path,
        Paint()..color = AppTheme.primary..style = PaintingStyle.fill,
      );
      SketchPaint.hatch(canvas, path,
          color: AppTheme.onPrimary.withValues(alpha: 0.20),
          spacing: 4,
          seed: 52);
    }
    const RoughCircleBorder(color: AppTheme.fg, strokeWidth: 1.5, seed: 51)
        .paint(canvas, rect);
  }

  @override
  bool shouldRepaint(_SketchBadgePainter old) => old.accepted != accepted;
}
