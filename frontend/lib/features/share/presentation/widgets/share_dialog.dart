import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../vault/data/vault_models.dart';
import '../share_notifier.dart';

class ShareItemSheet extends ConsumerStatefulWidget {
  const ShareItemSheet({
    super.key,
    required this.title,
    required this.type,
    required this.payload,
  });

  final String title;
  final VaultItemType type;
  final Map<String, dynamic> payload;

  @override
  ConsumerState<ShareItemSheet> createState() => _ShareItemSheetState();
}

class _ShareItemSheetState extends ConsumerState<ShareItemSheet> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _success;
  // null = no expiry. Otherwise number of days.
  int? _expiryDays = 7;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
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
      await ref.read(shareProvider.notifier).shareWithEmail(
            email: email,
            type: widget.type,
            title: widget.title,
            payload: widget.payload,
            expiresInDays: _expiryDays,
          );
      setState(() {
        _busy = false;
        _success = _expiryDays == null
            ? 'Shared with $email — only they can decrypt it.'
            : 'Shared with $email. Auto-revokes in $_expiryDays day${_expiryDays == 1 ? '' : 's'}.';
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Share securely',
                style: TextStyle(
                  color: AppTheme.fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Enter the recipient's email. The item is sealed to their key — "
            'only that account can ever decrypt it, even if someone else gets '
            'the share id.',
            style: TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.4),
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
              _ExpiryChip(
                label: '1 day',
                selected: _expiryDays == 1,
                onTap: () => setState(() => _expiryDays = 1),
              ),
              _ExpiryChip(
                label: '7 days',
                selected: _expiryDays == 7,
                onTap: () => setState(() => _expiryDays = 7),
              ),
              _ExpiryChip(
                label: '30 days',
                selected: _expiryDays == 30,
                onTap: () => setState(() => _expiryDays = 30),
              ),
              _ExpiryChip(
                label: '90 days',
                selected: _expiryDays == 90,
                onTap: () => setState(() => _expiryDays = 90),
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
            label: 'Send sealed share',
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

Future<void> showShareSheet(
  BuildContext context, {
  required String title,
  required VaultItemType type,
  required Map<String, dynamic> payload,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => ShareItemSheet(
      title: title,
      type: type,
      payload: payload,
    ),
  );
}
