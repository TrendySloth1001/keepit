import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../../data/icon_catalog.dart';
import '../../data/vault_models.dart';
import '../storage_notifier.dart';
import '../vault_notifier.dart';

class VaultUploaderPage extends ConsumerStatefulWidget {
  const VaultUploaderPage({super.key, required this.type});
  final VaultItemType type;

  @override
  ConsumerState<VaultUploaderPage> createState() => _VaultUploaderPageState();
}

/// Hard ceiling enforced server-side too. Keep in sync with backend
/// `MAX_UPLOAD_BYTES` env (defaults to 15 MB, range 10–20 MB).
const int _maxUploadBytes = 15 * 1024 * 1024;

class _PickedAsset {
  _PickedAsset({
    required this.bytes,
    required this.filename,
    required this.mime,
  });
  final Uint8List bytes;
  final String filename;
  final String mime;

  // Per-asset edit state.
  late final TextEditingController title =
      TextEditingController(text: filename);
  String? iconKey;

  // Per-asset upload state. Each is encrypted independently with a fresh IV
  // on its own VaultItem, so failure of one does not block the rest.
  double progress = 0;
  String? status; // null | 'uploading' | 'done' | 'error:<msg>'
}

class _VaultUploaderPageState extends ConsumerState<VaultUploaderPage> {
  final List<_PickedAsset> _assets = [];
  bool _isPicking = false;
  bool _isUploading = false;
  String? _error;

  @override
  void dispose() {
    for (final a in _assets) {
      a.title.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      final picked = <_PickedAsset>[];
      if (widget.type == VaultItemType.image) {
        final picker = ImagePicker();
        final files = await picker.pickMultiImage(imageQuality: 92);
        for (final f in files) {
          final bytes = await f.readAsBytes();
          picked.add(_PickedAsset(
            bytes: bytes,
            filename: f.name,
            mime: f.mimeType ?? 'image/jpeg',
          ));
        }
      } else {
        final result = await FilePicker.pickFiles(
          withData: true,
          allowMultiple: true,
        );
        if (result == null) return;
        for (final f in result.files) {
          if (f.bytes == null) continue;
          picked.add(_PickedAsset(
            bytes: f.bytes!,
            filename: f.name,
            mime: 'application/octet-stream',
          ));
        }
      }

      final tooLarge = picked.where((a) => a.bytes.length > _maxUploadBytes);
      if (tooLarge.isNotEmpty) {
        final limitMb = (_maxUploadBytes / (1024 * 1024)).toStringAsFixed(0);
        setState(() {
          _error =
              '${tooLarge.length} file(s) exceeded the $limitMb MB limit and were skipped.';
        });
      }
      final accepted =
          picked.where((a) => a.bytes.length <= _maxUploadBytes).toList();
      if (!mounted) return;
      setState(() => _assets.addAll(accepted));
    } catch (e) {
      _error = 'Pick failed: ${friendlyApiError(e)}';
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickIconFor(_PickedAsset a) async {
    final fallback =
        a.iconKey ?? IconCatalog.guessFromTitle(a.title.text).key;
    final picked = await context.push<String>(
      '/vault/icon-picker',
      extra: fallback,
    );
    if (picked != null && mounted) setState(() => a.iconKey = picked);
  }

  void _remove(_PickedAsset a) {
    setState(() {
      _assets.remove(a);
      a.title.dispose();
    });
  }

  Future<void> _upload() async {
    if (_assets.isEmpty) {
      setState(() => _error = 'Pick at least one file');
      return;
    }
    final missingTitle = _assets.any((a) => a.title.text.trim().isEmpty);
    if (missingTitle) {
      setState(() => _error = 'Each item needs a title');
      return;
    }
    setState(() {
      _isUploading = true;
      _error = null;
      for (final a in _assets) {
        a.progress = 0;
        a.status = null;
      }
    });

    final notifier = ref.read(vaultProvider.notifier);
    var anyFailure = false;
    // Sequential to keep memory steady and not slam the server with N parallel
    // multipart uploads of large encrypted blobs. Each item is independent.
    for (final a in _assets) {
      if (a.status == 'done') continue;
      setState(() => a.status = 'uploading');
      try {
        final iconKey = a.iconKey == 'generic' ? null : a.iconKey;
        await notifier.uploadFile(
          type: widget.type,
          title: a.title.text.trim(),
          bytes: a.bytes,
          mime: a.mime,
          originalFilename: a.filename,
          iconKey: iconKey,
          onProgress: (p) {
            if (mounted) setState(() => a.progress = p);
          },
        );
        if (mounted) {
          setState(() {
            a.status = 'done';
            a.progress = 1;
          });
        }
      } catch (e) {
        anyFailure = true;
        if (mounted) {
          setState(() => a.status = 'error:${friendlyApiError(e)}');
        }
      }
    }

    await ref.read(storageProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _isUploading = false);
    if (!anyFailure) {
      showAppSnack(
        context,
        'Uploaded ${_assets.length} item${_assets.length == 1 ? '' : 's'}',
        kind: AppSnackKind.success,
      );
      Navigator.of(context).pop();
    } else {
      showAppSnack(
        context,
        'Some uploads failed — review the list',
        kind: AppSnackKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.type == VaultItemType.image;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: KeepItAppBar(
        title: isImage ? 'Upload images' : 'Upload files',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        border: Border.all(color: AppTheme.hairline),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isImage
                                ? Icons.image_outlined
                                : Icons.insert_drive_file_outlined,
                            size: 48,
                            color: AppTheme.muted,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _assets.isEmpty
                                ? 'No ${isImage ? 'images' : 'files'} selected'
                                : '${_assets.length} ${isImage ? 'image' : 'file'}${_assets.length == 1 ? '' : 's'} selected',
                            style: const TextStyle(
                              color: AppTheme.fg,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Each item is encrypted independently on this device.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: _assets.isEmpty
                                ? 'Choose ${isImage ? 'images' : 'files'}'
                                : 'Add more',
                            icon: Icons.folder_open_outlined,
                            variant: AppButtonVariant.secondary,
                            isBusy: _isPicking,
                            onPressed: _pick,
                            fullWidth: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final a in _assets) ...[
                      _AssetCard(
                        asset: a,
                        onRemove: _isUploading ? null : () => _remove(a),
                        onPickIcon:
                            _isUploading ? null : () => _pickIconFor(a),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Text(
                      'Max upload size per item: ${(_maxUploadBytes / (1024 * 1024)).toStringAsFixed(0)} MB.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            if (_assets.isNotEmpty)
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
                  label:
                      'Encrypt and upload ${_assets.length} item${_assets.length == 1 ? '' : 's'}',
                  icon: Icons.lock_outline,
                  variant: AppButtonVariant.accent,
                  isBusy: _isUploading,
                  onPressed: _upload,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.asset,
    required this.onRemove,
    required this.onPickIcon,
  });

  final _PickedAsset asset;
  final VoidCallback? onRemove;
  final VoidCallback? onPickIcon;

  @override
  Widget build(BuildContext context) {
    final iconKey =
        asset.iconKey ?? IconCatalog.guessFromTitle(asset.title.text).key;
    final status = asset.status;
    final isError = status != null && status.startsWith('error:');
    final done = status == 'done';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.hairline),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onPickIcon,
                child: VaultIcon(iconKey: iconKey, size: 44, iconSize: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: asset.title,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatBytes(asset.bytes.length)} · ${asset.mime}',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close, color: AppTheme.muted),
                  onPressed: onRemove,
                ),
            ],
          ),
          if (status == 'uploading') ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: asset.progress,
                color: AppTheme.primary,
                backgroundColor: AppTheme.surfaceAlt,
                minHeight: 4,
              ),
            ),
          ],
          if (done) ...[
            const SizedBox(height: AppSpacing.sm),
            const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: AppTheme.primary, size: 16),
                SizedBox(width: 6),
                Text(
                  'Uploaded',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (isError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              status.substring('error:'.length),
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
