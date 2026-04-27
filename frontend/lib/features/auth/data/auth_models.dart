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
    required this.policyAcceptedVersion,
    required this.policyAcceptedAt,
    required this.currentPolicyVersion,
    required this.policyAcceptedCurrent,
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
  final String? policyAcceptedVersion;
  final DateTime? policyAcceptedAt;
  final String currentPolicyVersion;
  final bool policyAcceptedCurrent;

  UserProfile copyWith({
    String? email,
    String? name,
    String? avatarUrl,
    bool? masterInitialized,
    String? masterSalt,
    KdfParams? masterParams,
    int? quotaBytes,
    int? bytesUsed,
    String? policyAcceptedVersion,
    DateTime? policyAcceptedAt,
    String? currentPolicyVersion,
    bool? policyAcceptedCurrent,
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
    policyAcceptedVersion: policyAcceptedVersion ?? this.policyAcceptedVersion,
    policyAcceptedAt: policyAcceptedAt ?? this.policyAcceptedAt,
    currentPolicyVersion: currentPolicyVersion ?? this.currentPolicyVersion,
    policyAcceptedCurrent: policyAcceptedCurrent ?? this.policyAcceptedCurrent,
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
      policyAcceptedVersion: json['policyAcceptedVersion'] as String?,
      policyAcceptedAt: json['policyAcceptedAt'] == null
          ? null
          : DateTime.parse(json['policyAcceptedAt'] as String),
      currentPolicyVersion: json['currentPolicyVersion'] as String? ?? 'unknown',
      policyAcceptedCurrent: json['policyAcceptedCurrent'] as bool? ?? false,
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
      'policyAcceptedVersion': policyAcceptedVersion,
      'policyAcceptedAt': policyAcceptedAt?.toIso8601String(),
      'currentPolicyVersion': currentPolicyVersion,
      'policyAcceptedCurrent': policyAcceptedCurrent,
    };
  }
}

class PrivacyPolicyDocument {
  const PrivacyPolicyDocument({
    required this.version,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  final String version;
  final String title;
  final String content;
  final DateTime updatedAt;

  factory PrivacyPolicyDocument.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyDocument(
      version: json['version'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
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
