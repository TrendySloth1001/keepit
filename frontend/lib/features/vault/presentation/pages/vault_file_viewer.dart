import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../share/presentation/widgets/share_dialog.dart';
import '../../data/icon_catalog.dart';
import '../../data/vault_models.dart';
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
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to decrypt: ${friendlyApiError(e)}';
        });
      }
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

  void _share() {
    if (_bytes == null) return;
    final live = _live();
    // For file/image we inline the bytes (base64) into the share payload so
    // the recipient never has to call our storage API. The express body cap
    // is 24mb, which fits an encrypted file up to ~16MB.
    showShareSheet(
      context,
      title: live.title,
      type: live.type,
      payload: {
        'filename': _filename ?? live.title,
        'mime': _mime ?? 'application/octet-stream',
        if (_iconKey != null) 'iconKey': _iconKey,
        'fileBase64': base64Encode(_bytes!),
      },
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
                  ? InlineMessage(
                      message: _error!,
                      kind: InlineMessageKind.error,
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
                          label: 'Save decrypted copy',
                          icon: Icons.save_outlined,
                          variant: AppButtonVariant.secondary,
                          onPressed: _saveToDisk,
                        ),
                      ],
                    ),
        ),
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
