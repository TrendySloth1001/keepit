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
  final _category = TextEditingController();
  bool _reveal = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _iconKey;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _title.addListener(_maybeAutoIcon);
    _bootstrap();
  }

  void _maybeAutoIcon() {
    if (_iconKey != null) return;
    final guess = IconCatalog.guessFromTitle(_title.text);
    if (guess.key != 'generic') setState(() {});
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
    _username.dispose();
    _password.dispose();
    _url.dispose();
    _notes.dispose();
    _category.dispose();
    super.dispose();
  }

  String get _effectiveIconKey =>
      _iconKey ?? IconCatalog.guessFromTitle(_title.text).key;

  Future<void> _pickIcon() async {
    final picked = await context.push<String>(
      '/vault/icon-picker',
      extra: _effectiveIconKey,
    );
    if (picked != null) setState(() => _iconKey = picked);
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
      await ref.read(vaultProvider.notifier).savePassword(
            id: widget.existing?.id,
            title: _title.text.trim(),
            payload: PasswordPayload(
              username: _username.text,
              password: _password.text,
              url: _url.text.isEmpty ? null : _url.text,
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
      backgroundColor: AppTheme.bg,
      appBar: KeepItAppBar(
        title: _isEditing ? 'Edit password' : 'New password',
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () {
              if (_title.text.trim().isEmpty || _password.text.isEmpty) {
                showAppSnack(
                  context,
                  'Add a title and password before sharing.',
                );
                return;
              }
              showShareSheet(
                context,
                title: _title.text.trim(),
                type: VaultItemType.password,
                payload: PasswordPayload(
                  username: _username.text,
                  password: _password.text,
                  url: _url.text.isEmpty ? null : _url.text,
                  notes: _notes.text.isEmpty ? null : _notes.text,
                  iconKey: _iconKey,
                  category: _category.text.trim().isEmpty
                      ? null
                      : _category.text.trim(),
                ).toJson(),
              );
            },
          ),
          if (_isEditing)
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
                          _IdentityHeader(
                            iconKey: _effectiveIconKey,
                            title: _title.text.isEmpty
                                ? 'New password'
                                : _title.text,
                            subtitle: _username.text.isEmpty
                                ? 'Tap to add details'
                                : _username.text,
                            onPickIcon: _pickIcon,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionCard(
                            title: 'IDENTITY',
                            icon: Icons.label_outline,
                            child: Column(
                              children: [
                                TextField(
                                  controller: _title,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    helperText: 'e.g. "GitHub work account"',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: _category,
                                  decoration: const InputDecoration(
                                    labelText: 'Category (optional)',
                                    hintText: 'Work · Personal · Crypto · …',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionCard(
                            title: 'CREDENTIALS',
                            icon: Icons.key_outlined,
                            child: Column(
                              children: [
                                TextField(
                                  controller: _username,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: 'Username / email',
                                    suffixIcon: _CopyButton(
                                      onTap: () =>
                                          _copy(_username.text, 'Username'),
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
                                          tooltip: _reveal ? 'Hide' : 'Reveal',
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
                                          tooltip: 'Generate',
                                          icon: const Icon(
                                            Icons.auto_awesome_outlined,
                                          ),
                                          onPressed: _generate,
                                        ),
                                        _CopyButton(
                                          onTap: () =>
                                              _copy(_password.text, 'Password'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                PasswordStrengthMeter(password: _password.text),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionCard(
                            title: 'EXTRAS',
                            icon: Icons.notes_outlined,
                            child: Column(
                              children: [
                                TextField(
                                  controller: _url,
                                  keyboardType: TextInputType.url,
                                  decoration: const InputDecoration(
                                    labelText: 'URL',
                                    prefixIcon: Icon(Icons.link),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: _notes,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes',
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
                  _SaveBar(
                    label: _isEditing ? 'Save changes' : 'Save securely',
                    busy: _isSaving,
                    onSave: _save,
                  ),
                ],
              ),
      ),
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({
    required this.iconKey,
    required this.title,
    required this.subtitle,
    required this.onPickIcon,
  });

  final String iconKey;
  final String title;
  final String subtitle;
  final VoidCallback onPickIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.heroGreen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPickIcon,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                VaultIcon(iconKey: iconKey, size: 64, iconSize: 32),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.heroGreen, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onPickIcon,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.palette_outlined, size: 16),
                  label: const Text('Change icon'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Copy',
        icon: const Icon(Icons.copy_outlined),
        onPressed: onTap,
      );
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.label,
    required this.busy,
    required this.onSave,
  });
  final String label;
  final bool busy;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.hairline)),
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
        label: label,
        icon: Icons.lock_outline,
        isBusy: busy,
        onPressed: onSave,
      ),
    );
  }
}
