import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final result = await ref
          .read(vaultProvider.notifier)
          .downloadFile(widget.item);
      if (!mounted) return;
      setState(() {
        _bytes = result.bytes;
        _filename = result.filename;
        _mime = result.mime;
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
      await ref.read(vaultProvider.notifier).delete(widget.item);
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
          border: Border.all(color: AppTheme.white),
          borderRadius: AppRadius.brLg,
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.white),
        borderRadius: AppRadius.brLg,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: AppIconSize.huge,
            color: AppTheme.white,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Preview not supported. Save to disk to open.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KeepItAppBar(
        title: widget.item.title,
        actions: [
          IconButton(
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
              ? InlineMessage(message: _error!, kind: InlineMessageKind.error)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPreview(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _filename ?? 'file',
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        if (widget.item.fileSize != null)
                          formatBytes(widget.item.fileSize!),
                        formatRelativeTime(widget.item.updatedAt),
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: AppType.micro,
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
