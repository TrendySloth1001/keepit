import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../auth_notifier.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'KeepIt',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your private vault.\nEnd-to-end encrypted.',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: auth.isBusy ? null : notifier.signInWithGoogle,
                icon: auth.isBusy
                    ? const ShimmerBox(width: 18, height: 18, borderRadius: 9)
                    : const Icon(Icons.login),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Only your master password unlocks your vault. We never see it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
