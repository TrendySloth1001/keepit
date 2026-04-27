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
        title: const Text('Privacy Policy'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: FutureBuilder<PrivacyPolicyDocument>(
          future: _policyFuture,
          builder: (context, snapshot) {
            final policy = snapshot.data;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PolicyHero(policy: policy, isLoading: isLoading),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppTheme.black,
                        border: Border.all(color: AppTheme.white),
                        borderRadius: AppRadius.brLg,
                      ),
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.white,
                              ),
                            )
                          : snapshot.hasError
                              ? _PolicyError(
                                  message: 'Unable to load the latest policy. Please retry.',
                                )
                              : _PolicyBody(policy: policy!),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ConsentPanel(
                    acknowledged: _acknowledged,
                    onChanged: (value) => setState(() => _acknowledged = value),
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
                        ),
                      ),
                    ),
                  AppButton(
                    label: auth.isBusy ? 'Saving consent...' : 'Accept policy and continue',
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
                ],
              ),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.black,
        border: Border.all(color: AppTheme.white),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Before you unlock the vault',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: AppType.title,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'We use a zero-knowledge model. Your vault content is encrypted on your device and the server cannot read it.',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: AppType.body,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isLoading
                ? 'Loading latest policy...'
                : 'Version ${policy?.version ?? '-'} • Updated ${_formatDate(policy?.updatedAt)}',
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

class _PolicyBody extends StatelessWidget {
  const _PolicyBody({required this.policy});

  final PrivacyPolicyDocument policy;

  @override
  Widget build(BuildContext context) {
    final sections = policy.content.split('\n\n');

    return ListView.separated(
      itemCount: sections.length,
      separatorBuilder: (context, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final text = sections[index].trim();
        if (text.isEmpty) return const SizedBox.shrink();
        if (text.startsWith('# ')) {
          return Text(
            text.substring(2),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: AppType.subtitle,
              fontWeight: FontWeight.w800,
            ),
          );
        }
        if (text.startsWith('## ')) {
          return Text(
            text.substring(3),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: AppType.body,
              fontWeight: FontWeight.w800,
            ),
          );
        }
        if (text.startsWith('- ')) {
          final lines = text.split('\n');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppTheme.white)),
                      Expanded(
                        child: Text(
                          line.substring(2),
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: AppType.body,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }
        return Text(
          text,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: AppType.body,
            height: 1.5,
          ),
        );
      },
    );
  }
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
        color: AppTheme.black,
        border: Border.all(color: AppTheme.white),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Required acknowledgement',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: AppType.body,
              fontWeight: FontWeight.w800,
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
                height: 1.4,
              ),
            ),
            subtitle: const Text(
              'Acceptance is required before the vault can be opened.',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: AppType.micro,
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
        ),
      ),
    );
  }
}
