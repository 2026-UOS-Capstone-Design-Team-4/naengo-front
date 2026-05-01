import '../data/mock_data_service.dart';
import '../models/user.dart';
import '../models/user_profile.dart';

///
/// 프로필 화면은 이 인터페이스만 바라봄 →
/// [MockAuthService] → KakaoAuthService 교체 시 UI 코드 수정 불필요.
abstract class AuthService {
  /// 현재 로그인된 사용자 기본 정보.
  AppUser get currentUser;

  /// 현재 로그인된 사용자 프로필 (취향·AI 분석 데이터).
  UserProfile get currentProfile;

  /// 유저가 직접 입력한 문장 배열([UserProfile.userInput])을 업데이트.
  ///
  /// 카카오 인증 이후엔 `PATCH /api/v1/users/me/profile` 호출로 교체.
  Future<void> updateUserInput(List<String> inputs);

  /// 닉네임을 업데이트.
  ///
  /// 카카오 인증 이후엔 `PATCH /api/v1/users/me` 호출로 교체.
  Future<void> updateNickname(String nickname);

  /// 로그인 여부.
  bool get isLoggedIn;
}

/// 현재 앱 전역에서 사용할 AuthService 인스턴스.
///
/// 카카오 인증 준비 완료 시:
///   AuthServiceLocator.instance = KakaoAuthService();
class AuthServiceLocator {
  AuthServiceLocator._();
  static AuthService instance = MockAuthService();
}

// ─────────────────────────────────────────────────────────
// Mock 구현 — 카카오 인증 전까지 사용
// ─────────────────────────────────────────────────────────

class MockAuthService implements AuthService {
  @override
  AppUser get currentUser => MockDataService.currentUser;

  @override
  UserProfile get currentProfile => MockDataService.currentProfile;

  @override
  bool get isLoggedIn => true; // 목 단계에서는 항상 로그인 상태

  @override
  Future<void> updateUserInput(List<String> inputs) async {
    MockDataService.currentProfile =
        MockDataService.currentProfile.copyWith(userInput: inputs);
  }

  @override
  Future<void> updateNickname(String nickname) async {
    MockDataService.currentUser =
        MockDataService.currentUser.copyWith(nickname: nickname);
  }
}
