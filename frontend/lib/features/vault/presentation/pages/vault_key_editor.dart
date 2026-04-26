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

class VaultKeyEditor extends ConsumerStatefulWidget {
  const VaultKeyEditor({super.key, this.existing});
  final VaultItem? existing;

  @override
  ConsumerState<VaultKeyEditor> createState() => _VaultKeyEditorState();
}

class _VaultKeyEditorState extends ConsumerState<VaultKeyEditor> {
  final _title = TextEditingController();
  final _value = TextEditingController();
  final _kind = TextEditingController();
  final _notes = TextEditingController();
  bool _reveal = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

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
      final decrypted =
          await ref.read(vaultProvider.notifier).decrypt(existing);
      final p = KeyPayload.fromJson(decrypted);
      _title.text = existing.title;
      _value.text = p.value;
      _kind.text = p.kind ?? '';
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
    _value.dispose();
    _kind.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _value.text.isEmpty) {
      setState(() => _error = 'Title and value are required');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(vaultProvider.notifier).saveKey(
        id: widget.existing?.id,
        title: _title.text.trim(),
        payload: KeyPayload(
          value: _value.text,
          kind: _kind.text.isEmpty ? null : _kind.text,
          notes: _notes.text.isEmpty ? null : _notes.text,
        ),
      );
      if (mounted) {
        showAppSnack(context, 'Saved', kind: AppSnackKind.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() {
        _isSaving = false;
        _error = friendlyApiError(e);
      });
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete key?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await ref.read(vaultProvider.notifier).delete(widget.existing!);
    if (mounted) {
      showAppSnack(context, 'Deleted', kind: AppSnackKind.success);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit key' : 'New key'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
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
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _kind,
                      decoration: const InputDecoration(
                        labelText: 'Kind (optional)',
                        helperText: 'e.g. "AWS access key", "GitHub PAT"',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _value,
                      obscureText: !_reveal,
                      maxLines: _reveal ? 4 : 1,
                      decoration: InputDecoration(
                        labelText: 'Value',
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
                              onPressed: () async {
                                if (_value.text.isEmpty) return;
                                await SafeClipboard.copy(_value.text);
                                if (mounted) {
                                  showAppSnack(
                                    context,
                                    'Copied. Clears in 30s.',
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: isEditing ? 'Save changes' : 'Save',
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
