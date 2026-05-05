import '../data/mock_data_service.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import 'naengo_api_service.dart';

///
/// 프로필 화면은 이 인터페이스만 바라봄 →
/// [MockAuthService] → [RealAuthService] → KakaoAuthService 교체 시 UI 코드 수정 불필요.
abstract class AuthService {
  /// 현재 로그인된 사용자 기본 정보.
  AppUser get currentUser;

  /// 현재 로그인된 사용자 프로필 (취향 데이터).
  UserProfile get currentProfile;

  /// 서비스 초기화 — API 데이터를 로드. Mock에서는 즉시 완료.
  Future<void> load();

  /// 유저가 직접 입력한 문장 배열([UserProfile.userInput])을 업데이트.
  Future<void> updateUserInput(List<String> inputs);

  /// 닉네임을 업데이트.
  Future<void> updateNickname(String nickname);

  /// 로그인 여부.
  bool get isLoggedIn;
}

/// 현재 앱 전역에서 사용할 AuthService 인스턴스.
class AuthServiceLocator {
  AuthServiceLocator._();
  static AuthService instance = RealAuthService();
}

// ─────────────────────────────────────────────────────────
// Real 구현 — GET/PATCH /api/v1/users/me, /api/v1/users/me/profile
// ─────────────────────────────────────────────────────────

class RealAuthService implements AuthService {
  AppUser? _user;
  List<String> _userInput = [];

  @override
  AppUser get currentUser =>
      _user ??
      AppUser(
        userId: 1,
        email: '',
        nickname: '...',
        createdAt: DateTime.now(),
      );

  @override
  UserProfile get currentProfile => UserProfile(
        userId: _user?.userId ?? 1,
        userInput: _userInput,
        updatedAt: DateTime.now(),
      );

  @override
  bool get isLoggedIn => _user != null;

  @override
  Future<void> load() async {
    _user = await NaengoApi.getMe();
    try {
      _userInput = await NaengoApi.getProfileInput();
    } catch (_) {
      _userInput = [];
    }
  }

  @override
  Future<void> updateNickname(String nickname) async {
    _user = await NaengoApi.patchNickname(nickname);
  }

  @override
  Future<void> updateUserInput(List<String> inputs) async {
    _userInput = await NaengoApi.patchProfileInput(inputs);
  }
}

// ─────────────────────────────────────────────────────────
// Mock 구현 — 카카오 인증 전까지 사용 (필요 시 교체)
// ─────────────────────────────────────────────────────────

class MockAuthService implements AuthService {
  @override
  AppUser get currentUser => MockDataService.currentUser;

  @override
  UserProfile get currentProfile => MockDataService.currentProfile;

  @override
  bool get isLoggedIn => true;

  @override
  Future<void> load() async {} // 즉시 완료

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
