import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../data/auth_models.dart';
import '../../data/auth_repository.dart';
import '../auth_notifier.dart';

class PrivacyPolicyConsentPage extends ConsumerStatefulWidget {
  const PrivacyPolicyConsentPage({super.key});

  @override
  ConsumerState<PrivacyPolicyConsentPage> createState() =>
      _PrivacyPolicyConsentPageState();
}

class _PrivacyPolicyConsentPageState extends ConsumerState<PrivacyPolicyConsentPage> {
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
      appBar: AppBar(
        title: const Text('Privacy Policy Consent'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: FutureBuilder<PrivacyPolicyDocument>(
          future: _policyFuture,
          builder: (context, snapshot) {
            final policy = snapshot.data;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PolicyHero(policy: policy, isLoading: isLoading),
                        const SizedBox(height: AppSpacing.lg),
                        _PolicySummaryStrip(isLoading: isLoading),
                        const SizedBox(height: AppSpacing.lg),
                        _PolicyCard(
                          title: 'Policy document',
                          subtitle:
                              'Read the terms below before you continue. The important clauses are highlighted to avoid ambiguity.',
                          child: isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(AppSpacing.xxl),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.white,
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
                          onChanged: (value) => setState(() => _acknowledged = value),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _PolicyCard(
                          title: 'Before you accept',
                          subtitle:
                              'This acknowledgement is permanent for this policy version. Loss of the master password means loss of access to encrypted vault data.',
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RuleLine(text: 'Keep your master password safe.'),
                              SizedBox(height: AppSpacing.sm),
                              _RuleLine(text: 'The server cannot read your vault data.'),
                              SizedBox(height: AppSpacing.sm),
                              _RuleLine(text: 'Acceptance is required to access the vault.'),
                            ],
                          ),
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
                              ? 'Saving consent...'
                              : 'Accept policy and continue',
                          icon: Icons.verified,
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
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PolicyHero extends StatelessWidget {
  const _PolicyHero({required this.policy, required this.isLoading});

  final PrivacyPolicyDocument? policy;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppTheme.black,
        border: Border.all(color: AppTheme.white),
        borderRadius: AppRadius.brXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consent required before vault access',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: AppType.title,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: AppType.body,
                          height: 1.45,
                        ),
                        children: [
                          TextSpan(text: 'Please review the policy carefully. '),
                          TextSpan(
                            text: 'The bold, underlined statements below are the binding parts.',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                              decorationThickness: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _VersionBadge(
                label: isLoading ? 'Loading' : 'Version',
                value: isLoading ? '...' : policy?.version ?? '-',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isLoading
                ? 'Loading latest policy...'
                : 'Updated ${_formatDate(policy?.updatedAt)}',
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _PolicySummaryStrip extends StatelessWidget {
  const _PolicySummaryStrip({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Zero knowledge',
            value: 'Server cannot read vault content',
            emphasized: true,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: 'Master password',
            value: 'Loss means permanent loss of access',
            emphasized: false,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.emphasized,
    required this.isLoading,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.black,
        border: Border.all(color: AppTheme.white),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isLoading ? '...' : value,
            style: TextStyle(
              color: AppTheme.white,
              fontSize: AppType.body,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              fontStyle: emphasized ? FontStyle.italic : FontStyle.normal,
              decoration:
                  emphasized ? TextDecoration.underline : TextDecoration.none,
              decorationThickness: 1.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppRadius.brPill,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.black,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.black,
              fontSize: AppType.body,
              fontWeight: FontWeight.w900,
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
        color: AppTheme.black,
        border: Border.all(color: AppTheme.white),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: AppType.caption,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
          color: AppTheme.white,
          fontSize: AppType.subtitle,
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.underline,
          decorationThickness: 2,
        ),
      );
    }

    if (section.startsWith('## ')) {
      return Text(
        section.substring(3),
        style: const TextStyle(
          color: AppTheme.white,
          fontSize: AppType.body,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
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
          color: AppTheme.white,
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
          child: Text('• ', style: TextStyle(color: AppTheme.white)),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppTheme.white,
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

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final split = text.split(':');
    final lead = split.first;
    final tail = split.length > 1 ? split.sublist(1).join(':').trim() : '';

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppTheme.white,
          fontSize: AppType.body,
          height: 1.45,
        ),
        children: [
          TextSpan(
            text: lead,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
            ),
          ),
          if (tail.isNotEmpty)
            TextSpan(
              text: ': $tail',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
        ],
      ),
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
          fontWeight: bold ? FontWeight.w900 : FontWeight.normal,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          decoration: underline ? TextDecoration.underline : TextDecoration.none,
          decorationThickness: 1.5,
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppTheme.black,
        border: Border.all(color: AppTheme.white),
        borderRadius: AppRadius.brXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Required acknowledgement',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'You must confirm the clauses below before the app unlocks the vault.',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: AppType.caption,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            value: acknowledged,
            onChanged: (value) => onChanged(value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.white,
            checkColor: AppTheme.black,
            title: const Text(
              'I understand that KeepIt cannot recover my encrypted data if I lose my master password.',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: AppType.body,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: const Text(
              'Acceptance is required before the vault can be opened.',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: AppType.micro,
                fontStyle: FontStyle.italic,
              ),
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
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.error,
          fontSize: AppType.body,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
