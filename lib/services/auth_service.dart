import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../data/mock_data_service.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import 'naengo_api_service.dart';

///
/// 프로필 화면은 이 인터페이스만 바라봄 →
/// [MockAuthService] → [RealAuthService] 교체 시 UI 코드 수정 불필요.
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

  /// 카카오 소셜 로그인. 성공 시 사용자 정보 반환.
  Future<AppUser> loginWithKakao();

  /// 이메일/비밀번호 로그인 (LOCAL 계정 전용).
  Future<AppUser> login(String email, String password);

  /// 회원가입 (LOCAL 계정 전용).
  Future<AppUser> signup(String email, String password, String nickname);

  /// 로그아웃 — 서버 쿠키 만료 요청 + 로컬 상태 초기화.
  Future<void> logout();
}

/// 현재 앱 전역에서 사용할 AuthService 인스턴스.
/// main()에서 RealAuthService로 교체 및 토큰 복원 후 runApp() 호출.
class AuthServiceLocator {
  AuthServiceLocator._();
  static AuthService instance = MockAuthService();
}

// ─────────────────────────────────────────────────────────
// Real 구현 — 카카오 SDK + Spring API 서버
// ─────────────────────────────────────────────────────────

class RealAuthService implements AuthService {
  AppUser? _user;
  String? _token;
  List<String> _userInput = [];

  @override
  AppUser get currentUser =>
      _user ??
      AppUser(
        userId: 0,
        nickname: '게스트',
        createdAt: DateTime.now(),
      );

  @override
  UserProfile get currentProfile => UserProfile(
        userId: _user?.userId ?? 0,
        userInput: _userInput,
        updatedAt: DateTime.now(),
      );

  @override
  bool get isLoggedIn => _user != null;

  @override
  String? get token => _token;

  // ── 카카오 로그인 ───────────────────────────────────────

  @override
  Future<AppUser> loginWithKakao() async {
    // 1. 카카오 SDK로 access token 획득
    //    KakaoTalk 앱이 설치된 경우 앱 로그인, 없으면 웹 로그인으로 폴백.
    OAuthToken oauthToken;
    try {
      if (await isKakaoTalkInstalled()) {
        oauthToken = await UserApi.instance.loginWithKakaoTalk();
      } else {
        oauthToken = await UserApi.instance.loginWithKakaoAccount();
      }
    } catch (_) {
      // KakaoTalk 로그인 실패 시 웹 계정 로그인으로 재시도
      oauthToken = await UserApi.instance.loginWithKakaoAccount();
    }

    // 2. 카카오 access token을 우리 서버로 전달 → 자체 JWT 발급
    final json = await NaengoApi.socialLoginKakao(oauthToken.accessToken);

    // 3. JWT in-memory 저장 및 사용자 정보 설정
    _token = json['access_token'] as String;

    _user = AppUser.fromJson({
      'user_id': json['user_id'],
      'nickname': json['nickname'],
      'role': json['role'] ?? 'USER',
      'is_active': true,
    });

    // 4. 프로필 로드 (실패해도 로그인은 유지)
    try {
      _userInput = await NaengoApi.getProfileInput();
    } catch (_) {
      _userInput = [];
    }

    return _user!;
  }

  // ── 이메일/비밀번호 로그인 (UI 없음, 확장 대비) ──────────

  @override
  Future<AppUser> login(String email, String password) async {
    throw UnimplementedError('이메일/비밀번호 로그인은 현재 지원하지 않습니다.');
  }

  @override
  Future<AppUser> signup(String email, String password, String nickname) async {
    throw UnimplementedError('이메일/비밀번호 회원가입은 현재 지원하지 않습니다.');
  }

  // ── 데이터 로드/수정 ────────────────────────────────────

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
    final toDelete = _userInput.where((s) => !inputs.contains(s)).toList();
    final toAdd = inputs.where((s) => !_userInput.contains(s)).toList();
    for (final text in toDelete) {
      await NaengoApi.deleteProfileInput(text);
    }
    for (final text in toAdd) {
      await NaengoApi.appendProfileInput(text);
    }
    _userInput = await NaengoApi.getProfileInput();
  }

  // ── 로그아웃 ────────────────────────────────────────────

  @override
  Future<void> logout() async {
    await NaengoApi.postLogout(); // 서버에 로그아웃 알림 (멱등)
    _user = null;
    _token = null;
    _userInput = [];
  }
}

// ─────────────────────────────────────────────────────────
// Mock 구현 — 실제 서버 없이 UI 개발/테스트 용
// ─────────────────────────────────────────────────────────

class MockAuthService implements AuthService {
  bool _loggedIn = false;

  @override
  AppUser get currentUser => MockDataService.currentUser;

  @override
  UserProfile get currentProfile => MockDataService.currentProfile;

  @override
  bool get isLoggedIn => _loggedIn;

  @override
  String? get token => null;

  @override
  Future<AppUser> loginWithKakao() async {
    _loggedIn = true;
    return MockDataService.currentUser;
  }

  @override
  Future<AppUser> login(String email, String password) async {
    _loggedIn = true;
    return MockDataService.currentUser;
  }

  @override
  Future<AppUser> signup(String email, String password, String nickname) async =>
      MockDataService.currentUser;

  @override
  Future<void> load() async {}

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
