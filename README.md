
# 냉고 (fridge_expert) — Flutter 앱

최신 모바일 개발 기술과 도구를 활용한 현대적인 Flutter 기반 모바일 앱으로, 크로스플랫폼 반응형 애플리케이션을 구축합니다.
## 📋 사전 요구사항
- Flutter SDK (^3.29.2)
- Dart SDK
- Android Studio / VS Code (Flutter 확장 포함)
- Android SDK / Xcode (iOS 개발 시)

## 🛠️ 설치 방법

1. 의존성 설치:
```bash
flutter pub get
```

2. 앱 실행:
```bash
flutter run
```

## 📁 프로젝트 구조
```
fridge_expert/
├── android/                  # Android 전용 설정
├── ios/                      # iOS 전용 설정
├── lib/
│   ├── core/                 # 핵심 유틸리티 및 서비스
│   │   └── utils/            # 유틸리티 클래스 (size_utils, image_constant)
│   ├── presentation/         # UI 화면 및 위젯
│   │   ├── chat_interface_screen/         # 채팅방 화면
│   │   ├── recipe_management_screen/      # 사이드 패널 (메뉴)
│   │   └── recipe_recommendation_screen/  # 첫화면 (홈)
│   ├── routes/               # 앱 라우팅
│   ├── services/             # API 서비스
│   ├── theme/                # 테마 설정 (색상, 폰트)
│   ├── widgets/              # 재사용 가능한 UI 컴포넌트
│   └── main.dart             # 앱 진입점
├── assets/                   # 이미지, 폰트 등 정적 리소스
├── pubspec.yaml              # 프로젝트 의존성 및 설정
└── README.md                 # 프로젝트 문서
```

## 🧩 라우트 추가 방법
새 라우트는 `lib/routes/app_routes.dart` 파일에서 추가하세요:

```dart
import 'package:flutter/material.dart';

class AppRoutes {
  static const String initial = '/';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    // 필요에 따라 라우트 추가
  }
}
```

## 🎨 테마
라이트/다크 테마를 포함한 종합 테마 시스템이 내장되어 있습니다:

```dart
// 현재 테마 접근
ThemeData get theme => ThemeHelper().themeData();

// 색상 사용
color: theme.colorScheme.primary,
```

## 📱 반응형 디자인
`SizeUtils`의 `.h` / `.fSize` 확장자를 통해 화면 크기에 맞게 자동 조절됩니다:

```dart
Container(
  width: 50.h,
  height: 20.h,
  child: Text('반응형 컨테이너'),
)
```

## 📦 배포
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 🙏 출처
- [Rocket.new](https://rocket.new) 으로 제작
- [Flutter](https://flutter.dev) & [Dart](https://dart.dev) 기반
- Material Design 스타일 적용

---

## 📱 구현된 프론트엔드 화면

### 1. 첫화면 (`recipe_recommendation_screen`)
- 상단 앱바: 햄버거 메뉴(사이드 패널 열기) + "새 채팅" 제목 + 프로필 아이콘
- 인사말 영역: "안녕하세요, 냉고입니다." + "오늘 뭐 해먹을까요?"
- 새 레시피 추천 카드 가로 스크롤 섹션
- 하단 통합 pill형 채팅 입력창 (카메라 버튼 + 텍스트 필드 + 종이비행기 전송 버튼)

### 2. 채팅방 (`chat_interface_screen`)
- 상단 앱바: 햄버거 메뉴 + "채팅방 이름1" + 프로필 아이콘
- AI / 유저 채팅 말풍선 (좌우 구분, AI는 'AI' 아바타 표시)
- 로딩 중 애니메이션 버블 ("답변 생성 중...")
- 하단 통합 pill형 입력창
- Claude API 연결 (`factchat-cloud.mindlogic.ai`)

### 3. 사이드 패널 (`recipe_management_screen`)
- 햄버거 메뉴 클릭 시 왼쪽에서 슬라이드 인 / `<` 버튼으로 닫기
- 배경 탭으로도 패널 닫기 가능
- 메뉴 항목: 새 채팅, 레시피 게시판, 레시피 작성하기
- 내 채팅 ∨/∧ 접기/펼치기 (현재 채팅방 + 이전 채팅 기록)
- 얇은 유튜브 스타일 스크롤바

---

## ⚠️ 누락된 폰트 (수동 추가 필요)
아래 폰트 파일을 `assets/fonts/` 폴더에 직접 추가 후 `pubspec.yaml`에 등록해야 정상 적용됩니다:

```
TmoneyRoundWindExtraBold.ttf
TmoneyRoundWindRegular.ttf
NanumSquareacB.ttf
NanumSquareacEB.ttf
NanumSquareacR.ttf
```