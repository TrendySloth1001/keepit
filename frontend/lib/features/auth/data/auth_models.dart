import '../../../shared/crypto/vault_crypto.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.masterInitialized,
    required this.masterSalt,
    required this.masterParams,
    required this.quotaBytes,
    required this.bytesUsed,
  });

  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final bool masterInitialized;
  final String? masterSalt;
  final KdfParams? masterParams;
  final int quotaBytes;
  final int bytesUsed;

  UserProfile copyWith({
    String? email,
    String? name,
    String? avatarUrl,
    bool? masterInitialized,
    String? masterSalt,
    KdfParams? masterParams,
    int? quotaBytes,
    int? bytesUsed,
  }) => UserProfile(
    id: id,
    email: email ?? this.email,
    name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    masterInitialized: masterInitialized ?? this.masterInitialized,
    masterSalt: masterSalt ?? this.masterSalt,
    masterParams: masterParams ?? this.masterParams,
    quotaBytes: quotaBytes ?? this.quotaBytes,
    bytesUsed: bytesUsed ?? this.bytesUsed,
  );

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final params = json['masterParams'];
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      masterInitialized: json['masterInitialized'] as bool,
      masterSalt: json['masterSalt'] as String?,
      masterParams: params == null
          ? null
          : KdfParams.fromJson(Map<String, dynamic>.from(params as Map)),
      quotaBytes: int.parse(json['quotaBytes'] as String),
      bytesUsed: int.parse(json['bytesUsed'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'masterInitialized': masterInitialized,
      'masterSalt': masterSalt,
      'masterParams': masterParams?.toJson(),
      'quotaBytes': quotaBytes.toString(),
      'bytesUsed': bytesUsed.toString(),
    };
  }
}

class SignInResult {
  const SignInResult({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime expiresAt;
  final UserProfile user;

  factory SignInResult.fromJson(Map<String, dynamic> json) => SignInResult(
    token: json['token'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    user: UserProfile.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
  );
}
