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

  /// 현재 JWT 액세스 토큰. 미로그인 시 null.
  String? get token;

  /// 이메일/비밀번호 로그인. 성공 시 사용자 정보 반환.
  Future<AppUser> login(String email, String password);

  /// 회원가입. 성공 시 사용자 정보 반환.
  Future<AppUser> signup(String email, String password, String nickname);

  /// 로그아웃 — 로컬 상태 초기화.
  Future<void> logout();
}

/// 현재 앱 전역에서 사용할 AuthService 인스턴스.
class AuthServiceLocator {
  AuthServiceLocator._();
  static AuthService instance = MockAuthService();
}

// ─────────────────────────────────────────────────────────
// Real 구현 — GET/PATCH /api/v1/users/me, /api/v1/users/me/profile
// ─────────────────────────────────────────────────────────

class RealAuthService implements AuthService {
  AppUser? _user;
  String? _token;
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
  String? get token => _token;

  @override
  Future<AppUser> login(String email, String password) async {
    // TODO: POST /api/v1/auth/login → _token, _user 저장
    throw UnimplementedError('로그인 미구현');
  }

  @override
  Future<AppUser> signup(String email, String password, String nickname) async {
    // TODO: POST /api/v1/auth/signup → _token, _user 저장
    throw UnimplementedError('회원가입 미구현');
  }

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

  @override
  Future<void> logout() async {
    _user = null;
    _userInput = [];
  }
}

// ─────────────────────────────────────────────────────────
// Mock 구현 — 카카오 인증 전까지 사용 (필요 시 교체)
// ─────────────────────────────────────────────────────────

class MockAuthService implements AuthService {
  bool _loggedIn = true;

  @override
  AppUser get currentUser => MockDataService.currentUser;

  @override
  UserProfile get currentProfile => MockDataService.currentProfile;

  @override
  bool get isLoggedIn => _loggedIn;

  @override
  String? get token => null;

  @override
  Future<AppUser> login(String email, String password) async {
    _loggedIn = true;
    return MockDataService.currentUser;
  }

  @override
  Future<AppUser> signup(String email, String password, String nickname) async =>
      MockDataService.currentUser;

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

  @override
  Future<void> logout() async {
    _loggedIn = false;
  }
}
