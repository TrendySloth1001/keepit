import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'vault_crypto.dart';

/// End-to-end share crypto.
///
/// Protocol (sealed-box equivalent built on X25519 + HKDF + AES-GCM):
///   1. Sender generates a fresh DEK and encrypts the item payload with
///      AES-GCM (DEK, iv).
///   2. Sender generates an ephemeral X25519 keypair, computes ECDH with the
///      recipient's long-term public key, and runs HKDF-SHA256 over the
///      shared secret to derive a wrapping key.
///   3. Sender encrypts the DEK with AES-GCM under the wrapping key.
///   4. The wire-format wrappedKey is `ephemeralPubKey(32) || wrapIv(12) ||
///      wrapCiphertext(48)` — recipient knows where each segment is.
///   5. Recipient derives the same wrapping key from its private key + the
///      embedded ephemeral pub key, decrypts the DEK, and uses it to decrypt
///      the payload.
///
/// The server only ever sees ciphertext + wrappedKey, so it cannot read the
/// payload even if it knows the share id and recipient.
class ShareCrypto {
  ShareCrypto._();

  static final _x25519 = Cryptography.instance.x25519();
  static final _aes = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Generates a fresh long-term sharing keypair. The private key is
  /// encrypted at-rest with the user's master key; the public key is
  /// published to the server.
  static Future<({String publicKey, String privateRaw})> generateKeypair() async {
    final pair = await _x25519.newKeyPair();
    final pub = await pair.extractPublicKey();
    final priv = await pair.extractPrivateKeyBytes();
    return (
      publicKey: base64Encode(pub.bytes),
      privateRaw: base64Encode(priv),
    );
  }

  /// Encrypt the raw private key bytes with the master key for at-rest
  /// storage on the server.
  static Future<({String cipher, String iv})> wrapPrivateKey({
    required Uint8List masterKey,
    required String privateRawBase64,
  }) async {
    final raw = base64Decode(privateRawBase64);
    final out = await VaultCrypto.encrypt(masterKey, raw);
    return (
      cipher: base64Encode(out.ciphertext),
      iv: base64Encode(out.iv),
    );
  }

  static Future<Uint8List> unwrapPrivateKey({
    required Uint8List masterKey,
    required String cipherBase64,
    required String ivBase64,
  }) async {
    return VaultCrypto.decrypt(
      masterKey: masterKey,
      ciphertext: base64Decode(cipherBase64),
      iv: base64Decode(ivBase64),
    );
  }

  /// Encrypts `payload` with a fresh DEK, then seals the DEK to
  /// `recipientPublicKey`. Returns the values the server expects.
  static Future<SealedShare> sealForRecipient({
    required String recipientPublicKeyBase64,
    required Map<String, dynamic> payload,
  }) async {
    final dek = VaultCrypto.randomBytes(32);
    final plain = utf8.encode(jsonEncode(payload));

    // Encrypt the payload with the DEK (AES-256-GCM).
    final iv = VaultCrypto.randomBytes(12);
    final secretBox = await _aes.encrypt(
      plain,
      secretKey: SecretKey(dek),
      nonce: iv,
    );
    final cipher = Uint8List(secretBox.cipherText.length + 16)
      ..setRange(0, secretBox.cipherText.length, secretBox.cipherText)
      ..setRange(
        secretBox.cipherText.length,
        secretBox.cipherText.length + 16,
        secretBox.mac.bytes,
      );

    // Wrap the DEK for the recipient.
    final ephem = await _x25519.newKeyPair();
    final ephemPub = await ephem.extractPublicKey();
    final shared = await _x25519.sharedSecretKey(
      keyPair: ephem,
      remotePublicKey: SimplePublicKey(
        base64Decode(recipientPublicKeyBase64),
        type: KeyPairType.x25519,
      ),
    );
    final wrappingKey = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode('keepit:share-wrap:v1'),
    );
    final wrapIv = VaultCrypto.randomBytes(12);
    final wrapBox = await _aes.encrypt(
      dek,
      secretKey: wrappingKey,
      nonce: wrapIv,
    );

    // Wire format: ephemPub(32) || wrapIv(12) || wrapCipher || wrapMac(16)
    final ephemBytes = Uint8List.fromList(ephemPub.bytes);
    final wrapped = Uint8List(
      32 + 12 + wrapBox.cipherText.length + 16,
    );
    var offset = 0;
    wrapped.setRange(offset, offset + 32, ephemBytes);
    offset += 32;
    wrapped.setRange(offset, offset + 12, wrapIv);
    offset += 12;
    wrapped.setRange(
      offset,
      offset + wrapBox.cipherText.length,
      wrapBox.cipherText,
    );
    offset += wrapBox.cipherText.length;
    wrapped.setRange(offset, offset + 16, wrapBox.mac.bytes);

    return SealedShare(
      cipherBlob: base64Encode(cipher),
      cipherIv: base64Encode(iv),
      wrappedKey: base64Encode(wrapped),
    );
  }

  /// Decrypts a share received over the wire. The recipient's private key
  /// must already have been unwrapped from the master-key-encrypted form.
  static Future<Map<String, dynamic>> openShare({
    required Uint8List recipientPrivateKey,
    required String cipherBlobBase64,
    required String cipherIvBase64,
    required String wrappedKeyBase64,
  }) async {
    final wrapped = base64Decode(wrappedKeyBase64);
    if (wrapped.length < 32 + 12 + 16) {
      throw const FormatException('wrappedKey too short');
    }
    final ephemPub = wrapped.sublist(0, 32);
    final wrapIv = wrapped.sublist(32, 44);
    final wrapMac = wrapped.sublist(wrapped.length - 16);
    final wrapCipher = wrapped.sublist(44, wrapped.length - 16);

    final shared = await _x25519.sharedSecretKey(
      keyPair: SimpleKeyPairData(
        recipientPrivateKey,
        publicKey: SimplePublicKey(ephemPub, type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      ),
      remotePublicKey:
          SimplePublicKey(ephemPub, type: KeyPairType.x25519),
    );
    final wrappingKey = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode('keepit:share-wrap:v1'),
    );
    final dek = await _aes.decrypt(
      SecretBox(wrapCipher, nonce: wrapIv, mac: Mac(wrapMac)),
      secretKey: wrappingKey,
    );

    final cipher = base64Decode(cipherBlobBase64);
    final iv = base64Decode(cipherIvBase64);
    final mac = cipher.sublist(cipher.length - 16);
    final body = cipher.sublist(0, cipher.length - 16);
    final plain = await _aes.decrypt(
      SecretBox(body, nonce: iv, mac: Mac(mac)),
      secretKey: SecretKey(dek),
    );
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  }
}

class SealedShare {
  const SealedShare({
    required this.cipherBlob,
    required this.cipherIv,
    required this.wrappedKey,
  });
  final String cipherBlob;
  final String cipherIv;
  final String wrappedKey;
}

class SealedFanout {
  const SealedFanout({
    required this.cipherBlob,
    required this.cipherIv,
    required this.wrappedKeys,
  });
  final String cipherBlob;
  final String cipherIv;
  // Map of userId → base64 wrappedKey.
  final Map<String, String> wrappedKeys;
}

/// Multi-recipient sealing helpers used by collaborative shared folders.
/// The payload is encrypted once with a fresh DEK; the DEK is then wrapped
/// independently to each recipient's sharing public key (same wrap protocol
/// as [ShareCrypto.sealForRecipient]).
class CollabCrypto {
  CollabCrypto._();

  static final _x25519 = Cryptography.instance.x25519();
  static final _aes = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Encrypts [payload] under a fresh DEK and wraps that DEK to every
  /// recipient in [recipients]. Caller MUST include themselves.
  static Future<SealedFanout> sealForMembers({
    required Map<String, dynamic> payload,
    required Map<String, String> recipients, // userId -> publicKey base64
  }) async {
    final dek = VaultCrypto.randomBytes(32);
    final iv = VaultCrypto.randomBytes(12);
    final plain = utf8.encode(jsonEncode(payload));
    final secretBox = await _aes.encrypt(
      plain,
      secretKey: SecretKey(dek),
      nonce: iv,
    );
    final cipher = Uint8List(secretBox.cipherText.length + 16)
      ..setRange(0, secretBox.cipherText.length, secretBox.cipherText)
      ..setRange(
        secretBox.cipherText.length,
        secretBox.cipherText.length + 16,
        secretBox.mac.bytes,
      );

    final wrapped = <String, String>{};
    for (final entry in recipients.entries) {
      wrapped[entry.key] = await _wrapDek(dek, entry.value);
    }
    return SealedFanout(
      cipherBlob: base64Encode(cipher),
      cipherIv: base64Encode(iv),
      wrappedKeys: wrapped,
    );
  }

  /// Re-wraps an already-known DEK to a single new recipient (used by
  /// [reWrapForNewMember] when inviting someone — we open each existing
  /// item with our own key, recover the DEK, and seal it for the invitee).
  static Future<String> wrapDekFor({
    required Uint8List dek,
    required String recipientPublicKeyBase64,
  }) {
    return _wrapDek(dek, recipientPublicKeyBase64);
  }

  static Future<String> _wrapDek(
    Uint8List dek,
    String recipientPublicKeyBase64,
  ) async {
    final ephem = await _x25519.newKeyPair();
    final ephemPub = await ephem.extractPublicKey();
    final shared = await _x25519.sharedSecretKey(
      keyPair: ephem,
      remotePublicKey: SimplePublicKey(
        base64Decode(recipientPublicKeyBase64),
        type: KeyPairType.x25519,
      ),
    );
    final wrappingKey = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode('keepit:share-wrap:v1'),
    );
    final wrapIv = VaultCrypto.randomBytes(12);
    final wrapBox = await _aes.encrypt(
      dek,
      secretKey: wrappingKey,
      nonce: wrapIv,
    );
    final ephemBytes = Uint8List.fromList(ephemPub.bytes);
    final out = Uint8List(32 + 12 + wrapBox.cipherText.length + 16);
    var off = 0;
    out.setRange(off, off + 32, ephemBytes);
    off += 32;
    out.setRange(off, off + 12, wrapIv);
    off += 12;
    out.setRange(off, off + wrapBox.cipherText.length, wrapBox.cipherText);
    off += wrapBox.cipherText.length;
    out.setRange(off, off + 16, wrapBox.mac.bytes);
    return base64Encode(out);
  }

  /// Recovers the DEK for an item by unwrapping the caller's own
  /// `wrappedKey` row. Used when re-wrapping older items for a newly
  /// invited member.
  static Future<Uint8List> recoverDek({
    required Uint8List myPrivateKey,
    required String wrappedKeyBase64,
  }) async {
    final wrapped = base64Decode(wrappedKeyBase64);
    if (wrapped.length < 32 + 12 + 16) {
      throw const FormatException('wrappedKey too short');
    }
    final ephemPub = wrapped.sublist(0, 32);
    final wrapIv = wrapped.sublist(32, 44);
    final wrapMac = wrapped.sublist(wrapped.length - 16);
    final wrapCipher = wrapped.sublist(44, wrapped.length - 16);
    final shared = await _x25519.sharedSecretKey(
      keyPair: SimpleKeyPairData(
        myPrivateKey,
        publicKey: SimplePublicKey(ephemPub, type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      ),
      remotePublicKey: SimplePublicKey(ephemPub, type: KeyPairType.x25519),
    );
    final wrappingKey = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode('keepit:share-wrap:v1'),
    );
    final dek = await _aes.decrypt(
      SecretBox(wrapCipher, nonce: wrapIv, mac: Mac(wrapMac)),
      secretKey: wrappingKey,
    );
    return Uint8List.fromList(dek);
  }

  /// Decrypts the cipher payload given the recovered DEK.
  static Future<Map<String, dynamic>> openWithDek({
    required Uint8List dek,
    required String cipherBlobBase64,
    required String cipherIvBase64,
  }) async {
    final cipher = base64Decode(cipherBlobBase64);
    final iv = base64Decode(cipherIvBase64);
    final mac = cipher.sublist(cipher.length - 16);
    final body = cipher.sublist(0, cipher.length - 16);
    final plain = await _aes.decrypt(
      SecretBox(body, nonce: iv, mac: Mac(mac)),
      secretKey: SecretKey(dek),
    );
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  }
}
