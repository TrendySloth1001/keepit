import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../data/vault_models.dart';
import '../vault_notifier.dart';

class VaultNoteEditor extends ConsumerStatefulWidget {
  const VaultNoteEditor({super.key, this.existing});
  final VaultItem? existing;

  @override
  ConsumerState<VaultNoteEditor> createState() => _VaultNoteEditorState();
}

class _VaultNoteEditorState extends ConsumerState<VaultNoteEditor> {
  final _title = TextEditingController();
  final _body = TextEditingController();
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
      final decrypted = await ref
          .read(vaultProvider.notifier)
          .decrypt(existing);
      final p = NotePayload.fromJson(decrypted);
      _title.text = existing.title;
      _body.text = p.body;
    } catch (e) {
      _error = 'Failed to decrypt: ${friendlyApiError(e)}';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
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
      await ref.read(vaultProvider.notifier).saveNote(
            id: widget.existing?.id,
            title: _title.text.trim(),
            payload: NotePayload(body: _body.text),
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
      title: 'Delete note?',
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
      backgroundColor: AppTheme.bg,
      appBar: KeepItAppBar(
        title: isEditing ? 'Edit note' : 'New note',
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
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
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
                          SectionCard(
                            title: 'NOTE',
                            icon: Icons.sticky_note_2_outlined,
                            child: Column(
                              children: [
                                TextField(
                                  controller: _title,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: _body,
                                  maxLines: 14,
                                  minLines: 8,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: const InputDecoration(
                                    labelText: 'Body (encrypted on device)',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: const Border(
                        top: BorderSide(color: AppTheme.hairline),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: AppButton(
                      label: isEditing ? 'Save changes' : 'Save securely',
                      icon: Icons.lock_outline,
                      isBusy: _isSaving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
