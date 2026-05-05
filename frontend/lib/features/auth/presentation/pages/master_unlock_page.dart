import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/auth/biometric_service.dart';
import '../../../../shared/storage/settings_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../auth_notifier.dart';

class MasterUnlockPage extends ConsumerStatefulWidget {
  const MasterUnlockPage({super.key});

  @override
  ConsumerState<MasterUnlockPage> createState() => _MasterUnlockPageState();
}

class _MasterUnlockPageState extends ConsumerState<MasterUnlockPage> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  bool _biometricBusy = false;
  String? _biometricError;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final settings = await SettingsService.instance.read();
    final supported = await BiometricService.instance.isSupported();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = settings.biometricLock;
      _biometricSupported = supported;
    });
    if (_biometricEnabled && supported) {
      // Auto-prompt on entry. The user can cancel and fall back to password.
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_biometricBusy) return;
    setState(() {
      _biometricBusy = true;
      _biometricError = null;
    });
    final ok = await ref.read(authProvider.notifier).unlockWithBiometric();
    if (!mounted) return;
    setState(() {
      _biometricBusy = false;
      if (!ok) _biometricError = 'Biometric unlock cancelled or failed';
    });
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.isEmpty) return;
    ref.read(authProvider.notifier).unlockMaster(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final showBiometric = _biometricEnabled && _biometricSupported;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: KeepItAppBar(
        title: 'Unlock vault',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: ref.read(authProvider.notifier).logout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppTheme.heroGreen,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (user != null) ...[
                      Text(
                        'Welcome back, ${user.name.split(' ').first}',
                        style: const TextStyle(
                          color: AppTheme.fg,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                    ] else
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: AppTheme.fg,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (showBiometric) ...[
                AppButton(
                  label: _biometricBusy
                      ? 'Authenticating…'
                      : 'Unlock with biometrics',
                  icon: Icons.fingerprint,
                  variant: AppButtonVariant.accent,
                  isBusy: _biometricBusy,
                  onPressed: _tryBiometric,
                ),
                if (_biometricError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  InlineMessage(
                    message: _biometricError!,
                    kind: InlineMessageKind.error,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.hairline)),
                    const SizedBox(width: 12),
                    Text(
                      'or use password',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Divider(color: AppTheme.hairline)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              TextField(
                controller: _password,
                obscureText: _obscure,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Master password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (auth.errorMessage != null)
                InlineMessage(
                  message: auth.errorMessage!,
                  kind: InlineMessageKind.error,
                ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: auth.isBusy ? 'Unlocking…' : 'Unlock',
                icon: Icons.lock_open_outlined,
                isBusy: auth.isBusy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
