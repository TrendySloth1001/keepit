import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/utils/clipboard.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../data/vault_models.dart';
import '../vault_notifier.dart';
import '../widgets/password_generator_sheet.dart';
import '../widgets/password_strength_meter.dart';

class VaultPasswordEditor extends ConsumerStatefulWidget {
  const VaultPasswordEditor({super.key, this.existing});
  final VaultItem? existing;

  @override
  ConsumerState<VaultPasswordEditor> createState() =>
      _VaultPasswordEditorState();
}

class _VaultPasswordEditorState extends ConsumerState<VaultPasswordEditor> {
  final _title = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _url = TextEditingController();
  final _notes = TextEditingController();
  bool _reveal = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final existing = widget.existing;
    if (existing == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final decrypted = await ref
          .read(vaultProvider.notifier)
          .decrypt(existing);
      final p = PasswordPayload.fromJson(decrypted);
      _title.text = existing.title;
      _username.text = p.username;
      _password.text = p.password;
      _url.text = p.url ?? '';
      _notes.text = p.notes ?? '';
    } catch (e) {
      _error = 'Failed to decrypt: ${friendlyApiError(e)}';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _url.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref
          .read(vaultProvider.notifier)
          .savePassword(
            id: widget.existing?.id,
            title: _title.text.trim(),
            payload: PasswordPayload(
              username: _username.text,
              password: _password.text,
              url: _url.text.isEmpty ? null : _url.text,
              notes: _notes.text.isEmpty ? null : _notes.text,
            ),
          );
      if (mounted) {
        showAppSnack(context, 'Saved', kind: AppSnackKind.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = friendlyApiError(e);
        });
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete password?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(vaultProvider.notifier).delete(widget.existing!);
      if (mounted) {
        showAppSnack(context, 'Deleted', kind: AppSnackKind.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(
          context,
          'Delete failed: ${friendlyApiError(e)}',
          kind: AppSnackKind.error,
        );
      }
    }
  }

  Future<void> _copy(String text, String label) async {
    if (text.isEmpty) return;
    await SafeClipboard.copy(text);
    if (mounted) showAppSnack(context, '$label copied. Clears in 30s.');
  }

  Future<void> _generate() async {
    final v = await showPasswordGenerator(context);
    if (v != null) setState(() => _password.text = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit password' : 'New password'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const ShimmerCentered()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      InlineMessage(
                        message: _error!,
                        kind: InlineMessageKind.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        helperText: 'e.g. "GitHub work account"',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _username,
                      decoration: InputDecoration(
                        labelText: 'Username / email',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () => _copy(_username.text, 'Username'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _password,
                      obscureText: !_reveal,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _reveal
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _reveal = !_reveal),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_outlined),
                              onPressed: () =>
                                  _copy(_password.text, 'Password'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.casino_outlined),
                              tooltip: 'Generate',
                              onPressed: _generate,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PasswordStrengthMeter(password: _password.text),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _url,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(labelText: 'URL'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _notes,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: _isEditing ? 'Save changes' : 'Save',
                      icon: Icons.lock_outline,
                      isBusy: _isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
