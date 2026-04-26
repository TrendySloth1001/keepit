import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../data/vault_models.dart';
import '../storage_notifier.dart';
import '../vault_notifier.dart';

class VaultUploaderPage extends ConsumerStatefulWidget {
  const VaultUploaderPage({super.key, required this.type});
  final VaultItemType type;

  @override
  ConsumerState<VaultUploaderPage> createState() => _VaultUploaderPageState();
}

class _VaultUploaderPageState extends ConsumerState<VaultUploaderPage> {
  final _title = TextEditingController();
  Uint8List? _bytes;
  String? _filename;
  String? _mime;
  double _progress = 0;
  bool _isPicking = false;
  bool _isUploading = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      if (widget.type == VaultItemType.image) {
        final picker = ImagePicker();
        final file = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 92,
        );
        if (file == null) return;
        final bytes = await file.readAsBytes();
        _bytes = bytes;
        _filename = file.name;
        _mime = file.mimeType ?? 'image/jpeg';
      } else {
        final result = await FilePicker.pickFiles(withData: true);
        if (result == null || result.files.isEmpty) return;
        final f = result.files.first;
        if (f.bytes == null) {
          setState(() => _error = 'Could not read file bytes');
          return;
        }
        _bytes = f.bytes!;
        _filename = f.name;
        _mime = 'application/octet-stream';
      }
      if (_title.text.isEmpty && _filename != null) {
        _title.text = _filename!;
      }
    } catch (e) {
      _error = 'Pick failed: ${friendlyApiError(e)}';
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _upload() async {
    if (_bytes == null || _filename == null) {
      setState(() => _error = 'Pick a file first');
      return;
    }
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }
    setState(() {
      _isUploading = true;
      _error = null;
      _progress = 0;
    });
    try {
      await ref.read(vaultProvider.notifier).uploadFile(
        type: widget.type,
        title: _title.text.trim(),
        bytes: _bytes!,
        mime: _mime!,
        originalFilename: _filename!,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      await ref.read(storageProvider.notifier).refresh();
      if (mounted) {
        showAppSnack(context, 'Uploaded', kind: AppSnackKind.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _error = friendlyApiError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.type == VaultItemType.image;
    return Scaffold(
      appBar: AppBar(
        title: Text(isImage ? 'Upload image' : 'Upload file'),
      ),
      body: SafeArea(
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
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.white),
                  borderRadius: AppRadius.brLg,
                ),
                child: Column(
                  children: [
                    Icon(
                      isImage
                          ? Icons.image_outlined
                          : Icons.insert_drive_file_outlined,
                      size: AppIconSize.huge,
                      color: AppTheme.white,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_filename == null)
                      const Text(
                        'No file selected',
                        style: TextStyle(color: AppTheme.white),
                      )
                    else
                      Column(
                        children: [
                          Text(
                            _filename!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatBytes(_bytes!.length),
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: AppType.micro,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: _filename == null ? 'Choose file' : 'Replace',
                      icon: Icons.folder_open_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: _pick,
                      isBusy: _isPicking,
                      fullWidth: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_isUploading) ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.white),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppButton(
                label: 'Encrypt and upload',
                icon: Icons.lock_outline,
                isBusy: _isUploading,
                onPressed: _upload,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'The file is encrypted on this device before being uploaded. '
                'The server never sees the contents.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.white, fontSize: AppType.micro),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
