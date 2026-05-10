import '../../vault/data/vault_models.dart';

class CollabFolderSummary {
  const CollabFolderSummary({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.ownerId,
    required this.ownerName,
    required this.itemCount,
    required this.memberCount,
    required this.isOwner,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? iconKey;
  final String ownerId;
  final String ownerName;
  final int itemCount;
  final int memberCount;
  final bool isOwner;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CollabFolderSummary.fromJson(Map<String, dynamic> json) =>
      CollabFolderSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        iconKey: json['iconKey'] as String?,
        ownerId: json['ownerId'] as String,
        ownerName: json['ownerName'] as String? ?? '',
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
        memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
        isOwner: json['isOwner'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class CollabMember {
  const CollabMember({
    required this.userId,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.role,
    required this.joinedAt,
    required this.sharingPublicKey,
  });

  final String userId;
  final String email;
  final String name;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;
  final String? sharingPublicKey;

  bool get isOwner => role == 'owner';

  factory CollabMember.fromJson(Map<String, dynamic> json) => CollabMember(
        userId: json['userId'] as String,
        email: json['email'] as String,
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        role: json['role'] as String? ?? 'member',
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        sharingPublicKey: json['sharingPublicKey'] as String?,
      );
}

class CollabItem {
  const CollabItem({
    required this.id,
    required this.type,
    required this.title,
    required this.creatorId,
    required this.creatorName,
    required this.cipherBlob,
    required this.cipherIv,
    required this.wrappedKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final VaultItemType type;
  final String title;
  final String creatorId;
  final String creatorName;
  final String cipherBlob;
  final String cipherIv;
  final String wrappedKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CollabItem.fromJson(Map<String, dynamic> json) => CollabItem(
        id: json['id'] as String,
        type: vaultItemTypeFromString(json['type'] as String),
        title: json['title'] as String,
        creatorId: json['creatorId'] as String,
        creatorName: json['creatorName'] as String? ?? '',
        cipherBlob: json['cipherBlob'] as String,
        cipherIv: json['cipherIv'] as String,
        wrappedKey: json['wrappedKey'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class CollabActivity {
  const CollabActivity({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.targetItemId,
    required this.detail,
    required this.createdAt,
  });

  final String id;
  final String actorId;
  final String actorName;
  final String action;
  final String? targetItemId;
  final String? detail;
  final DateTime createdAt;

  factory CollabActivity.fromJson(Map<String, dynamic> json) => CollabActivity(
        id: json['id'] as String,
        actorId: json['actorId'] as String,
        actorName: json['actorName'] as String? ?? '',
        action: json['action'] as String,
        targetItemId: json['targetItemId'] as String?,
        detail: json['detail'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class CollabFolderDetail {
  const CollabFolderDetail({
    required this.summary,
    required this.members,
    required this.items,
    required this.activity,
  });

  final CollabFolderSummary summary;
  final List<CollabMember> members;
  final List<CollabItem> items;
  final List<CollabActivity> activity;

  factory CollabFolderDetail.fromJson(Map<String, dynamic> json) {
    return CollabFolderDetail(
      summary: CollabFolderSummary.fromJson(json),
      members: (json['members'] as List? ?? [])
          .map((m) =>
              CollabMember.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
      items: (json['items'] as List? ?? [])
          .map((m) => CollabItem.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
      activity: (json['activity'] as List? ?? [])
          .map((m) =>
              CollabActivity.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
    );
  }
}

class CollabRecipientLookup {
  const CollabRecipientLookup({
    required this.userId,
    required this.email,
    required this.name,
    required this.sharingPublicKey,
  });

  final String userId;
  final String email;
  final String name;
  final String? sharingPublicKey;

  factory CollabRecipientLookup.fromJson(Map<String, dynamic> json) =>
      CollabRecipientLookup(
        userId: json['userId'] as String,
        email: json['email'] as String,
        name: json['name'] as String? ?? '',
        sharingPublicKey: json['sharingPublicKey'] as String?,
      );
}
