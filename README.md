
# 냉고 (fridge_expert) — Flutter 앱

냉장고 속 재료를 기반으로 레시피를 추천하고, AI와의 채팅을 통해 요리 조언을 받을 수 있는 Flutter 기반 크로스플랫폼 모바일 앱입니다.

## 📋 사전 요구사항
- Flutter SDK (^3.9.0)
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
├── web/                      # 웹 빌드 설정
├── lib/
│   ├── core/                 # 앱 공통 export 및 유틸리티
│   │   ├── app_export.dart   # 전역 export 모음
│   │   └── utils/            # size_utils, image_constant
│   ├── data/
│   │   └── mock_data_service.dart   # 백엔드 연결 전 테스트용 목 데이터 서비스
│   ├── models/               # 데이터 모델 (DB 스키마 기준)
│   │   ├── chat_message.dart # 채팅 메시지
│   │   ├── chat_room.dart    # 채팅방 (Chat_Rooms)
│   │   ├── recipe_item.dart  # 레시피 (Recipes + Recipe_Stats)
│   │   └── user.dart         # 사용자 (Users)
│   ├── presentation/         # UI 화면
│   │   ├── app_navigation_screen/       # 네비게이션 확인용 디버그 화면
│   │   ├── main_shell/                  # 메인 Shell (추천/게시판 + 사이드 패널 관리)
│   │   ├── recipe_recommendation_screen/# 홈 화면 (추천/새 채팅)
│   │   ├── chat_interface_screen/       # AI 채팅방 화면
│   │   ├── recipe_management_screen/    # 왼쪽 사이드 패널 (메뉴 + 채팅 기록)
│   │   ├── recipe_board_screen/         # 레시피 게시판
│   │   └── recipe_detail_screen/        # 레시피 상세 보기
│   ├── routes/               # 라우팅 (app_routes.dart)
│   ├── services/             # API 서비스 (api_service.dart)
│   ├── theme/                # 테마 (theme_helper, text_style_helper)
│   ├── widgets/              # 재사용 UI 컴포넌트 (app bar, chat bubble, input field 등)
│   └── main.dart             # 앱 진입점
├── assets/
│   ├── fonts/                # Inter, Urbanist, NotoSansKR, Tmoney RoundWind, NanumSquare_ac
│   └── images/               # SVG / PNG 아이콘
├── env.json                  # 환경 변수
├── pubspec.yaml              # 프로젝트 의존성
└── README.md
```

## 🧩 라우트 구성 (`lib/routes/app_routes.dart`)
| 경로                              | 화면                        | 설명                                                    |
|-----------------------------------|-----------------------------|---------------------------------------------------------|
| `/` (`initialRoute`)              | `MainShell`                 | 홈 추천 + 게시판을 탭처럼 전환하는 메인 컨테이너        |
| `/recipe_recommendation_screen`   | `RecipeRecommendationScreen`| 레시피 추천 / 새 채팅 시작 화면                         |
| `/chat_interface_screen`          | `ChatInterfaceScreen`       | AI 채팅방 (아래 → 위 슬라이드 전환 적용)                |
| `/recipe_management_screen`       | `RecipeManagementScreen`    | 왼쪽 사이드 패널 (메뉴 + 내 채팅 기록)                  |
| `/recipe_board_screen`            | `RecipeBoardScreen`         | 레시피 게시판                                           |

라우트 추가 방법:
```dart
static const String newScreen = '/new_screen';

static Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case newScreen:
      return MaterialPageRoute(builder: (_) => const NewScreen());
    // ...
  }
}
```

## 🎨 테마
`ThemeHelper()` 로 라이트/다크 테마와 색상, `TextStyleHelper`로 텍스트 스타일을 일관되게 관리합니다.

```dart
// 테마 / 색상
ThemeData theme = ThemeHelper().themeData();
color: theme.colorScheme.primary,

// 텍스트 스타일
Text('안녕하세요', style: TextStyleHelper.instance.title16);
```

## 📱 반응형 디자인
`SizeUtils`의 `.h` / `.fSize` 확장자로 화면 크기에 맞게 자동 조절됩니다.
```dart
Container(
  width: 50.h,
  height: 20.h,
  child: Text('반응형 컨테이너', style: TextStyle(fontSize: 14.fSize)),
)
```

## 📦 배포
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

---

## 📱 구현된 프론트엔드 화면

### 1. 메인 Shell (`main_shell`)
- 홈(추천)과 게시판을 상태값으로 전환하는 컨테이너
- 왼쪽 사이드 패널(`RecipeManagementScreen`) 슬라이드 인/아웃 애니메이션 관리
- 배경 오버레이 페이드 + 배경 탭으로 패널 닫기

### 2. 홈 / 추천 화면 (`recipe_recommendation_screen`)
- 상단 앱바: 햄버거 메뉴(사이드 패널 열기) + "새 채팅" 제목 + 프로필 아이콘
- 인사말 영역: "안녕하세요, 냉고입니다." / "오늘 뭐 해먹을까요?"
- 새 레시피 추천 카드 가로 스크롤 섹션
- 하단 통합 pill형 채팅 입력창 (카메라 + 텍스트 필드 + 종이비행기 전송 버튼)
- 입력 시 새 `ChatRoom` 생성 → 채팅방으로 이동

### 3. 채팅방 (`chat_interface_screen`)
- 상단 앱바: 햄버거 메뉴 + 채팅방 제목 + 프로필 아이콘
- AI / 유저 채팅 말풍선 (좌우 구분, AI 아바타 표시)
- 로딩 중 애니메이션 버블 ("답변 생성 중...")
- 하단 통합 pill형 입력창
- `roomId` 단위로 메시지 저장 (`MockDataService.roomMessages`) → 채팅 기록 유지
- Claude API 연결 (`factchat-cloud.mindlogic.ai`)

### 4. 사이드 패널 (`recipe_management_screen`)
- 햄버거 메뉴 클릭 시 왼쪽에서 슬라이드 인 / `<` 버튼 또는 배경 탭으로 닫기
- 메뉴 항목: 새 채팅, 레시피 게시판, 레시피 작성하기
- 내 채팅 ∨/∧ 접기/펼치기 → 최근 채팅방 목록 표시 (클릭 시 해당 방으로 이동)
- 얇은 유튜브 스타일 스크롤바

### 5. 레시피 게시판 (`recipe_board_screen`)
- 사용자/표준 레시피 목록 표시
- 레시피 카드에 좋아요 개수(`likesCount`), 스크랩 개수(`scrapCount`) 노출
- `ValueNotifier` 기반 좋아요 실시간 반영 (`MockDataService.likesNotifier`)

### 6. 레시피 상세 (`recipe_detail_screen`)
- 이미지, 설명, 재료 목록, 조리 과정 단계별 표시
- 좋아요 / 스크랩 토글 → 카드/게시판에 즉시 반영

---

## 🗄️ 데이터 계층

### 모델 (`lib/models/`)
DB정리 스키마를 기준으로 프론트 모델을 정의합니다.

| 모델          | 주요 필드                                                                 |
|---------------|---------------------------------------------------------------------------|
| `AppUser`     | `userId`, `email`, `nickname`, `role`, `provider`, `createdAt`            |
| `ChatRoom`    | `roomId`, `userId`, `title`, `isActive`, `createdAt`, `updatedAt`         |
| `ChatMessage` | `text`, `isMe`, `sentAt`                                                  |
| `RecipeItem`  | `recipeId`, `title`, `ingredientsList`, `cookingSteps`, `likesCount`, `scrapCount`, `isLiked`, `isBookmarked` 등 |

### 목 데이터 서비스 (`lib/data/mock_data_service.dart`)
백엔드 연결 전까지 사용하는 인메모리 저장소입니다.
- `currentUser` — 현재 로그인 사용자
- `chatRooms`, `roomMessages` — 채팅방 목록과 방별 메시지
- `createRoom()`, `updateRoomTitle()`, `removeRoom()`, `addMessage()` — CRUD 헬퍼
- `likesNotifier` — 좋아요 변경 알림 (`ValueNotifier<int>`)

---

## 🔌 서비스 / API

- `lib/services/api_service.dart` — AI 채팅 API (`factchat-cloud.mindlogic.ai`) 호출
- `env.json` — API 키 / 엔드포인트 등 환경 변수
- HTTP 통신: `http` 패키지

---

## ✨ 최근 작업 내역

| 커밋                             | 내용                                                              |
|----------------------------------|-------------------------------------------------------------------|
| `feat: 좋아요 개수, 버그 수정`   | 레시피 카드/상세 좋아요 개수 표시, `likesNotifier`로 즉시 반영, 게시판/관리 화면 버그 수정 |
| `feat: 채팅 기록, 버그 수정`     | `ChatRoom`/`ChatMessage`/`AppUser` 모델 추가, `MockDataService`로 방별 기록 관리, 사이드 패널에서 이전 채팅 복귀 지원 |
| `Initial clean commit`           | 초기 스캐폴드 (홈/채팅/사이드 패널/게시판/상세 화면, 테마, 라우팅, 위젯 등) |

---

## 📦 주요 의존성 (`pubspec.yaml`)
- `flutter_svg` ^2.0.12 — SVG 아이콘
- `cached_network_image` ^3.4.1 — 네트워크 이미지 캐싱
- `shared_preferences` ^2.3.3 — 로컬 저장소
- `connectivity_plus` ^6.1.0 — 네트워크 상태
- `gradient_borders` ^1.0.2 — 그라디언트 테두리
- `http` ^1.6.0 — HTTP 통신
- `universal_html` ^2.2.4 — 웹 호환

등록 폰트: Urbanist, Inter, Noto Sans KR, Tmoney RoundWind, NanumSquare ac
