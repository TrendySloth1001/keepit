import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../shared/crypto/share_crypto.dart';
import '../../shared/crypto/vault_crypto.dart';
import '../../shared/network/api_error.dart';
import '../../shared/storage/settings_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/inline_message.dart';
import '../../shared/widgets/keepit_app_bar.dart';
import '../../shared/widgets/section_card.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/auth_notifier.dart';
import '../share/data/share_repository.dart';
import '../vault/data/vault_repository.dart';

class ChangeMasterPasswordPage extends ConsumerStatefulWidget {
  const ChangeMasterPasswordPage({super.key});

  @override
  ConsumerState<ChangeMasterPasswordPage> createState() =>
      _ChangeMasterPasswordPageState();
}

class _ChangeMasterPasswordPageState
    extends ConsumerState<ChangeMasterPasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _status;
  double _progress = 0;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _rotate() async {
    final user = ref.read(authProvider).user;
    if (user == null || user.masterSalt == null) {
      setState(() => _error = 'Account not ready');
      return;
    }
    final cur = _current.text;
    final next = _next.text;
    final conf = _confirm.text;
    if (cur.isEmpty || next.isEmpty) {
      setState(() => _error = 'Fill in all fields');
      return;
    }
    if (next.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters');
      return;
    }
    if (next != conf) {
      setState(() => _error = 'New passwords do not match');
      return;
    }
    if (next == cur) {
      setState(() => _error = 'Pick a password different from the current one');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _status = 'Verifying current password…';
      _progress = 0;
    });

    try {
      // 1) Re-derive the OLD key for verification + decryption.
      final oldSalt = base64Decode(user.masterSalt!);
      final oldParams = user.masterParams ?? KdfParams.defaults;
      final oldDerived = await VaultCrypto.deriveMaster(
        password: cur,
        salt: oldSalt,
        params: oldParams,
      );

      // Cross-check against the in-memory key when available — this avoids
      // a server round-trip and rejects typos before we touch any items.
      final memoryKey = ref.read(authProvider.notifier).masterKey;
      if (memoryKey != null &&
          !_constantTimeEq(oldDerived.key, memoryKey)) {
        setState(() {
          _busy = false;
          _error = 'Current password is incorrect';
        });
        return;
      }

      // 2) Derive the NEW key.
      setState(() => _status = 'Deriving new key…');
      final newSaltBytes = VaultCrypto.randomBytes(16);
      const newParams = KdfParams.defaults;
      final newDerived = await VaultCrypto.deriveMaster(
        password: next,
        salt: newSaltBytes,
        params: newParams,
      );

      // 3) Pull every item, decrypt with OLD, re-encrypt with NEW.
      setState(() => _status = 'Re-encrypting vault items…');
      final repo = VaultRepository.instance;
      final all = <_RewrappedItem>[];
      String? cursor;
      var fetched = 0;
      while (true) {
        final page = await repo.list(cursor: cursor, limit: 100);
        for (final item in page.items) {
          final plaintext = await VaultCrypto.decrypt(
            masterKey: oldDerived.key,
            ciphertext: base64Decode(item.cipherBlob),
            iv: base64Decode(item.cipherIv),
          );
          final reEncrypted =
              await VaultCrypto.encrypt(newDerived.key, plaintext);
          all.add(
            _RewrappedItem(
              id: item.id,
              cipherBlob: base64Encode(reEncrypted.ciphertext),
              cipherIv: base64Encode(reEncrypted.iv),
            ),
          );
          fetched++;
        }
        if (mounted) {
          setState(() {
            _progress = fetched == 0 ? 0.5 : 0.5;
            _status = 'Re-encrypted $fetched items…';
          });
        }
        if (page.nextCursor == null) break;
        cursor = page.nextCursor;
      }

      // 4) Re-wrap the share keypair private key under the new master key.
      Map<String, String>? keypairPayload;
      try {
        final stored = await ShareRepository.instance.getKeypair();
        if (stored.isComplete) {
          final priv = await ShareCrypto.unwrapPrivateKey(
            masterKey: oldDerived.key,
            cipherBase64: stored.privateCipher!,
            ivBase64: stored.privateIv!,
          );
          final reWrapped = await ShareCrypto.wrapPrivateKey(
            masterKey: newDerived.key,
            privateRawBase64: base64Encode(priv),
          );
          keypairPayload = {
            'privateCipher': reWrapped.cipher,
            'privateIv': reWrapped.iv,
          };
        }
      } catch (_) {
        // Keypair may not be set up yet — non-fatal.
      }

      // 5) Atomic server-side rotation.
      setState(() => _status = 'Updating server…');
      await AuthRepository.instance.rotateMaster(
        currentVerifier: oldDerived.verifier,
        newSalt: base64Encode(newSaltBytes),
        newVerifier: newDerived.verifier,
        newParams: newParams,
        items: all
            .map(
              (i) => {
                'id': i.id,
                'cipherBlob': i.cipherBlob,
                'cipherIv': i.cipherIv,
              },
            )
            .toList(),
        keypair: keypairPayload,
      );

      // 6) Update local in-memory key + persisted-key (if biometric/remember on).
      await ref.read(authProvider.notifier).adoptRotatedMasterKey(
            key: newDerived.key,
            saltBase64: base64Encode(newSaltBytes),
            params: newParams,
          );
      final settings = await SettingsService.instance.read();
      if (settings.rememberMasterKey || settings.biometricLock) {
        await SettingsService.instance.writeMasterKey(newDerived.key);
      }

      if (!mounted) return;
      setState(() {
        _busy = false;
        _progress = 1;
        _status = 'Done';
      });
      showAppSnack(
        context,
        'Master password updated',
        kind: AppSnackKind.success,
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = friendlyApiError(e);
        _status = null;
      });
    }
  }

  bool _constantTimeEq(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: const KeepItAppBar(title: 'Change Master Password'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const InlineMessage(
              message:
                  'Every vault item will be re-encrypted on this device. Keep the app open until it finishes.',
              kind: InlineMessageKind.warning,
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: 'CURRENT PASSWORD',
              icon: Icons.lock_outline,
              child: TextField(
                controller: _current,
                obscureText: true,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Enter current master password',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'NEW PASSWORD',
              icon: Icons.lock_reset_outlined,
              child: Column(
                children: [
                  TextField(
                    controller: _next,
                    obscureText: true,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'New master password',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _confirm,
                    obscureText: true,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_status != null) ...[
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _status!,
                      style: const TextStyle(
                        color: AppTheme.fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppTheme.surfaceAlt,
                  color: AppTheme.primary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (_error != null) ...[
              InlineMessage(message: _error!, kind: InlineMessageKind.error),
              const SizedBox(height: AppSpacing.md),
            ],
            AppButton(
              label: _busy ? 'Re-encrypting…' : 'Change password',
              icon: Icons.check,
              variant: AppButtonVariant.accent,
              isBusy: _busy,
              onPressed: _busy ? null : _rotate,
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }
}

class _RewrappedItem {
  const _RewrappedItem({
    required this.id,
    required this.cipherBlob,
    required this.cipherIv,
  });
  final String id;
  final String cipherBlob;
  final String cipherIv;
}
