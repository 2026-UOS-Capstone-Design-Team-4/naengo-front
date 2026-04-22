class AppUser {
  final int userId; // user_id SERIAL PRIMARY KEY
  final String email; // email VARCHAR(255)
  final String nickname; // nickname VARCHAR(50)
  final String role; // 'USER' | 'ADMIN'
  final bool isBlocked; // is_blocked BOOLEAN
  final String provider; // 'LOCAL' | 'KAKAO' | 'GOOGLE' ...
  final String? providerId; // provider_id
  final DateTime createdAt; // created_at

  const AppUser({
    required this.userId,
    required this.email,
    required this.nickname,
    this.role = 'USER',
    this.isBlocked = false,
    this.provider = 'LOCAL',
    this.providerId,
    required this.createdAt,
  });
}
