class AppUser {
  final int userId;       // user_id SERIAL PRIMARY KEY
  final String email;     // email VARCHAR(255)
  final String nickname;  // nickname VARCHAR(50)
  final String role;      // 'USER' | 'ADMIN'
  final bool isActive;    // is_active BOOLEAN (탈퇴·이메일 인증 여부)
  final bool isBlocked;   // is_blocked BOOLEAN
  final String provider;  // 'LOCAL' | 'KAKAO' 
  final String? providerId;       // provider_id
  final String? profileImageUrl;  // profile_image_url (백엔드 컬럼 추가 예정)
  final DateTime createdAt;       // created_at

  const AppUser({
    required this.userId,
    required this.email,
    required this.nickname,
    this.role = 'USER',
    this.isActive = true,
    this.isBlocked = false,
    this.provider = 'LOCAL',
    this.providerId,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        userId: j['user_id'] as int,
        // API v5: email → username. 두 키 모두 허용 (하위 호환)
        email: j['username'] as String? ?? j['email'] as String? ?? '',
        nickname: j['nickname'] as String,
        role: j['role'] as String? ?? 'USER',
        isActive: j['is_active'] as bool? ?? true,
        isBlocked: j['is_blocked'] as bool? ?? false,
        provider: j['provider'] as String? ?? 'LOCAL',
        providerId: j['provider_id'] as String?,
        profileImageUrl: j['profile_image_url'] as String?,
        // auth 응답(signup/login)에는 created_at이 없으므로 null-safe 처리
        createdAt: j['created_at'] != null
            ? DateTime.parse(j['created_at'] as String)
            : DateTime.now(),
      );

  AppUser copyWith({String? nickname, String? profileImageUrl}) => AppUser(
        userId: userId,
        email: email,
        nickname: nickname ?? this.nickname,
        role: role,
        isActive: isActive,
        isBlocked: isBlocked,
        provider: provider,
        providerId: providerId,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        createdAt: createdAt,
      );
}
