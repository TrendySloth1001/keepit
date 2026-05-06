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
  final List<_ExtraFieldController> _extras = [];
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
      for (final f in p.extras) {
        _extras.add(_ExtraFieldController.fromField(f));
      }
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
    for (final extra in _extras) {
      extra.dispose();
    }
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
    final extras = _extras
        .map(
          (f) => PasswordExtraField(
            label: f.label.text.trim(),
            value: f.value.text,
            kind: f.kind,
          ),
        )
        .where((f) => f.label.isNotEmpty || f.value.isNotEmpty)
        .toList();
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
              iconKey: _iconKey,
              category: _category.text.trim().isEmpty
                  ? null
                  : _category.text.trim(),
              extras: extras,
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

  void _addExtra(ExtraFieldKind kind) {
    setState(() => _extras.add(_ExtraFieldController(kind: kind)));
  }

  void _removeExtra(int index) {
    final removed = _extras.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _openAddFieldSheet() async {
    final kind = await showModalBottomSheet<ExtraFieldKind>(
      context: context,
      isScrollControlled: false,
      builder: (_) => const _AddFieldSheet(),
    );
    if (kind != null) _addExtra(kind);
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
                  extras: _extras
                      .map(
                        (f) => PasswordExtraField(
                          label: f.label.text.trim(),
                          value: f.value.text,
                          kind: f.kind,
                        ),
                      )
                      .where((f) => f.label.isNotEmpty || f.value.isNotEmpty)
                      .toList(),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.key_outlined,
                                      size: 16,
                                      color: AppTheme.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'CREDENTIALS',
                                      style: TextStyle(
                                        color: AppTheme.muted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: _openAddFieldSheet,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
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
                                                  ? Icons
                                                        .visibility_off_outlined
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
                                if (_extras.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  const Text(
                                    'CUSTOM FIELDS',
                                    style: TextStyle(
                                      color: AppTheme.muted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  for (var i = 0; i < _extras.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: _ExtraFieldCard(
                                        field: _extras[i],
                                        onRemove: () => _removeExtra(i),
                                        onChanged: () => setState(() {}),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionCard(
                            title: 'DETAILS',
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

class _ExtraFieldController {
  _ExtraFieldController({required this.kind, String? label, String? value})
    : label = TextEditingController(text: label ?? ''),
      value = TextEditingController(text: value ?? '');

  factory _ExtraFieldController.fromField(PasswordExtraField field) =>
      _ExtraFieldController(
        kind: field.kind,
        label: field.label,
        value: field.value,
      );

  final TextEditingController label;
  final TextEditingController value;
  ExtraFieldKind kind;
  bool reveal = false;

  void dispose() {
    label.dispose();
    value.dispose();
  }
}

class _AddFieldSheet extends StatelessWidget {
  const _AddFieldSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add field',
              style: TextStyle(
                color: AppTheme.fg,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Choose what to add to credentials.',
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AddFieldTile(
              kind: ExtraFieldKind.text,
              description: 'Additional text detail',
            ),
            _AddFieldTile(
              kind: ExtraFieldKind.password,
              description: 'Secondary password',
            ),
            _AddFieldTile(
              kind: ExtraFieldKind.note,
              description: 'Secure note field',
            ),
            _AddFieldTile(
              kind: ExtraFieldKind.key,
              description: 'API key or token',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFieldTile extends StatelessWidget {
  const _AddFieldTile({required this.kind, required this.description});
  final ExtraFieldKind kind;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
      title: Text(
        kind.label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(color: AppTheme.muted),
      ),
      onTap: () => Navigator.pop(context, kind),
    );
  }
}

class _ExtraFieldCard extends StatefulWidget {
  const _ExtraFieldCard({
    required this.field,
    required this.onRemove,
    required this.onChanged,
  });

  final _ExtraFieldController field;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_ExtraFieldCard> createState() => _ExtraFieldCardState();
}

class _ExtraFieldCardState extends State<_ExtraFieldCard> {
  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final isSecret = field.kind.isSecret;
    final isMultiline = field.kind.isMultiline;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ExtraFieldKind>(
                  value: field.kind,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ExtraFieldKind.values
                      .map(
                        (k) => DropdownMenuItem(value: k, child: Text(k.label)),
                      )
                      .toList(),
                  onChanged: (k) {
                    if (k == null) return;
                    setState(() => field.kind = k);
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close, size: 18),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: field.label,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'e.g. Backup code, UPI PIN',
            ),
            onChanged: (_) => widget.onChanged(),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: field.value,
            maxLines: isMultiline ? 4 : 1,
            obscureText: isSecret && !field.reveal,
            decoration: InputDecoration(
              labelText: 'Value',
              alignLabelWithHint: isMultiline,
              suffixIcon: isSecret
                  ? IconButton(
                      tooltip: field.reveal ? 'Hide' : 'Reveal',
                      icon: Icon(
                        field.reveal
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => field.reveal = !field.reveal);
                        widget.onChanged();
                      },
                    )
                  : null,
            ),
            onChanged: (_) => widget.onChanged(),
          ),
        ],
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
