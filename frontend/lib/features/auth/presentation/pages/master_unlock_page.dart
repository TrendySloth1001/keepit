import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../auth_notifier.dart';

class MasterUnlockPage extends ConsumerStatefulWidget {
  const MasterUnlockPage({super.key});

  @override
  ConsumerState<MasterUnlockPage> createState() => _MasterUnlockPageState();
}

class _MasterUnlockPageState extends ConsumerState<MasterUnlockPage> {
  final _password = TextEditingController();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: ref.read(authProvider.notifier).logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                Text(
                  user.name,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: AppTheme.white, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _password,
                obscureText: true,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: 'Master password'),
              ),
              const SizedBox(height: 16),
              if (auth.errorMessage != null)
                Text(
                  auth.errorMessage!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isBusy ? null : _submit,
                child: auth.isBusy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
