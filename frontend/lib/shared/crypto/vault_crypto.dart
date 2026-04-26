import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class KdfParams {
  const KdfParams({
    this.algo = 'argon2id',
    this.iterations = 3,
    this.memoryKiB = 65536,
    this.parallelism = 2,
    this.keyLength = 32,
    this.version = 0x13,
  });

  final String algo;
  final int iterations;
  final int memoryKiB;
  final int parallelism;
  final int keyLength;
  final int version;

  Map<String, dynamic> toJson() => {
    'algo': algo,
    'iterations': iterations,
    'memoryKiB': memoryKiB,
    'parallelism': parallelism,
    'keyLength': keyLength,
    'version': version,
  };

  factory KdfParams.fromJson(Map<String, dynamic> json) => KdfParams(
    algo: json['algo'] as String? ?? 'argon2id',
    iterations: (json['iterations'] as num).toInt(),
    memoryKiB: (json['memoryKiB'] as num).toInt(),
    parallelism: (json['parallelism'] as num).toInt(),
    keyLength: (json['keyLength'] as num).toInt(),
    version: (json['version'] as num?)?.toInt() ?? 0x13,
  );

  static const KdfParams defaults = KdfParams();
}

class DerivedMasterKey {
  const DerivedMasterKey({required this.key, required this.verifier});

  final Uint8List key;
  final String verifier; // base64
}

class VaultCrypto {
  VaultCrypto._();

  static final _rng = Random.secure();
  static final _aes = AesGcm.with256bits();

  static Uint8List randomBytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _rng.nextInt(256);
    }
    return out;
  }

  static String randomSaltBase64({int length = 16}) {
    return base64Encode(randomBytes(length));
  }

  static Future<Uint8List> deriveKey({
    required String password,
    required Uint8List salt,
    required KdfParams params,
  }) async {
    final kdf = Argon2id(
      memory: params.memoryKiB,
      parallelism: params.parallelism,
      iterations: params.iterations,
      hashLength: params.keyLength,
    );
    final secretKey = await kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Verifier sent to the server so it can confirm the user typed the right
  /// master password without ever seeing the actual key.
  static Future<String> deriveVerifier(Uint8List masterKey) async {
    final mac = Hmac.sha256();
    final result = await mac.calculateMac(
      utf8.encode('keepit:master:verifier:v1'),
      secretKey: SecretKey(masterKey),
    );
    return base64Encode(result.bytes);
  }

  static Future<DerivedMasterKey> deriveMaster({
    required String password,
    required Uint8List salt,
    required KdfParams params,
  }) async {
    final key = await deriveKey(password: password, salt: salt, params: params);
    final verifier = await deriveVerifier(key);
    return DerivedMasterKey(key: key, verifier: verifier);
  }

  static Future<({Uint8List ciphertext, Uint8List iv})> encrypt(
    Uint8List masterKey,
    Uint8List plaintext,
  ) async {
    final iv = randomBytes(12);
    final secretBox = await _aes.encrypt(
      plaintext,
      secretKey: SecretKey(masterKey),
      nonce: iv,
    );
    final out = Uint8List(secretBox.cipherText.length + 16);
    out.setRange(0, secretBox.cipherText.length, secretBox.cipherText);
    out.setRange(
      secretBox.cipherText.length,
      out.length,
      secretBox.mac.bytes,
    );
    return (ciphertext: out, iv: iv);
  }

  static Future<Uint8List> decrypt({
    required Uint8List masterKey,
    required Uint8List ciphertext,
    required Uint8List iv,
  }) async {
    if (ciphertext.length < 16) {
      throw const FormatException('cipher too short');
    }
    final cipher = ciphertext.sublist(0, ciphertext.length - 16);
    final mac = ciphertext.sublist(ciphertext.length - 16);
    final secretBox = SecretBox(cipher, nonce: iv, mac: Mac(mac));
    final plain = await _aes.decrypt(secretBox, secretKey: SecretKey(masterKey));
    return Uint8List.fromList(plain);
  }

  static Future<({String cipherBlob, String cipherIv})> encryptJson(
    Uint8List masterKey,
    Map<String, dynamic> payload,
  ) async {
    final encoded = utf8.encode(jsonEncode(payload));
    final encrypted = await encrypt(masterKey, Uint8List.fromList(encoded));
    return (
      cipherBlob: base64Encode(encrypted.ciphertext),
      cipherIv: base64Encode(encrypted.iv),
    );
  }

  static Future<Map<String, dynamic>> decryptJson({
    required Uint8List masterKey,
    required String cipherBlob,
    required String cipherIv,
  }) async {
    final plain = await decrypt(
      masterKey: masterKey,
      ciphertext: base64Decode(cipherBlob),
      iv: base64Decode(cipherIv),
    );
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  }
}
