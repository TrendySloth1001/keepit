import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/utils/clipboard.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../share/presentation/widgets/share_dialog.dart';
import '../../data/icon_catalog.dart';
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
  final _category = TextEditingController();
  bool _reveal = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _iconKey;

  static const _kindSuggestions = [
    'AWS access key',
    'GCP service account',
    'Azure key',
    'GitHub PAT',
    'GitLab token',
    'OpenAI API key',
    'Anthropic API key',
    'Stripe key',
    'SSH private key',
    'JWT secret',
    'Webhook secret',
  ];

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
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
      final p = KeyPayload.fromJson(decrypted);
      _title.text = existing.title;
      _value.text = p.value;
      _kind.text = p.kind ?? '';
      _notes.text = p.notes ?? '';
      _category.text = p.category ?? '';
      _iconKey = p.iconKey;
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
    _category.dispose();
    super.dispose();
  }

  String get _effectiveIconKey {
    if (_iconKey != null) return _iconKey!;
    final fromTitle = IconCatalog.guessFromTitle(_title.text);
    if (fromTitle.key != 'generic') return fromTitle.key;
    final fromKind = IconCatalog.guessFromTitle(_kind.text);
    if (fromKind.key != 'generic') return fromKind.key;
    return 'api_key';
  }

  Future<void> _pickIcon() async {
    final picked = await context.push<String>(
      '/vault/icon-picker',
      extra: _effectiveIconKey,
    );
    if (picked != null) setState(() => _iconKey = picked);
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
              iconKey: _iconKey,
              category: _category.text.trim().isEmpty
                  ? null
                  : _category.text.trim(),
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
      backgroundColor: AppTheme.bg,
      appBar: KeepItAppBar(
        title: isEditing ? 'Edit key' : 'New key',
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () {
              if (_title.text.trim().isEmpty || _value.text.isEmpty) {
                showAppSnack(
                  context,
                  'Add a title and value before sharing.',
                );
                return;
              }
              showShareSheet(
                context,
                title: _title.text.trim(),
                type: VaultItemType.key,
                payload: KeyPayload(
                  value: _value.text,
                  kind: _kind.text.isEmpty ? null : _kind.text,
                  notes: _notes.text.isEmpty ? null : _notes.text,
                  iconKey: _iconKey,
                  category: _category.text.trim().isEmpty
                      ? null
                      : _category.text.trim(),
                ).toJson(),
              );
            },
          ),
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
                          _IconHeader(
                            iconKey: _effectiveIconKey,
                            onPick: _pickIcon,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionCard(
                            title: 'IDENTITY',
                            icon: Icons.label_outline,
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
                                  controller: _kind,
                                  decoration: const InputDecoration(
                                    labelText: 'Kind',
                                    helperText:
                                        'e.g. "AWS access key", "GitHub PAT"',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final s in _kindSuggestions)
                                      ActionChip(
                                        label: Text(s),
                                        onPressed: () {
                                          setState(() => _kind.text = s);
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: _category,
                                  decoration: const InputDecoration(
                                    labelText: 'Category (optional)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionCard(
                            title: 'SECRET',
                            icon: Icons.key_outlined,
                            child: TextField(
                              controller: _value,
                              obscureText: !_reveal,
                              maxLines: _reveal ? 6 : 1,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Value',
                                alignLabelWithHint: true,
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: AnimatedSwitcher(
                                        duration: AppDurations.short,
                                        child: Icon(
                                          _reveal
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          key: ValueKey(_reveal),
                                        ),
                                      ),
                                      onPressed: () => setState(
                                        () => _reveal = !_reveal,
                                      ),
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
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionCard(
                            title: 'NOTES',
                            icon: Icons.notes_outlined,
                            child: TextField(
                              controller: _notes,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Notes (optional)',
                                alignLabelWithHint: true,
                              ),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
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

class _IconHeader extends StatelessWidget {
  const _IconHeader({required this.iconKey, required this.onPick});
  final String iconKey;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final entry = IconCatalog.resolve(iconKey);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.heroGreen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPick,
            child: VaultIcon(iconKey: iconKey, size: 64, iconSize: 32),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: const TextStyle(
                    color: AppTheme.fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Pick the brand or type that fits this key.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onPick,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.palette_outlined, size: 16),
                  label: const Text('Browse 100+ icons'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
