import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/crypto/vault_crypto.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../../share/data/share_models.dart';
import '../../../share/presentation/share_notifier.dart';
import '../../../folder/presentation/folder_notifier.dart';
import '../../../folder/presentation/widgets/folder_picker_sheet.dart';
import '../../../share/presentation/widgets/share_dialog.dart';
import '../../data/icon_catalog.dart';
import '../../data/vault_models.dart';
import '../../data/vault_repository.dart';
import '../storage_notifier.dart';
import '../vault_notifier.dart';

class VaultFileViewer extends ConsumerStatefulWidget {
  const VaultFileViewer({super.key, required this.item});
  final VaultItem item;

  @override
  ConsumerState<VaultFileViewer> createState() => _VaultFileViewerState();
}

class _VaultFileViewerState extends ConsumerState<VaultFileViewer> {
  Uint8List? _bytes;
  String? _filename;
  String? _mime;
  String? _iconKey;
  String? _fileIvBase64;
  String? _fileKeyBase64;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  VaultItem _live() {
    return ref
        .read(vaultProvider)
        .items
        .firstWhere((i) => i.id == widget.item.id, orElse: () => widget.item);
  }

  bool _isUnrecoverable = false;

  Future<void> _bootstrap() async {
    try {
      final result =
          await ref.read(vaultProvider.notifier).downloadFile(_live());
      if (!mounted) return;
      setState(() {
        _bytes = result.bytes;
        _filename = result.filename;
        _mime = result.mime;
        _iconKey = result.iconKey;
        _fileIvBase64 = result.fileIvBase64;
        _fileKeyBase64 = result.fileKeyBase64;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        // A MAC mismatch means the body is sealed to a key we no longer have
        // (typically: legacy item that survived a master-password rotation
        // without its body being migrated). The bytes are unrecoverable —
        // surface a delete affordance so the user can clean the row up.
        final raw = e.toString();
        final unrecoverable = raw.contains('SecretBoxAuthenticationError') ||
            raw.contains('wrong message authentication code') ||
            raw.contains('MAC');
        setState(() {
          _isLoading = false;
          _isUnrecoverable = unrecoverable;
          _error = unrecoverable
              ? 'This file cannot be decrypted with your current master '
                  'password. It was likely sealed under a previous password '
                  'and the encrypted body was never migrated. The bytes are '
                  'no longer recoverable — you can remove this entry from '
                  'your vault to free its storage.'
              : 'Failed to decrypt: ${friendlyApiError(e)}';
        });
      }
    }
  }

  /// Writes the decrypted bytes to a temp file and asks the OS to open it
  /// with whichever installed app handles its mime/extension. The file lives
  /// in the app sandbox tmp dir; the OS removes it eventually but we don't
  /// proactively clean up — re-opening should hit the same path.
  Future<void> _openExternally() async {
    if (_bytes == null || _filename == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$_filename';
      final file = File(path);
      await file.writeAsBytes(_bytes!, flush: true);
      final result = await OpenFilex.open(path, type: _mime);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        showAppSnack(
          context,
          result.message.isEmpty
              ? 'No installed app can open this file type.'
              : result.message,
          kind: AppSnackKind.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnack(
        context,
        'Open failed: ${friendlyApiError(e)}',
        kind: AppSnackKind.error,
      );
    }
  }

  Future<void> _saveToDisk() async {
    if (_bytes == null || _filename == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$_filename';
      final file = File(path);
      await file.writeAsBytes(_bytes!);
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

  Future<void> _editDetails() async {
    final live = _live();
    final result = await showModalBottomSheet<_DetailsResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditDetailsSheet(
        initialTitle: live.title,
        initialIconKey:
            _iconKey ?? IconCatalog.guessFromTitle(live.title).key,
      ),
    );
    if (result == null || !mounted) return;
    try {
      await ref.read(vaultProvider.notifier).updateFileMeta(
            item: live,
            title: result.title,
            iconKey: result.iconKey,
          );
      if (!mounted) return;
      setState(() => _iconKey = result.iconKey);
      showAppSnack(context, 'Updated', kind: AppSnackKind.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(
        context,
        'Update failed: ${friendlyApiError(e)}',
        kind: AppSnackKind.error,
      );
    }
  }

  Future<void> _moveToFolder() async {
    final live = _live();
    final picked = await showFolderPickerSheet(
      context,
      currentFolderId: live.folderId,
    );
    if (picked == null || !mounted) return;
    final newFolderId = picked.isEmpty ? null : picked;
    if (newFolderId == live.folderId) return;
    try {
      await ref.read(vaultProvider.notifier).moveToFolder(live, newFolderId);
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

  Future<void> _share() async {
    if (_bytes == null) return;
    final live = _live();

    // Share-by-reference: the encrypted body stays on our storage; we only
    // seal a small payload (filename, mime, per-file DEK + IV) to the
    // recipient so they can pull the body via /shares/:id/content. For
    // legacy items uploaded before per-file DEKs, we migrate the body to a
    // fresh DEK on the fly so we never share a master-bound key.
    var fileKeyB64 = _fileKeyBase64;
    var fileIvB64 = _fileIvBase64;
    if (fileKeyB64 == null) {
      try {
        showAppSnack(context, 'Migrating to per-file key…');
        final fileKey = VaultCrypto.randomBytes(32);
        final reEnc = await VaultCrypto.encrypt(fileKey, _bytes!);
        await VaultRepository.instance.rekeyBody(
          itemId: live.id,
          ciphertext: reEnc.ciphertext,
        );
        fileKeyB64 = base64Encode(fileKey);
        fileIvB64 = base64Encode(reEnc.iv);
        // Persist the new fileKey/fileIv into the item's metadata so future
        // downloads find them. updateFileMeta preserves any pre-existing
        // fileKey, so we have to inject it via a new path.
        await _persistMigratedMeta(
          item: live,
          fileKeyB64: fileKeyB64,
          fileIvB64: fileIvB64,
        );
        if (mounted) {
          setState(() {
            _fileKeyBase64 = fileKeyB64;
            _fileIvBase64 = fileIvB64;
          });
        }
      } catch (e) {
        if (mounted) {
          showAppSnack(
            context,
            'Could not prepare file for sharing: ${friendlyApiError(e)}',
            kind: AppSnackKind.error,
          );
        }
        return;
      }
    }

    if (!mounted) return;
    showShareSheet(
      context,
      title: live.title,
      type: live.type,
      sourceItemId: live.id,
      payload: {
        'filename': _filename ?? live.title,
        'mime': _mime ?? 'application/octet-stream',
        if (_iconKey != null) 'iconKey': _iconKey,
        'fileKey': fileKeyB64,
        'fileIv': fileIvB64,
      },
    );
  }

  /// Writes a migrated (per-file-DEK) metadata blob back to the server so the
  /// item is no longer in legacy format. Mirrors `updateFileMeta` but accepts
  /// a brand-new fileKey/fileIv pair (the existing helper only preserves
  /// what's already there).
  Future<void> _persistMigratedMeta({
    required VaultItem item,
    required String fileKeyB64,
    required String fileIvB64,
  }) async {
    final notifier = ref.read(vaultProvider.notifier);
    final meta = await notifier.readFileMeta(item);
    meta['fileKey'] = fileKeyB64;
    meta['fileIv'] = fileIvB64;
    final repo = VaultRepository.instance;
    final masterKey =
        ref.read(authProvider.notifier).masterKey;
    if (masterKey == null) {
      throw StateError('Vault is locked');
    }
    final encrypted = await VaultCrypto.encryptJson(masterKey, meta);
    await repo.update(
      item.id,
      cipherBlob: encrypted.cipherBlob,
      cipherIv: encrypted.cipherIv,
    );
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete?',
      message:
          'This permanently deletes the encrypted file from your vault and frees up storage.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(vaultProvider.notifier).delete(_live());
      await ref.read(storageProvider.notifier).refresh();
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

  List<Widget> _sharedWithSection(VaultItem live) {
    final sent = ref.watch(shareProvider).sent;
    final shares = sent
        .where((s) => s.type == live.type && s.title == live.title)
        .toList();
    if (shares.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.lg),
      _FileSharedWithCard(shares: shares),
    ];
  }

  Widget _buildPreview() {
    final bytes = _bytes;
    if (bytes == null) return const SizedBox.shrink();
    final mime = _mime ?? '';
    if (mime.startsWith('image/') || widget.item.type == VaultItemType.image) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 360),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.hairline),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.huge),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.hairline),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 60, color: AppTheme.muted),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Preview not supported. Save to disk to open.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = _live();
    final iconKey = _iconKey ?? IconCatalog.guessFromTitle(live.title).key;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: KeepItAppBar(
        title: live.title,
        actions: [
          if (_bytes != null)
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _isLoading
              ? const ShimmerCentered()
              : _error != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InlineMessage(
                          message: _error!,
                          kind: InlineMessageKind.error,
                        ),
                        if (_isUnrecoverable) ...[
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: 'Delete broken item',
                            icon: Icons.delete_outline,
                            variant: AppButtonVariant.accent,
                            onPressed: _delete,
                          ),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPreview(),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            border: Border.all(color: AppTheme.hairline),
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              VaultIcon(
                                iconKey: iconKey,
                                size: 44,
                                iconSize: 22,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _filename ?? 'file',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.fg,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (live.fileSize != null)
                                          formatBytes(live.fileSize!),
                                        formatRelativeTime(live.updatedAt),
                                      ].join(' · '),
                                      style: const TextStyle(
                                        color: AppTheme.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit details',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: _editDetails,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: 'Open',
                          icon: Icons.open_in_new_outlined,
                          variant: AppButtonVariant.accent,
                          onPressed: _openExternally,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Save decrypted copy',
                          icon: Icons.save_outlined,
                          variant: AppButtonVariant.secondary,
                          onPressed: _saveToDisk,
                        ),
                        ..._sharedWithSection(live),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _FileSharedWithCard extends StatelessWidget {
  const _FileSharedWithCard({required this.shares});
  final List<SharedItem> shares;

  @override
  Widget build(BuildContext context) {
    final recipients = shares.map((s) => s.recipientEmail).toSet().toList()
      ..sort();
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

class _DetailsResult {
  const _DetailsResult({required this.title, required this.iconKey});
  final String title;
  final String? iconKey;
}

class _EditDetailsSheet extends StatefulWidget {
  const _EditDetailsSheet({
    required this.initialTitle,
    required this.initialIconKey,
  });
  final String initialTitle;
  final String initialIconKey;

  @override
  State<_EditDetailsSheet> createState() => _EditDetailsSheetState();
}

class _EditDetailsSheetState extends State<_EditDetailsSheet> {
  late final TextEditingController _title;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _iconKey = widget.initialIconKey;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final picked =
        await context.push<String>('/vault/icon-picker', extra: _iconKey);
    if (picked != null && mounted) setState(() => _iconKey = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Edit details',
            style: TextStyle(
              color: AppTheme.fg,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: VaultIcon(iconKey: _iconKey, size: 40, iconSize: 20),
            title: const Text(
              'Icon',
              style: TextStyle(
                color: AppTheme.fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              IconCatalog.resolve(_iconKey).label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppTheme.muted),
            onTap: _pickIcon,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Save',
            icon: Icons.check,
            variant: AppButtonVariant.accent,
            onPressed: () {
              final t = _title.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(
                context,
                _DetailsResult(
                  title: t,
                  iconKey: _iconKey == 'generic' ? null : _iconKey,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
