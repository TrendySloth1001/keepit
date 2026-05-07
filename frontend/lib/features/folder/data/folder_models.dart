class VaultFolder {
  const VaultFolder({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? iconKey;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory VaultFolder.fromJson(Map<String, dynamic> json) => VaultFolder(
        id: json['id'] as String,
        name: json['name'] as String,
        iconKey: json['iconKey'] as String?,
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  VaultFolder copyWith({String? name, String? iconKey, int? itemCount}) =>
      VaultFolder(
        id: id,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
        itemCount: itemCount ?? this.itemCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
