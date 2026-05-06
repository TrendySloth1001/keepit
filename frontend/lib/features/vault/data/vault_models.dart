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
enum ExtraFieldKind { text, password, note, key }

ExtraFieldKind extraFieldKindFromKey(String? key) {
  if (key == null || key.isEmpty) return ExtraFieldKind.text;
  for (final kind in ExtraFieldKind.values) {
    if (kind.name == key) return kind;
  }
  return ExtraFieldKind.text;
}

extension ExtraFieldKindX on ExtraFieldKind {
  String get label => switch (this) {
    ExtraFieldKind.text => 'Text',
    ExtraFieldKind.password => 'Password',
    ExtraFieldKind.note => 'Note',
    ExtraFieldKind.key => 'Key',
  };

  bool get isSecret =>
      this == ExtraFieldKind.password || this == ExtraFieldKind.key;

  bool get isMultiline => this == ExtraFieldKind.note;
}

class PasswordExtraField {
  const PasswordExtraField({
    required this.label,
    required this.value,
    required this.kind,
  });

  final String label;
  final String value;
  final ExtraFieldKind kind;

  Map<String, dynamic> toJson() => {
    'label': label,
    'value': value,
    'kind': kind.name,
  };

  factory PasswordExtraField.fromJson(Map<String, dynamic> json) =>
      PasswordExtraField(
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
        kind: extraFieldKindFromKey(json['kind'] as String?),
      );
}

class PasswordPayload {
  const PasswordPayload({
    required this.username,
    required this.password,
    this.url,
    this.notes,
    this.iconKey,
    this.category,
    this.extras = const [],
  });

  final String username;
  final String password;
  final String? url;
  final String? notes;

  /// Stable catalog key — see [IconCatalog]. Visual mapping only; safe to
  /// rename/retire entries as long as old keys still resolve.
  final String? iconKey;

  /// Free-form category label (e.g. "Work", "Personal", "Crypto"). Encrypted.
  final String? category;

  /// Optional user-defined fields (notes, keys, or extra passwords).
  final List<PasswordExtraField> extras;

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    if (url != null) 'url': url,
    if (notes != null) 'notes': notes,
    if (iconKey != null) 'iconKey': iconKey,
    if (category != null) 'category': category,
    if (extras.isNotEmpty) 'extras': extras.map((f) => f.toJson()).toList(),
  };

  factory PasswordPayload.fromJson(Map<String, dynamic> json) =>
      PasswordPayload(
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        url: json['url'] as String?,
        notes: json['notes'] as String?,
        iconKey: json['iconKey'] as String?,
        category: json['category'] as String?,
        extras:
            (json['extras'] as List?)
                ?.cast<Map>()
                .map(
                  (m) =>
                      PasswordExtraField.fromJson(Map<String, dynamic>.from(m)),
                )
                .toList() ??
            const [],
      );
}

class NotePayload {
  const NotePayload({required this.body, this.iconKey});
  final String body;
  final String? iconKey;

  Map<String, dynamic> toJson() => {
    'body': body,
    if (iconKey != null) 'iconKey': iconKey,
  };

  factory NotePayload.fromJson(Map<String, dynamic> json) => NotePayload(
    body: json['body'] as String? ?? '',
    iconKey: json['iconKey'] as String?,
  );
}

class KeyPayload {
  const KeyPayload({
    required this.value,
    this.kind,
    this.notes,
    this.iconKey,
    this.category,
  });

  final String value;
  final String? kind;
  final String? notes;
  final String? iconKey;
  final String? category;

  Map<String, dynamic> toJson() => {
    'value': value,
    if (kind != null) 'kind': kind,
    if (notes != null) 'notes': notes,
    if (iconKey != null) 'iconKey': iconKey,
    if (category != null) 'category': category,
  };

  factory KeyPayload.fromJson(Map<String, dynamic> json) => KeyPayload(
    value: json['value'] as String? ?? '',
    kind: json['kind'] as String?,
    notes: json['notes'] as String?,
    iconKey: json['iconKey'] as String?,
    category: json['category'] as String?,
  );
}

class NoteMeta {
  const NoteMeta({this.iconKey, this.category});
  final String? iconKey;
  final String? category;
}
