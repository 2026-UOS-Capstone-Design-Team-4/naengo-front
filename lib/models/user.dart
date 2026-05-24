class UserIdentity {
  final int id;
  final String provider; // 'KAKAO' | 'GOOGLE' | 'NAVER' | 'APPLE'
  final String? email;
  final DateTime createdAt;

  const UserIdentity({
    required this.id,
    required this.provider,
    this.email,
    required this.createdAt,
  });

  factory UserIdentity.fromJson(Map<String, dynamic> j) => UserIdentity(
        id: j['id'] as int,
        provider: j['provider'] as String,
        email: j['email'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class AppUser {
  final int userId;
  final String? username;
  final String nickname;
  final String role; // 'USER' | 'ADMIN'
  final bool isActive;
  final bool isBlocked;
  final List<UserIdentity> userIdentities;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.userId,
    this.username,
    required this.nickname,
    this.role = 'USER',
    this.isActive = true,
    this.isBlocked = false,
    this.userIdentities = const [],
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        userId: j['user_id'] as int,
        username: j['username'] as String?,
        nickname: j['nickname'] as String,
        role: j['role'] as String? ?? 'USER',
        isActive: j['is_active'] as bool? ?? true,
        isBlocked: j['is_blocked'] as bool? ?? false,
        userIdentities: ((j['user_identities'] as List?) ?? const [])
            .map((e) => UserIdentity.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        profileImageUrl: j['profile_image_url'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.parse(j['created_at'] as String)
            : DateTime.now(),
        updatedAt: j['updated_at'] != null
            ? DateTime.tryParse(j['updated_at'] as String)
            : null,
      );

  AppUser copyWith({String? nickname, String? profileImageUrl}) => AppUser(
        userId: userId,
        username: username,
        nickname: nickname ?? this.nickname,
        role: role,
        isActive: isActive,
        isBlocked: isBlocked,
        userIdentities: userIdentities,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
