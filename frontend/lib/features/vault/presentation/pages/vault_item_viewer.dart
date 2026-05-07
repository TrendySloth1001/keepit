import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/utils/clipboard.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../folder/presentation/folder_notifier.dart';
import '../../../folder/presentation/widgets/folder_picker_sheet.dart';
import '../../../share/data/share_models.dart';
import '../../../share/presentation/share_notifier.dart';
import '../../../share/presentation/widgets/share_dialog.dart';
import '../../data/icon_catalog.dart';
import '../../data/vault_models.dart';
import '../vault_notifier.dart';

class VaultItemViewer extends ConsumerStatefulWidget {
  const VaultItemViewer({super.key, required this.item});
  final VaultItem item;

  @override
  ConsumerState<VaultItemViewer> createState() => _VaultItemViewerState();
}

class _VaultItemViewerState extends ConsumerState<VaultItemViewer> {
  Map<String, dynamic>? _decrypted;
  bool _loading = true;
  String? _error;
  bool _reveal = false;
  final Set<int> _extraRevealed = {};

  @override
  void initState() {
    super.initState();
    _decryptLatest();
  }

  Future<void> _decryptLatest() async {
    try {
      // Re-fetch from the live vault list when possible, so edits made in
      // the editor and popped back are visible without requiring a refresh.
      final fresh = ref
          .read(vaultProvider)
          .items
          .firstWhere((i) => i.id == widget.item.id, orElse: () => widget.item);
      final payload = await ref.read(vaultProvider.notifier).decrypt(fresh);
      if (!mounted) return;
      setState(() {
        _decrypted = payload;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to decrypt: ${friendlyApiError(e)}';
        _loading = false;
      });
    }
  }

  VaultItem _liveItem() {
    return ref
        .read(vaultProvider)
        .items
        .firstWhere((i) => i.id == widget.item.id, orElse: () => widget.item);
  }

  Future<void> _edit() async {
    final live = _liveItem();
    final route = switch (live.type) {
      VaultItemType.password => '/vault/edit/password',
      VaultItemType.note => '/vault/edit/note',
      VaultItemType.key => '/vault/edit/key',
      _ => null,
    };
    if (route == null) return;
    await context.push(route, extra: live);
    if (!mounted) return;
    setState(() => _loading = true);
    await _decryptLatest();
  }

  Future<void> _delete() async {
    final live = _liveItem();
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${_typeLabel(live.type).toLowerCase()}?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(vaultProvider.notifier).delete(live);
      if (!mounted) return;
      showAppSnack(context, 'Deleted', kind: AppSnackKind.success);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      showAppSnack(
        context,
        'Delete failed: ${friendlyApiError(e)}',
        kind: AppSnackKind.error,
      );
    }
  }

  void _share() {
    if (_decrypted == null) return;
    final live = _liveItem();
    showShareSheet(
      context,
      title: live.title,
      type: live.type,
      payload: _decrypted!,
    );
  }

  Future<void> _moveToFolder() async {
    final live = _liveItem();
    final picked = await showFolderPickerSheet(
      context,
      currentFolderId: live.folderId,
    );
    if (picked == null || !mounted) return;
    final newFolderId = picked.isEmpty ? null : picked;
    if (newFolderId == live.folderId) return;
    try {
      await ref.read(vaultProvider.notifier).moveToFolder(live, newFolderId);
      // Keep folder counts honest in the chip strip without a roundtrip.
      ref.read(folderProvider.notifier).bumpItemCount(live.folderId, -1);
      ref.read(folderProvider.notifier).bumpItemCount(newFolderId, 1);
      if (!mounted) return;
      showAppSnack(context, 'Moved', kind: AppSnackKind.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(
        context,
        'Move failed: ${friendlyApiError(e)}',
        kind: AppSnackKind.error,
      );
    }
  }

  Future<void> _copy(String text, String label) async {
    if (text.isEmpty) return;
    await SafeClipboard.copy(text);
    if (mounted) showAppSnack(context, '$label copied. Clears in 30s.');
  }

  String _typeLabel(VaultItemType t) => switch (t) {
    VaultItemType.password => 'Password',
    VaultItemType.note => 'Note',
    VaultItemType.key => 'Key',
    VaultItemType.file => 'File',
    VaultItemType.image => 'Image',
  };

  @override
  Widget build(BuildContext context) {
    final live = _liveItem();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: KeepItAppBar(
        title: _typeLabel(live.type),
        actions: [
          if (!_loading && _decrypted != null && _error == null)
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: _share,
            ),
          IconButton(
            tooltip: 'Move to folder',
            icon: const Icon(Icons.drive_file_move_outlined),
            onPressed: _moveToFolder,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
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
                          ] else
                            ..._buildBody(live),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                  _EditBar(onEdit: _edit),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildBody(VaultItem live) {
    final payload = _decrypted ?? const <String, dynamic>{};
    switch (live.type) {
      case VaultItemType.password:
        return _passwordBody(live, PasswordPayload.fromJson(payload));
      case VaultItemType.note:
        return _noteBody(live, NotePayload.fromJson(payload));
      case VaultItemType.key:
        return _keyBody(live, KeyPayload.fromJson(payload));
      case VaultItemType.file:
      case VaultItemType.image:
        // The viewer is only wired up for password/note/key; files are still
        // routed to vault_file_viewer directly.
        return const [SizedBox.shrink()];
    }
  }

  List<Widget> _passwordBody(VaultItem live, PasswordPayload p) {
    final iconKey = p.iconKey ?? IconCatalog.guessFromTitle(live.title).key;
    final shared = _sentSharesFor(live);
    return [
      _Hero(
        iconKey: iconKey,
        title: live.title,
        subtitle: p.username.isEmpty ? 'No username' : p.username,
        category: p.category,
      ),
      const SizedBox(height: AppSpacing.lg),
      _FieldCard(
        children: [
          _ReadField(
            label: 'Username',
            value: p.username,
            onCopy: () => _copy(p.username, 'Username'),
          ),
          const _Divider(),
          _ReadField(
            label: 'Password',
            value: p.password,
            isSecret: true,
            revealed: _reveal,
            onToggleReveal: () => setState(() => _reveal = !_reveal),
            onCopy: () => _copy(p.password, 'Password'),
          ),
        ],
      ),
      if ((p.url ?? '').isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _FieldCard(
          children: [
            _ReadField(
              label: 'Website',
              value: p.url!,
              monospace: false,
              onCopy: () => _copy(p.url!, 'URL'),
            ),
          ],
        ),
      ],
      if ((p.notes ?? '').isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _NotesCard(text: p.notes!),
      ],
      if (p.extras.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _FieldCard(
          children: [
            for (var i = 0; i < p.extras.length; i++) ...[
              _ReadField(
                label: _extraLabel(p.extras[i]),
                value: p.extras[i].value,
                isSecret: p.extras[i].kind.isSecret,
                revealed: _extraRevealed.contains(i),
                onToggleReveal: p.extras[i].kind.isSecret
                    ? () => setState(() {
                        if (_extraRevealed.contains(i)) {
                          _extraRevealed.remove(i);
                        } else {
                          _extraRevealed.add(i);
                        }
                      })
                    : null,
                onCopy: () => _copy(p.extras[i].value, p.extras[i].kind.label),
                monospace: p.extras[i].kind.isSecret,
              ),
              if (i != p.extras.length - 1) const _Divider(),
            ],
          ],
        ),
      ],
      if (shared.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _SharedWithCard(shares: shared),
      ],
      const SizedBox(height: AppSpacing.md),
      _MetaRow(item: live),
    ];
  }

  List<Widget> _noteBody(VaultItem live, NotePayload p) {
    final iconKey = p.iconKey ?? IconCatalog.guessFromTitle(live.title).key;
    final shared = _sentSharesFor(live);
    return [
      _Hero(
        iconKey: iconKey,
        title: live.title,
        subtitle: 'Encrypted note',
        category: null,
      ),
      const SizedBox(height: AppSpacing.lg),
      _NotesCard(text: p.body.isEmpty ? '(empty)' : p.body),
      if (shared.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _SharedWithCard(shares: shared),
      ],
      const SizedBox(height: AppSpacing.md),
      _MetaRow(item: live),
    ];
  }

  List<Widget> _keyBody(VaultItem live, KeyPayload p) {
    final iconKey =
        p.iconKey ??
        () {
          final fromTitle = IconCatalog.guessFromTitle(live.title);
          if (fromTitle.key != 'generic') return fromTitle.key;
          return 'api_key';
        }();
    final shared = _sentSharesFor(live);
    return [
      _Hero(
        iconKey: iconKey,
        title: live.title,
        subtitle: (p.kind ?? '').isEmpty ? 'API key / token' : p.kind!,
        category: p.category,
      ),
      const SizedBox(height: AppSpacing.lg),
      _FieldCard(
        children: [
          _ReadField(
            label: 'Value',
            value: p.value,
            isSecret: true,
            revealed: _reveal,
            onToggleReveal: () => setState(() => _reveal = !_reveal),
            onCopy: () => _copy(p.value, 'Key'),
          ),
        ],
      ),
      if ((p.notes ?? '').isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _NotesCard(text: p.notes!),
      ],
      if (shared.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _SharedWithCard(shares: shared),
      ],
      const SizedBox(height: AppSpacing.md),
      _MetaRow(item: live),
    ];
  }

  String _extraLabel(PasswordExtraField field) {
    final base = field.label.isEmpty ? field.kind.label : field.label;
    return field.label.isEmpty ? base : '$base · ${field.kind.label}';
  }

  List<SharedItem> _sentSharesFor(VaultItem live) {
    final sent = ref.watch(shareProvider).sent;
    return sent
        .where((s) => s.type == live.type && s.title == live.title)
        .toList();
  }
}

class _SharedWithCard extends StatelessWidget {
  const _SharedWithCard({required this.shares});
  final List<SharedItem> shares;

  @override
  Widget build(BuildContext context) {
    final recipients = shares.map((s) => s.recipientEmail).toSet().toList();
    recipients.sort();
    final lastShared = shares
        .map((s) => s.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.share_outlined, size: 16, color: AppTheme.muted),
              const SizedBox(width: 6),
              const Text(
                'SHARED WITH',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                'Last shared ${formatRelativeTime(lastShared)}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final email in recipients)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppTheme.hairline),
                  ),
                  child: Text(
                    email,
                    style: const TextStyle(
                      color: AppTheme.fg,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.iconKey,
    required this.title,
    required this.subtitle,
    required this.category,
  });
  final String iconKey;
  final String title;
  final String subtitle;
  final String? category;

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
          VaultIcon(iconKey: iconKey, size: 64, iconSize: 32),
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
                if ((category ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Comma-separated tokens render as individual pills so users
                  // can tag with multiple keywords ("work, key, private") and
                  // still scan them at a glance.
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final token in category!
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: AppTheme.hairline),
                          ),
                          child: Text(
                            token,
                            style: const TextStyle(
                              color: AppTheme.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppTheme.hairline, height: 1);
}

class _ReadField extends StatelessWidget {
  const _ReadField({
    required this.label,
    required this.value,
    this.isSecret = false,
    this.revealed = false,
    this.onToggleReveal,
    this.onCopy,
    this.monospace = false,
  });
  final String label;
  final String value;
  final bool isSecret;
  final bool revealed;
  final VoidCallback? onToggleReveal;
  final VoidCallback? onCopy;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final shown = isSecret && !revealed
        ? '•' * (value.isEmpty ? 0 : value.length.clamp(6, 16))
        : (value.isEmpty ? '—' : value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  shown,
                  style: TextStyle(
                    color: AppTheme.fg,
                    fontSize: 15,
                    fontFamily: (isSecret && revealed) || monospace
                        ? 'monospace'
                        : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isSecret)
            IconButton(
              tooltip: revealed ? 'Hide' : 'Reveal',
              icon: Icon(
                revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: onToggleReveal,
            ),
          if (onCopy != null)
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_outlined),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTES',
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            text,
            style: const TextStyle(
              color: AppTheme.fg,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.item});
  final VaultItem item;
  @override
  Widget build(BuildContext context) {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Expanded(
          child: _MetaCell(label: 'Created', value: fmt(item.createdAt)),
        ),
        Expanded(
          child: _MetaCell(label: 'Updated', value: fmt(item.updatedAt)),
        ),
      ],
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.fg,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EditBar extends StatelessWidget {
  const _EditBar({required this.onEdit});
  final VoidCallback onEdit;
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
        label: 'Edit',
        icon: Icons.edit_outlined,
        variant: AppButtonVariant.accent,
        onPressed: onEdit,
      ),
    );
  }
}
