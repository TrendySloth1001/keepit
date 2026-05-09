import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../folder/data/folder_models.dart';
import '../../../vault/data/vault_models.dart';
import '../../../vault/data/vault_repository.dart';
import '../../../vault/presentation/vault_notifier.dart';
import '../share_notifier.dart';

/// Shares an entire folder with a recipient as a read-only snapshot. Each
/// child item is sealed independently with a fresh per-share DEK, so partial
/// revoke remains possible. File/image children with legacy master-bound
/// bodies are skipped — the sheet tells the user to share those individually.
Future<void> showShareFolderSheet(
  BuildContext context, {
  required VaultFolder folder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _ShareFolderSheet(folder: folder),
  );
}

class _ShareFolderSheet extends ConsumerStatefulWidget {
  const _ShareFolderSheet({required this.folder});
  final VaultFolder folder;

  @override
  ConsumerState<_ShareFolderSheet> createState() => _ShareFolderSheetState();
}

class _ShareFolderSheetState extends ConsumerState<_ShareFolderSheet> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _success;
  int? _expiryDays = 7;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<List<FolderShareEntry>> _gatherEntries({
    required List<VaultItem> items,
    required List<String> skipped,
  }) async {
    final entries = <FolderShareEntry>[];
    final notifier = ref.read(vaultProvider.notifier);
    for (final item in items) {
      switch (item.type) {
        case VaultItemType.password:
        case VaultItemType.note:
        case VaultItemType.key:
          final payload = await notifier.decrypt(item);
          entries.add(FolderShareEntry(
            type: item.type,
            title: item.title,
            payload: payload,
          ));
          break;
        case VaultItemType.file:
        case VaultItemType.image:
          final meta = await notifier.readFileMeta(item);
          final fileKey = meta['fileKey'] as String?;
          final fileIv = meta['fileIv'] as String?;
          if (fileKey == null || fileIv == null) {
            // Legacy item: body is sealed under the master key, not a
            // per-file DEK — sharing it requires a body migration. Skip
            // and tell the user; they can share that one individually
            // (the single-item share path handles the migration on the fly).
            skipped.add(item.title);
            continue;
          }
          entries.add(FolderShareEntry(
            type: item.type,
            title: item.title,
            sourceItemId: item.id,
            payload: {
              'filename': meta['filename'] ?? item.title,
              'mime': meta['mime'] ?? 'application/octet-stream',
              'fileIv': fileIv,
              'fileKey': fileKey,
            },
          ));
          break;
      }
    }
    return entries;
  }

  Future<void> _share() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      // Pull every item that lives in this folder. Use a generous limit so
      // small/medium folders fit in one page; larger folders just need a
      // batch loop (cheap — list is metadata only).
      final all = <VaultItem>[];
      String? cursor;
      while (true) {
        final page = await VaultRepository.instance.list(
          folderId: widget.folder.id,
          cursor: cursor,
          limit: 100,
        );
        all.addAll(page.items);
        if (page.nextCursor == null) break;
        cursor = page.nextCursor;
      }
      if (all.isEmpty) {
        setState(() {
          _busy = false;
          _error = 'This folder is empty — nothing to share.';
        });
        return;
      }
      final skipped = <String>[];
      final entries = await _gatherEntries(items: all, skipped: skipped);
      if (entries.isEmpty) {
        setState(() {
          _busy = false;
          _error = skipped.isEmpty
              ? 'Nothing to share in this folder.'
              : 'All items in this folder are legacy files that need to be '
                  'migrated. Open and share each one individually first.';
        });
        return;
      }
      await ref.read(shareProvider.notifier).shareFolder(
            email: email,
            folderName: widget.folder.name,
            items: entries,
            sourceFolderId: widget.folder.id,
            expiresInDays: _expiryDays,
          );
      var msg = _expiryDays == null
          ? 'Shared "${widget.folder.name}" with $email — '
              '${entries.length} item${entries.length == 1 ? '' : 's'} sealed.'
          : 'Shared "${widget.folder.name}" with $email '
              '(${entries.length} item${entries.length == 1 ? '' : 's'}, '
              'auto-revokes in $_expiryDays day${_expiryDays == 1 ? '' : 's'}).';
      if (skipped.isNotEmpty) {
        msg += '\n\nSkipped legacy items (share individually):\n• '
            '${skipped.join('\n• ')}';
      }
      setState(() {
        _busy = false;
        _success = msg;
        _email.clear();
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = friendlyApiError(e);
      });
    }
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_shared_outlined,
                    color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Share folder · ${widget.folder.name}',
                    style: const TextStyle(
                      color: AppTheme.fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Each item is sealed independently to the recipient. They get '
              'a read-only snapshot — items added to this folder later are not '
              'auto-shared.',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Recipient email',
                prefixIcon: Icon(Icons.alternate_email),
                hintText: 'name@example.com',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'AUTO-REVOKE',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in const [1, 7, 30, 90])
                  _ExpiryChip(
                    label: '$d day${d == 1 ? '' : 's'}',
                    selected: _expiryDays == d,
                    onTap: () => setState(() => _expiryDays = d),
                  ),
                _ExpiryChip(
                  label: 'Never',
                  selected: _expiryDays == null,
                  onTap: () => setState(() => _expiryDays = null),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage(message: _error!, kind: InlineMessageKind.error),
            ],
            if (_success != null) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage(
                message: _success!,
                kind: InlineMessageKind.success,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Share folder',
              icon: Icons.send_outlined,
              isBusy: _busy,
              onPressed: _share,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Close',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  const _ExpiryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary : AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.hairline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

