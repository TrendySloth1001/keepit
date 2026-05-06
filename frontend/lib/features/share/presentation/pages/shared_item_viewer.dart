import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/utils/clipboard.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../vault/data/icon_catalog.dart';
import '../../../vault/data/vault_models.dart';
import '../../data/share_models.dart';
import '../share_notifier.dart';

class SharedItemViewer extends ConsumerStatefulWidget {
  const SharedItemViewer({
    super.key,
    required this.item,
    this.incoming = true,
  });

  final SharedItem item;
  final bool incoming;

  @override
  ConsumerState<SharedItemViewer> createState() => _SharedItemViewerState();
}

class _SharedItemViewerState extends ConsumerState<SharedItemViewer> {
  Map<String, dynamic>? _payload;
  bool _loading = false;
  String? _error;
  bool _reveal = false;

  @override
  void initState() {
    super.initState();
    if (widget.incoming) _open();
  }

  Future<void> _open() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload =
          await ref.read(shareProvider.notifier).openReceived(widget.item);
      if (!mounted) return;
      setState(() {
        _payload = payload;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not open: ${friendlyApiError(e)}';
      });
    }
  }

  Future<void> _copy(String text, String label) async {
    if (text.isEmpty) return;
    await SafeClipboard.copy(text);
    if (mounted) showAppSnack(context, '$label copied. Clears in 30s.');
  }

  Future<void> _revoke() async {
    try {
      await ref.read(shareProvider.notifier).revoke(widget.item);
      if (mounted) {
        showAppSnack(
          context,
          widget.incoming ? 'Removed from inbox' : 'Revoked',
          kind: AppSnackKind.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(
          context,
          friendlyApiError(e),
          kind: AppSnackKind.error,
        );
      }
    }
  }

  Future<void> _saveSharedFile() async {
    final p = _payload;
    if (p == null) return;
    final b64 = p['fileBase64'] as String?;
    if (b64 == null) return;
    try {
      final bytes = base64Decode(b64);
      final filename = p['filename'] as String? ?? widget.item.title;
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$filename';
      await File(path).writeAsBytes(bytes);
      if (mounted) {
        showAppSnack(
          context,
          'Saved decrypted copy: $path',
          kind: AppSnackKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(
          context,
          'Save failed: ${friendlyApiError(e)}',
          kind: AppSnackKind.error,
        );
      }
    }
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
    final item = widget.item;
    final owner = item.ownerName.isEmpty ? item.ownerEmail : item.ownerName;
    final iconKey = (_payload?['iconKey'] as String?) ??
        IconCatalog.guessFromTitle(item.title).key;
    final subtitle = widget.incoming
        ? 'Shared by $owner'
        : 'Shared with ${item.recipientEmail}';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: KeepItAppBar(
        title: _typeLabel(item.type),
        actions: [
          IconButton(
            tooltip: widget.incoming ? 'Remove' : 'Revoke',
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: _revoke,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const ShimmerCentered()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.huge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(
                      iconKey: iconKey,
                      title: item.title,
                      subtitle: subtitle,
                      sharedAt: item.createdAt,
                      canEdit: item.canEdit,
                      expiresAt: item.expiresAt,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_error != null)
                      InlineMessage(
                        message: _error!,
                        kind: InlineMessageKind.error,
                      )
                    else if (!widget.incoming)
                      const InlineMessage(
                        message:
                            'This share is sealed to the recipient. Open the original item in your vault to view details.',
                        kind: InlineMessageKind.info,
                      )
                    else
                      ..._buildBody(item, _payload ?? const {}),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildBody(SharedItem item, Map<String, dynamic> p) {
    switch (item.type) {
      case VaultItemType.password:
        return _passwordBody(PasswordPayload.fromJson(p));
      case VaultItemType.note:
        return _noteBody(NotePayload.fromJson(p));
      case VaultItemType.key:
        return _keyBody(KeyPayload.fromJson(p));
      case VaultItemType.file:
      case VaultItemType.image:
        return _filePayloadBody(item, p);
    }
  }

  List<Widget> _passwordBody(PasswordPayload p) {
    return [
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
              onCopy: () => _copy(p.url!, 'URL'),
            ),
          ],
        ),
      ],
      if ((p.notes ?? '').isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _NotesCard(text: p.notes!),
      ],
    ];
  }

  List<Widget> _noteBody(NotePayload p) {
    return [_NotesCard(text: p.body.isEmpty ? '(empty)' : p.body)];
  }

  List<Widget> _keyBody(KeyPayload p) {
    return [
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
    ];
  }

  List<Widget> _filePayloadBody(SharedItem item, Map<String, dynamic> p) {
    final b64 = p['fileBase64'] as String?;
    final filename = p['filename'] as String? ?? item.title;
    final mime = p['mime'] as String? ?? 'application/octet-stream';
    if (b64 == null) {
      return const [
        InlineMessage(
          message: 'This share has no file payload.',
          kind: InlineMessageKind.warning,
        ),
      ];
    }

    Uint8List? bytes;
    try {
      bytes = base64Decode(b64);
    } catch (_) {
      return const [
        InlineMessage(
          message: 'File payload could not be decoded.',
          kind: InlineMessageKind.error,
        ),
      ];
    }

    final isImage =
        item.type == VaultItemType.image || mime.startsWith('image/');
    return [
      if (isImage)
        Container(
          constraints: const BoxConstraints(maxHeight: 360),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.hairline),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.memory(bytes, fit: BoxFit.contain),
        )
      else
        Container(
          padding: const EdgeInsets.all(AppSpacing.huge),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.hairline),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 60,
                color: AppTheme.muted,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Save to disk to open this file.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted),
              ),
            ],
          ),
        ),
      const SizedBox(height: AppSpacing.md),
      _FieldCard(
        children: [
          _ReadField(label: 'Filename', value: filename),
          const _Divider(),
          _ReadField(label: 'Size', value: formatBytes(bytes.length)),
          const _Divider(),
          _ReadField(label: 'Type', value: mime),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        label: 'Save decrypted copy',
        icon: Icons.save_outlined,
        variant: AppButtonVariant.accent,
        onPressed: _saveSharedFile,
      ),
    ];
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.iconKey,
    required this.title,
    required this.subtitle,
    required this.sharedAt,
    required this.canEdit,
    required this.expiresAt,
  });

  final String iconKey;
  final String title;
  final String subtitle;
  final DateTime sharedAt;
  final bool canEdit;
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final expired =
        expiresAt != null && DateTime.now().isAfter(expiresAt!);
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetaChip(label: 'Shared ${formatRelativeTime(sharedAt)}'),
                    _MetaChip(label: canEdit ? 'Can edit' : 'View only'),
                    if (expiresAt != null)
                      _MetaChip(
                        icon: Icons.timer_outlined,
                        label: expired
                            ? 'Expired'
                            : 'Revokes in ${formatCountdown(expiresAt!)}',
                        tone: expired
                            ? _MetaTone.danger
                            : _MetaTone.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _MetaTone { neutral, warning, danger }

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.icon,
    this.tone = _MetaTone.neutral,
  });
  final String label;
  final IconData? icon;
  final _MetaTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _MetaTone.warning => (bg: Colors.white, fg: AppTheme.warning),
      _MetaTone.danger => (bg: Colors.white, fg: AppTheme.error),
      _ => (bg: Colors.white, fg: AppTheme.primaryDark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: colors.fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
  });
  final String label;
  final String value;
  final bool isSecret;
  final bool revealed;
  final VoidCallback? onToggleReveal;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final shown = isSecret && !revealed
        ? '•' * (value.isEmpty ? 0 : value.length.clamp(6, 16))
        : (value.isEmpty ? '—' : value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
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
                    fontWeight: FontWeight.w600,
                    fontFamily:
                        (isSecret && revealed) ? 'monospace' : null,
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
