import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../auth_notifier.dart';

class MasterSetupPage extends ConsumerStatefulWidget {
  const MasterSetupPage({super.key});

  @override
  ConsumerState<MasterSetupPage> createState() => _MasterSetupPageState();
}

class _MasterSetupPageState extends ConsumerState<MasterSetupPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final pw = _password.text;
    if (pw.length < 8) {
      setState(() => _localError = 'Use at least 8 characters');
      return;
    }
    if (pw != _confirm.text) {
      setState(() => _localError = 'Passwords do not match');
      return;
    }
    setState(() => _localError = null);
    ref.read(authProvider.notifier).setupMaster(pw);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Set master password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'This password unlocks your vault. It never leaves your device. '
                'If you forget it, your data cannot be recovered.',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Master password'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
              const SizedBox(height: 16),
              if (_localError != null)
                Text(
                  _localError!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isBusy ? null : _submit,
                child: auth.isBusy
                    ? const ShimmerBox(width: 84, height: 18, borderRadius: 9)
                    : const Text('Create vault'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
