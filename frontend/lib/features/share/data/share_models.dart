import '../../vault/data/vault_models.dart';

class SharedItem {
  const SharedItem({
    required this.id,
    required this.ownerName,
    required this.ownerEmail,
    required this.recipientEmail,
    required this.type,
    required this.title,
    required this.cipherBlob,
    required this.cipherIv,
    required this.wrappedKey,
    required this.permission,
    required this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String ownerName;
  final String ownerEmail;
  final String recipientEmail;
  final VaultItemType type;
  final String title;
  final String cipherBlob;
  final String cipherIv;
  final String wrappedKey;
  final String permission;
  final DateTime createdAt;
  // Optional auto-revoke timestamp. null means "no expiry".
  final DateTime? expiresAt;

  bool get canEdit => permission == 'edit';
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory SharedItem.fromJson(Map<String, dynamic> json) => SharedItem(
        id: json['id'] as String,
        ownerName: json['ownerName'] as String? ?? '',
        ownerEmail: json['ownerEmail'] as String? ?? '',
        recipientEmail: json['recipientEmail'] as String? ?? '',
        type: vaultItemTypeFromString(json['type'] as String),
        title: json['title'] as String,
        cipherBlob: json['cipherBlob'] as String,
        cipherIv: json['cipherIv'] as String,
        wrappedKey: json['wrappedKey'] as String,
        permission: json['permission'] as String? ?? 'view',
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.parse(json['expiresAt'] as String),
      );
}

class RecipientInfo {
  const RecipientInfo({
    required this.id,
    required this.email,
    required this.name,
    required this.publicKey,
  });
  final String id;
  final String email;
  final String name;
  final String publicKey;

  factory RecipientInfo.fromJson(Map<String, dynamic> json) => RecipientInfo(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String? ?? '',
        publicKey: json['sharingPublicKey'] as String,
      );
}

class StoredKeypair {
  const StoredKeypair({
    required this.publicKey,
    required this.privateCipher,
    required this.privateIv,
  });
  final String? publicKey;
  final String? privateCipher;
  final String? privateIv;

  bool get isComplete =>
      publicKey != null && privateCipher != null && privateIv != null;

  factory StoredKeypair.fromJson(Map<String, dynamic> json) => StoredKeypair(
        publicKey: json['publicKey'] as String?,
        privateCipher: json['privateCipher'] as String?,
        privateIv: json['privateIv'] as String?,
      );
}

class SharedItemViewArgs {
  const SharedItemViewArgs({required this.item, required this.incoming});

  final SharedItem item;
  final bool incoming;
}
