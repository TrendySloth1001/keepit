import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/crypto/share_crypto.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../../folder/presentation/widgets/folder_icons.dart';
import '../../../share/data/share_repository.dart';
import '../../../vault/data/vault_models.dart';
import '../../data/collab_folder_models.dart';
import '../../data/collab_folder_repository.dart';
import '../collab_folder_notifier.dart';

class CollabFolderDetailPage extends ConsumerStatefulWidget {
  const CollabFolderDetailPage({super.key, required this.folderId});
  final String folderId;

  @override
  ConsumerState<CollabFolderDetailPage> createState() =>
      _CollabFolderDetailPageState();
}

class _CollabFolderDetailPageState
    extends ConsumerState<CollabFolderDetailPage> {
  final _repo = CollabFolderRepository.instance;
  Uint8List? _myPrivateKey; // sharing private key, unwrapped at first use

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(collabFolderDetailProvider(widget.folderId).notifier)
          .refresh();
    });
  }

  Future<Uint8List> _privateKey() async {
    if (_myPrivateKey != null) return _myPrivateKey!;
    final masterKey = ref.read(authProvider.notifier).masterKey;
    if (masterKey == null) {
      throw StateError('Vault is locked.');
    }
    final stored = await ShareRepository.instance.getKeypair();
    if (!stored.isComplete) {
      throw StateError('Sharing is not set up on this account.');
    }
    final priv = await ShareCrypto.unwrapPrivateKey(
      masterKey: masterKey,
      cipherBase64: stored.privateCipher!,
      ivBase64: stored.privateIv!,
    );
    _myPrivateKey = Uint8List.fromList(priv);
    return _myPrivateKey!;
  }

  String? get _myUserId => ref.read(authProvider).user?.id;

  Future<void> _onAddPassword(CollabFolderDetail detail) async {
    final draft = await showModalBottomSheet<_PasswordDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _PasswordEditorSheet(),
    );
    if (draft == null || !mounted) return;
    await _postNewItem(
      detail: detail,
      type: VaultItemType.password,
      title: draft.title,
      payload: {
        'username': draft.username,
        'password': draft.password,
        'url': draft.url,
        'notes': draft.notes,
      },
    );
  }

  Future<void> _onAddNote(CollabFolderDetail detail) async {
    final draft = await showModalBottomSheet<_NoteDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _NoteEditorSheet(),
    );
    if (draft == null || !mounted) return;
    await _postNewItem(
      detail: detail,
      type: VaultItemType.note,
      title: draft.title,
      payload: {'body': draft.body},
    );
  }

  Future<void> _postNewItem({
    required CollabFolderDetail detail,
    required VaultItemType type,
    required String title,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Build recipients map for every current member.
      final recipients = <String, String>{};
      for (final m in detail.members) {
        if (m.sharingPublicKey != null) {
          recipients[m.userId] = m.sharingPublicKey!;
        }
      }
      if (recipients.isEmpty) {
        throw StateError('No members with published sharing keys yet.');
      }
      final sealed = await CollabCrypto.sealForMembers(
        payload: payload,
        recipients: recipients,
      );
      final memberKeys = [
        for (final entry in sealed.wrappedKeys.entries)
          {'userId': entry.key, 'wrappedKey': entry.value},
      ];
      final created = await _repo.postItem(
        folderId: widget.folderId,
        type: type.name,
        title: title,
        cipherBlob: sealed.cipherBlob,
        cipherIv: sealed.cipherIv,
        memberKeys: memberKeys,
      );
      ref
          .read(collabFolderDetailProvider(widget.folderId).notifier)
          .addItemLocal(created);
      if (!mounted) return;
      showAppSnack(context, 'Added "$title".', kind: AppSnackKind.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
    }
  }

  Future<void> _onInvite(CollabFolderDetail detail) async {
    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _InviteSheet(),
    );
    if (email == null || email.isEmpty || !mounted) return;
    try {
      // 1) Look up recipient pubkey.
      final recipient = await _repo.lookupRecipient(email);
      if (recipient.sharingPublicKey == null) {
        throw StateError(
          'Recipient has not unlocked their vault yet — ask them to sign in first.',
        );
      }
      // 2) Rewrap every existing item's DEK to the new member.
      final priv = await _privateKey();
      final itemKeys = <Map<String, String>>[];
      for (final item in detail.items) {
        final dek = await CollabCrypto.recoverDek(
          myPrivateKey: priv,
          wrappedKeyBase64: item.wrappedKey,
        );
        final rewrapped = await CollabCrypto.wrapDekFor(
          dek: dek,
          recipientPublicKeyBase64: recipient.sharingPublicKey!,
        );
        itemKeys.add({'itemId': item.id, 'wrappedKey': rewrapped});
      }
      // 3) Submit invite with rewrapped keys.
      final member = await _repo.invite(
        folderId: widget.folderId,
        email: email,
        itemKeys: itemKeys,
      );
      ref
          .read(collabFolderDetailProvider(widget.folderId).notifier)
          .addMemberLocal(member);
      if (!mounted) return;
      showAppSnack(context, 'Invited ${recipient.email}',
          kind: AppSnackKind.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
    }
  }

  Future<void> _showItem(CollabItem item) async {
    try {
      final priv = await _privateKey();
      final dek = await CollabCrypto.recoverDek(
        myPrivateKey: priv,
        wrappedKeyBase64: item.wrappedKey,
      );
      final payload = await CollabCrypto.openWithDek(
        dek: dek,
        cipherBlobBase64: item.cipherBlob,
        cipherIvBase64: item.cipherIv,
      );
      // Best-effort activity log.
      _repo.markViewed(widget.folderId, item.id).catchError((_) {});
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) =>
            _ItemViewerSheet(item: item, payload: payload),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
    }
  }

  Future<void> _deleteItem(CollabItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${item.title}"?'),
        content: const Text('This is permanent. Other members will see it disappear.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(ctx).colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repo.deleteItem(widget.folderId, item.id);
      ref
          .read(collabFolderDetailProvider(widget.folderId).notifier)
          .removeItemLocal(item.id);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
    }
  }

  void _showAddSheet(CollabFolderDetail detail) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.password_rounded),
            title: const Text('Password'),
            subtitle: const Text('Share a credential with everyone here.'),
            onTap: () {
              Navigator.pop(ctx);
              _onAddPassword(detail);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: const Text('Note'),
            subtitle: const Text('Plain-text note, end-to-end encrypted.'),
            onTap: () {
              Navigator.pop(ctx);
              _onAddNote(detail);
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collabFolderDetailProvider(widget.folderId));
    final cs = Theme.of(context).colorScheme;
    final detail = state.detail;
    final me = _myUserId;

    return Scaffold(
      floatingActionButton: detail == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddSheet(detail),
              icon: const Icon(Icons.add),
              label: const Text('Add to folder'),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref
              .read(collabFolderDetailProvider(widget.folderId).notifier)
              .refresh(),
          child: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                pinned: true,
                expandedHeight: 130,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FolderGlyph(
                      iconKey: detail?.summary.iconKey ?? 'folder',
                      size: 28,
                      foreground: cs.primary,
                      innerColor: cs.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        detail?.summary.name ?? 'Shared folder',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (detail != null && detail.summary.isOwner)
                    IconButton(
                      tooltip: 'Invite member',
                      icon: const Icon(Icons.person_add_alt_rounded),
                      onPressed: () => _onInvite(detail),
                    ),
                ],
              ),
              if (state.errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: InlineMessage(
                      message: state.errorMessage!,
                      kind: InlineMessageKind.error,
                    ),
                  ),
                ),
              if (state.isLoading && detail == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: ShimmerCentered(),
                )
              else if (detail != null) ...[
                SliverToBoxAdapter(
                  child: _MembersStrip(
                    members: detail.members,
                    canInvite: detail.summary.isOwner,
                    onInvite: () => _onInvite(detail),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      detail.items.isEmpty
                          ? 'No items yet — anyone in this folder can add one.'
                          : '${detail.items.length} item'
                              '${detail.items.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (detail.items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.huge,
                      ),
                      child: EmptyState(
                        icon: Icons.lock_open_outlined,
                        title: 'Folder is empty',
                        message:
                            'Tap "Add to folder" to post the first credential.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverList.separated(
                      itemCount: detail.items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final item = detail.items[i];
                        return _CollabItemTile(
                          item: item,
                          isMine: item.creatorId == me,
                          onTap: () => _showItem(item),
                          onDelete: item.creatorId == me
                              ? () => _deleteItem(item)
                              : null,
                        );
                      },
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _ActivityFeed(activity: detail.activity),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 96),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersStrip extends StatelessWidget {
  const _MembersStrip({
    required this.members,
    required this.canInvite,
    required this.onInvite,
  });

  final List<CollabMember> members;
  final bool canInvite;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: members.length + (canInvite ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, i) {
            if (i < members.length) {
              final m = members[i];
              return Column(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: m.isOwner
                        ? cs.primaryContainer
                        : cs.secondaryContainer,
                    foregroundImage: (m.avatarUrl != null &&
                            m.avatarUrl!.isNotEmpty)
                        ? NetworkImage(m.avatarUrl!)
                        : null,
                    child: Text(
                      _initials(m.name.isNotEmpty ? m.name : m.email),
                      style: TextStyle(
                        color: m.isOwner
                            ? cs.onPrimaryContainer
                            : cs.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      m.name.isEmpty
                          ? m.email.split('@').first
                          : m.name.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                InkWell(
                  onTap: onInvite,
                  borderRadius: BorderRadius.circular(22),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: cs.surfaceContainerHigh,
                    child: Icon(Icons.person_add_alt_rounded,
                        color: cs.primary, size: 22),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Invite',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _CollabItemTile extends StatelessWidget {
  const _CollabItemTile({
    required this.item,
    required this.isMine,
    required this.onTap,
    required this.onDelete,
  });

  final CollabItem item;
  final bool isMine;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(_iconFor(item.type), color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMine
                          ? 'You added this'
                          : 'Added by ${item.creatorName.isEmpty ? "someone" : item.creatorName}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(VaultItemType t) => switch (t) {
        VaultItemType.password => Icons.password_rounded,
        VaultItemType.note => Icons.note_alt_outlined,
        VaultItemType.key => Icons.vpn_key_rounded,
        VaultItemType.file => Icons.description_outlined,
        VaultItemType.image => Icons.image_outlined,
      };
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.activity});
  final List<CollabActivity> activity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (activity.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: cs.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final a in activity.take(50))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(_iconFor(a.action),
                        size: 14, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${a.actorName.isEmpty ? "Someone" : a.actorName} ',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: _verb(a.action)),
                          if (a.detail != null && a.detail!.isNotEmpty)
                            TextSpan(
                              text: ' "${a.detail}"',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          TextSpan(
                            text: '  ·  ${_time(a.createdAt)}',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'created':
        return Icons.create_new_folder_outlined;
      case 'invited':
      case 'joined':
        return Icons.person_add_alt_rounded;
      case 'post_item':
        return Icons.add_circle_outline_rounded;
      case 'edit_item':
        return Icons.edit_outlined;
      case 'delete_item':
        return Icons.delete_outline;
      case 'viewed_item':
        return Icons.visibility_outlined;
      default:
        return Icons.history_rounded;
    }
  }

  String _verb(String action) {
    switch (action) {
      case 'created':
        return 'created the folder';
      case 'invited':
        return 'invited';
      case 'joined':
        return 'joined the folder';
      case 'post_item':
        return 'posted';
      case 'edit_item':
        return 'edited';
      case 'delete_item':
        return 'deleted';
      case 'viewed_item':
        return 'opened';
      case 'removed_member':
        return 'removed';
      default:
        return action;
    }
  }

  String _time(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}

// --- editors / viewer sheets ---

class _PasswordDraft {
  const _PasswordDraft({
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    required this.notes,
  });
  final String title;
  final String username;
  final String password;
  final String url;
  final String notes;
}

class _PasswordEditorSheet extends StatefulWidget {
  const _PasswordEditorSheet();
  @override
  State<_PasswordEditorSheet> createState() => _PasswordEditorSheetState();
}

class _PasswordEditorSheetState extends State<_PasswordEditorSheet> {
  final _title = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _url = TextEditingController();
  final _notes = TextEditingController();
  bool _show = false;

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _url.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final t = _title.text.trim();
    if (t.isEmpty) return;
    Navigator.pop(
      context,
      _PasswordDraft(
        title: t,
        username: _username.text,
        password: _password.text,
        url: _url.text.trim(),
        notes: _notes.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add password',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username / email'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _password,
                obscureText: !_show,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _show = !_show),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _url,
                decoration: const InputDecoration(labelText: 'URL (optional)'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteDraft {
  const _NoteDraft({required this.title, required this.body});
  final String title;
  final String body;
}

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet();
  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add note',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _body,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Body'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final t = _title.text.trim();
                        if (t.isEmpty) return;
                        Navigator.pop(
                          context,
                          _NoteDraft(title: t, body: _body.text),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet();
  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Invite to folder',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'They\'ll be able to see and post items here. The recipient '
                'must have signed in to KeepIt at least once.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _email,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'name@example.com',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final v = _email.text.trim();
                        if (v.isEmpty) return;
                        Navigator.pop(context, v);
                      },
                      child: const Text('Send invite'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemViewerSheet extends StatelessWidget {
  const _ItemViewerSheet({required this.item, required this.payload});
  final CollabItem item;
  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Added by ${item.creatorName.isEmpty ? "a member" : item.creatorName}',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (item.type == VaultItemType.password) ...[
                _Field(label: 'Username', value: payload['username'] ?? ''),
                _Field(
                  label: 'Password',
                  value: payload['password'] ?? '',
                  obscure: true,
                ),
                if ((payload['url'] as String? ?? '').isNotEmpty)
                  _Field(label: 'URL', value: payload['url']),
                if ((payload['notes'] as String? ?? '').isNotEmpty)
                  _Field(label: 'Notes', value: payload['notes'], multiline: true),
              ] else if (item.type == VaultItemType.note) ...[
                Text(
                  payload['body'] as String? ?? '',
                  style: const TextStyle(fontSize: 14, height: 1.45),
                ),
              ] else ...[
                Text(
                  jsonEncode(payload),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.value,
    this.obscure = false,
    this.multiline = false,
  });
  final String label;
  final String value;
  final bool obscure;
  final bool multiline;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shown = widget.obscure && !_show ? '••••••••' : widget.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  shown,
                  maxLines: widget.multiline ? null : 1,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (widget.obscure)
                IconButton(
                  icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _show = !_show),
                ),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}
