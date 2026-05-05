import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../../data/auth_models.dart';
import '../../data/auth_repository.dart';
import '../auth_notifier.dart';

class PrivacyPolicyConsentPage extends ConsumerStatefulWidget {
  const PrivacyPolicyConsentPage({super.key});

  @override
  ConsumerState<PrivacyPolicyConsentPage> createState() =>
      _PrivacyPolicyConsentPageState();
}

class _PrivacyPolicyConsentPageState
    extends ConsumerState<PrivacyPolicyConsentPage> {
  bool _acknowledged = false;
  late final Future<PrivacyPolicyDocument> _policyFuture;

  @override
  void initState() {
    super.initState();
    _policyFuture = AuthRepository.instance.getCurrentPrivacyPolicy();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: const KeepItAppBar(title: 'Privacy Policy'),
      body: SafeArea(
        child: FutureBuilder<PrivacyPolicyDocument>(
          future: _policyFuture,
          builder: (context, snapshot) {
            final policy = snapshot.data;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(policy: policy, isLoading: isLoading),
                  const SizedBox(height: AppSpacing.lg),
                  _SummaryStrip(),
                  const SizedBox(height: AppSpacing.lg),
                  _PolicyCard(
                    title: 'Policy document',
                    subtitle:
                        'Read the terms below before you continue. Bold lines are the binding clauses.',
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.xxl),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                              ),
                            ),
                          )
                        : snapshot.hasError
                            ? const _PolicyError(
                                message:
                                    'Unable to load the latest policy. Please retry.',
                              )
                            : _PolicyBody(policy: policy!),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ConsentPanel(
                    acknowledged: _acknowledged,
                    onChanged: (value) =>
                        setState(() => _acknowledged = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (auth.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: AppType.caption,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  AppButton(
                    label: auth.isBusy
                        ? 'Saving consent…'
                        : 'Accept and continue',
                    icon: Icons.verified,
                    variant: AppButtonVariant.accent,
                    onPressed: !_acknowledged || auth.isBusy || policy == null
                        ? null
                        : () async {
                            await notifier.acceptLatestPrivacyPolicy();
                            if (context.mounted &&
                                ref.read(authProvider).stage !=
                                    AuthStage.needsPolicyConsent) {
                              showAppSnack(
                                context,
                                'Privacy policy accepted',
                                kind: AppSnackKind.success,
                              );
                            }
                          },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.policy, required this.isLoading});

  final PrivacyPolicyDocument? policy;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppTheme.heroGreen,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppTheme.hairline),
                ),
                child: Text(
                  isLoading ? 'Loading…' : 'Version ${policy?.version ?? "—"}',
                  style: const TextStyle(
                    color: AppTheme.fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Consent required',
            style: TextStyle(
              color: AppTheme.fg,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Please review the privacy policy. Your master password is the only key that decrypts your vault — keep it safe.',
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (!isLoading && policy?.updatedAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Updated ${_formatDate(policy!.updatedAt)}',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _SummaryStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            icon: Icons.lock_outline,
            label: 'Zero knowledge',
            value: 'Server can\'t read your vault',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            icon: Icons.key_outlined,
            label: 'Master key',
            value: 'Lose it, lose access',
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryDark),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _PolicyBody extends StatelessWidget {
  const _PolicyBody({required this.policy});

  final PrivacyPolicyDocument policy;

  @override
  Widget build(BuildContext context) {
    final sections = policy.content.split('\n\n');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      separatorBuilder: (context, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final text = sections[index].trim();
        if (text.isEmpty) return const SizedBox.shrink();
        return _PolicySection(section: text);
      },
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.section});

  final String section;

  @override
  Widget build(BuildContext context) {
    if (section.startsWith('# ')) {
      return Text(
        section.substring(2),
        style: const TextStyle(
          color: AppTheme.fg,
          fontSize: AppType.subtitle,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    if (section.startsWith('## ')) {
      return Text(
        section.substring(3),
        style: const TextStyle(
          color: AppTheme.fg,
          fontSize: AppType.body,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    if (section.startsWith('- ')) {
      final lines = section.split('\n');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _BulletLine(text: line.substring(2)),
            ),
        ],
      );
    }

    final lines = section.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _FormattedParagraph(text: line),
          ),
      ],
    );
  }
}

class _FormattedParagraph extends StatelessWidget {
  const _FormattedParagraph({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppTheme.fg,
          fontSize: AppType.body,
          height: 1.55,
        ),
        children: _parseInlineStyles(text),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: Icon(Icons.circle, color: AppTheme.primary, size: 6),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppTheme.fg,
                fontSize: AppType.body,
                height: 1.5,
              ),
              children: _parseInlineStyles(text),
            ),
          ),
        ),
      ],
    );
  }
}

List<InlineSpan> _parseInlineStyles(String text) {
  final spans = <InlineSpan>[];
  final buffer = StringBuffer();
  bool bold = false;
  bool italic = false;
  bool underline = false;

  void flush() {
    if (buffer.isEmpty) return;
    spans.add(
      TextSpan(
        text: buffer.toString(),
        style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          decoration: underline
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      ),
    );
    buffer.clear();
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == '*' && i + 1 < text.length && text[i + 1] == '*') {
      flush();
      bold = !bold;
      i++;
      continue;
    }
    if (char == '_' && i + 1 < text.length && text[i + 1] == '_') {
      flush();
      underline = !underline;
      i++;
      continue;
    }
    if (char == '*' && (i == 0 || text[i - 1] != '*')) {
      flush();
      italic = !italic;
      continue;
    }
    buffer.write(char);
  }

  flush();
  return spans;
}

class _ConsentPanel extends StatelessWidget {
  const _ConsentPanel({required this.acknowledged, required this.onChanged});

  final bool acknowledged;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: acknowledged ? AppTheme.primary : AppTheme.hairline,
          width: acknowledged ? 1.4 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: acknowledged,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I understand and accept',
                  style: TextStyle(
                    color: AppTheme.fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'KeepIt cannot recover my encrypted data if I lose my master password. Acceptance is required to access the vault.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyError extends StatelessWidget {
  const _PolicyError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.error,
            fontSize: AppType.body,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
