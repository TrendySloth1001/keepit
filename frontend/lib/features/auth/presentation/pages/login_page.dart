import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../auth_notifier.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1080&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.95),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/logo/wallet-passes-app-logo.png',
                        width: 56,
                        height: 56,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const Text(
                    'Welcome to KeepIt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.fg,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your private vault.\nEnd-to-end encrypted on your device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 17,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  if (auth.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ElevatedButton(
                    onPressed: auth.isBusy ? null : notifier.signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.fg,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: auth.isBusy
                        ? const ShimmerBox(
                            width: 24,
                            height: 24,
                            borderRadius: 12,
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, size: 22),
                              SizedBox(width: 12),
                              Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Only your master password unlocks your vault.\nWe never see it or store it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
