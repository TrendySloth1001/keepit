enum VaultItemType { password, note, key, file, image }

VaultItemType vaultItemTypeFromString(String s) =>
    VaultItemType.values.firstWhere((e) => e.name == s);

/// Metadata returned by the API. The actual sensitive payload sits inside
/// `cipherBlob` and is only readable on-device once decrypted with the master key.
class VaultItem {
  const VaultItem({
    required this.id,
    required this.type,
    required this.title,
    required this.cipherBlob,
    required this.cipherIv,
    required this.fileSize,
    required this.fileMime,
    required this.uploadStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final VaultItemType type;
  final String title;
  final String cipherBlob;
  final String cipherIv;
  final int? fileSize;
  final String? fileMime;
  final String? uploadStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory VaultItem.fromJson(Map<String, dynamic> json) => VaultItem(
    id: json['id'] as String,
    type: vaultItemTypeFromString(json['type'] as String),
    title: json['title'] as String,
    cipherBlob: json['cipherBlob'] as String,
    cipherIv: json['cipherIv'] as String,
    fileSize: json['fileSize'] == null
        ? null
        : int.parse(json['fileSize'] as String),
    fileMime: json['fileMime'] as String?,
    uploadStatus: json['uploadStatus'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class StorageStats {
  const StorageStats({
    required this.bytesUsed,
    required this.quotaBytes,
    required this.breakdown,
  });

  final int bytesUsed;
  final int quotaBytes;
  final List<StorageBreakdown> breakdown;

  double get fraction =>
      quotaBytes == 0 ? 0 : (bytesUsed / quotaBytes).clamp(0.0, 1.0);

  factory StorageStats.fromJson(Map<String, dynamic> json) => StorageStats(
    bytesUsed: int.parse(json['bytesUsed'] as String),
    quotaBytes: int.parse(json['quotaBytes'] as String),
    breakdown: (json['breakdown'] as List)
        .cast<Map>()
        .map((m) => StorageBreakdown.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
  );
}

class StorageBreakdown {
  const StorageBreakdown({
    required this.type,
    required this.bytes,
    required this.count,
  });

  final VaultItemType type;
  final int bytes;
  final int count;

  factory StorageBreakdown.fromJson(Map<String, dynamic> json) =>
      StorageBreakdown(
        type: vaultItemTypeFromString(json['type'] as String),
        bytes: int.parse(json['bytes'] as String),
        count: json['count'] as int,
      );
}

/// Plaintext shapes (encrypted client-side before being persisted).
class PasswordPayload {
  const PasswordPayload({
    required this.username,
    required this.password,
    this.url,
    this.notes,
  });

  final String username;
  final String password;
  final String? url;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    if (url != null) 'url': url,
    if (notes != null) 'notes': notes,
  };

  factory PasswordPayload.fromJson(Map<String, dynamic> json) => PasswordPayload(
    username: json['username'] as String? ?? '',
    password: json['password'] as String? ?? '',
    url: json['url'] as String?,
    notes: json['notes'] as String?,
  );
}

class NotePayload {
  const NotePayload({required this.body});
  final String body;

  Map<String, dynamic> toJson() => {'body': body};

  factory NotePayload.fromJson(Map<String, dynamic> json) =>
      NotePayload(body: json['body'] as String? ?? '');
}

class KeyPayload {
  const KeyPayload({
    required this.value,
    this.kind,
    this.notes,
  });

  final String value;
  final String? kind;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'value': value,
    if (kind != null) 'kind': kind,
    if (notes != null) 'notes': notes,
  };

  factory KeyPayload.fromJson(Map<String, dynamic> json) => KeyPayload(
    value: json['value'] as String? ?? '',
    kind: json['kind'] as String?,
    notes: json['notes'] as String?,
  );
}
