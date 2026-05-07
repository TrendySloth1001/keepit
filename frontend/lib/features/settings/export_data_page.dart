import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../shared/network/api_error.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/inline_message.dart';
import '../../shared/widgets/keepit_app_bar.dart';
import '../auth/presentation/auth_notifier.dart';
import '../vault/data/vault_models.dart';
import '../vault/presentation/vault_notifier.dart';

class ExportDataPage extends ConsumerStatefulWidget {
  const ExportDataPage({super.key});

  @override
  ConsumerState<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends ConsumerState<ExportDataPage> {
  bool _busy = false;
  String? _error;
  int _decryptedCount = 0;

  Future<void> _export({required bool includeFiles}) async {
    final accepted = await _confirmExport(includeFiles: includeFiles);
    if (!accepted) return;
    setState(() {
      _busy = true;
      _error = null;
      _decryptedCount = 0;
    });
    try {
      final notifier = ref.read(vaultProvider.notifier);
      // Make sure we have the latest list before exporting.
      await notifier.refresh();
      // Walk all pages.
      while (ref.read(vaultProvider).hasMore) {
        await notifier.loadMore();
      }

      final items = ref.read(vaultProvider).items;
      final entries = <Map<String, dynamic>>[];

      for (final item in items) {
        if (!includeFiles &&
            (item.type == VaultItemType.file ||
                item.type == VaultItemType.image)) {
          continue;
        }
        final payload = await notifier.decrypt(item);
        entries.add({
          'id': item.id,
          'type': item.type.name,
          'title': item.title,
          'createdAt': item.createdAt.toIso8601String(),
          'updatedAt': item.updatedAt.toIso8601String(),
          'payload': payload,
        });
        if (mounted) {
          setState(() => _decryptedCount = entries.length);
        }
      }

      final user = ref.read(authProvider).user;
      final doc = <String, dynamic>{
        'app': 'keepit',
        'exportedAt': DateTime.now().toIso8601String(),
        'account': {'id': user?.id, 'email': user?.email, 'name': user?.name},
        'count': entries.length,
        'items': entries,
      };

      final bytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(doc),
      );
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/keepit-export-$stamp.json');
      await file.writeAsBytes(bytes);

      // Trigger the OS share sheet so the user can save it anywhere.
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'KeepIt vault export',
        text: 'Decrypted KeepIt vault export. Treat this file as sensitive.',
      );

      if (!mounted) return;
      setState(() => _busy = false);
      showAppSnack(
        context,
        'Exported ${entries.length} items',
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = friendlyApiError(e);
      });
    }
  }

  Future<bool> _confirmExport({required bool includeFiles}) async {
    var accepted = false;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: AppSpacing.lg + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You are exporting decrypted data',
                        style: TextStyle(
                          color: AppTheme.fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'The file you are about to generate contains your '
                  'passwords, notes and keys in plaintext. Once it leaves '
                  'KeepIt, its safety is entirely up to you.',
                  style: TextStyle(
                    color: AppTheme.fg,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'By continuing you agree that:',
                  style: TextStyle(
                    color: AppTheme.fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const _BulletLine(
                  'You are solely responsible for storing and deleting this file.',
                ),
                const _BulletLine(
                  'KeepIt cannot recover or revoke it once it is shared or saved off-device.',
                ),
                const _BulletLine(
                  'Anyone who gets the file can read your secrets without your master password.',
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: () => setLocal(() => accepted = !accepted),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: accepted,
                          onChanged: (v) =>
                              setLocal(() => accepted = v ?? false),
                          activeColor: AppTheme.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'I understand and accept responsibility for this exported file.',
                              style: TextStyle(
                                color: AppTheme.fg,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        disabledBackgroundColor: AppTheme.surfaceAlt,
                      ),
                      onPressed: accepted
                          ? () => Navigator.pop(ctx, true)
                          : null,
                      child: Text(
                        includeFiles ? 'Export everything' : 'Export now',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: const KeepItAppBar(title: 'Export Data'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.heroGreen,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.download_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Decrypted JSON export',
                          style: TextStyle(
                            color: AppTheme.fg,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Generated on this device — vault key never leaves.',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              InlineMessage(message: _error!, kind: InlineMessageKind.error),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_busy) ...[
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Decrypting… $_decryptedCount items',
                    style: const TextStyle(
                      color: AppTheme.fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppButton(
              label: 'Export passwords, notes, keys',
              icon: Icons.text_snippet_outlined,
              variant: AppButtonVariant.accent,
              isBusy: _busy,
              onPressed: _busy ? null : () => _export(includeFiles: false),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Export everything (metadata only)',
              icon: Icons.folder_open_outlined,
              variant: AppButtonVariant.secondary,
              isBusy: _busy,
              onPressed: _busy ? null : () => _export(includeFiles: true),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'File and image bytes are not included in the export — only their titles and metadata. Download files individually from the vault.',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 5, color: AppTheme.muted),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.fg,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
