# 냉고 (fridge_expert) — Flutter 앱

냉장고 속 재료를 기반으로 레시피를 추천하고, AI 와의 채팅을 통해 요리 조언을 받을 수 있는 Flutter 기반 크로스플랫폼 모바일 앱입니다.

지금은 팀이 자체 운영하는 **Naengo 백엔드**(SSE 스트리밍 + 멀티모달 채팅 + 벡터 레시피 검색) 와 연결돼 있습니다.

---

## 📋 사전 요구사항
- Flutter SDK (^3.9.0)
- Dart SDK
- Android Studio / VS Code (Flutter 확장 포함)
- Android SDK / Xcode (iOS 개발 시)

## 🛠️ 설치 및 실행

```bash
flutter pub get
flutter run
```

### 백엔드 주소 변경 (선택)
기본은 `http://43.201.62.254:8000` 입니다. 다른 주소로 빌드하려면 `--dart-define` 으로 주입:

```bash
flutter run --dart-define=NAENGO_API_BASE=http://your-server:8000
```

### Android cleartext HTTP
백엔드가 평문 HTTP 라 Android 9+ 에선 기본 차단입니다. `android/app/src/main/AndroidManifest.xml` 의 `<application>` 태그에 다음 속성이 있어야 합니다:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

배포 직전엔 백엔드를 HTTPS 로 전환하고 이 속성을 제거하는 걸 권장합니다.

---

## 📁 프로젝트 구조

```
fridge_expert/
├── android/                  # Android 전용 설정
├── ios/                      # iOS 전용 설정
├── web/                      # 웹 빌드 설정
├── lib/
│   ├── core/                 # 앱 공통 export 및 유틸리티
│   ├── data/
│   │   └── mock_data_service.dart   # 채팅방/메시지 인메모리 저장소
│   ├── models/
│   │   ├── chat_message.dart # text(mutable), imagePath, recipes, isStreaming
│   │   ├── chat_room.dart    # 로컬 roomId + 백엔드 serverRoomId
│   │   ├── recipe.dart       # 백엔드 RecipeResponse (Naengo API 응답)
│   │   ├── recipe_item.dart  # 로컬/UI 레시피 (게시판/목 데이터용)
│   │   └── user.dart
│   ├── presentation/
│   │   ├── main_shell/                  # 메인 Shell (홈/게시판 + 사이드 패널)
│   │   ├── recipe_recommendation_screen/# 홈 (인사말 + 추천 카드 + 입력창)
│   │   ├── chat_interface_screen/       # AI 채팅방 (SSE 스트리밍 + 이미지)
│   │   ├── recipe_management_screen/    # 왼쪽 사이드 패널 (메뉴 + 채팅 기록)
│   │   ├── recipe_board_screen/         # 레시피 게시판
│   │   └── recipe_detail_screen/        # 레시피 상세
│   ├── routes/               # app_routes.dart
│   ├── services/
│   │   ├── camera_service.dart        # image_picker 래퍼
│   │   └── naengo_api_service.dart    # ⭐ Naengo 백엔드 SSE 클라이언트
│   ├── theme/                # theme_helper, text_style_helper
│   ├── widgets/              # 재사용 UI 컴포넌트
│   └── main.dart
├── assets/
│   ├── fonts/                # Inter, Urbanist, NotoSansKR, Tmoney RoundWind, NanumSquare_ac
│   └── images/               # SVG / PNG 아이콘
├── pubspec.yaml
└── README.md
```

---

## 🔌 백엔드 연결 (Naengo API)

자체 운영 FastAPI 서버 (`/api/v1/...`) 와 통신. 핵심 엔드포인트:

| 메서드 | 경로 | 설명 |
|---|---|---|
| `POST` | `/api/v1/chat/rooms` | 새 방 + 첫 메시지 — SSE 스트림 |
| `POST` | `/api/v1/chat/rooms/{room_id}` | 기존 방 메시지 — SSE 스트림 |
| `GET`  | `/api/v1/chat/rooms` | 채팅방 목록 |
| `GET`  | `/api/v1/chat/rooms/{room_id}` | 메시지 내역 |
| `GET`  | `/api/v1/recipes?ids=...` | 레시피 ID 로 조회 |

### 요청 형식

```json
{
  "prompt": "김치랑 두부 있는데 뭐 만들 수 있어?",
  "image": "data:image/jpeg;base64,..."   // 선택 — 멀티모달
}
```

### SSE 응답 이벤트

```
event: room
data: {"room_id": 1}            ← 첫 메시지에서만 (room_id 부여)

event: message
data: {"content": "김치"}        ← AI 응답 청크 N개

event: message
data: {"content": "와 두부로..."}

event: recipes
data: [RecipeResponse, ...]      ← 답변 완료 후 추천 레시피
```

`NaengoApi` (in `naengo_api_service.dart`) 가 위 스트림을 파싱해 `Stream<ChatEvent>` 로 yield 합니다:
- `RoomCreated(roomId)`
- `MessageChunk(content)`
- `RecipesReceived(recipes)`
- `ChatStreamError(message)` — 네트워크/파싱 오류

---

## 📱 구현된 화면

### 1. 메인 Shell (`main_shell`)
홈(추천)과 게시판을 상태값으로 전환. 왼쪽 사이드 패널 슬라이드 + 배경 오버레이 페이드.

### 2. 홈 / 추천 화면 (`recipe_recommendation_screen`)
- 인사말 + 추천 카드 가로 스크롤
- 하단 pill 형 입력창 (📷 + 텍스트 + 종이비행기)
- **카메라 버튼** → 촬영 → 미리보기(브랜드 톤 다이얼로그) → 채팅방 진입(이미지 자동 첫 메시지)
- 텍스트 입력 → 새 채팅방 생성 후 진입

### 3. 채팅방 (`chat_interface_screen`) ⭐
- **SSE 스트리밍** — AI 응답이 청크 단위로 실시간 누적
- **이미지 메시지** — 사용자 버블에 사진 표시, 탭하면 핀치 줌 전체화면
- **레시피 칩** — AI 응답 아래 추천 레시피 가로 스크롤 (빨강 외곽선)
- **`serverRoomId` 영속** — 같은 방 재진입 시 백엔드 컨텍스트 유지
- **카메라** — 입력창 캡션과 함께 이미지를 base64 data URL 로 백엔드에 전송
- 로딩 인디케이터 ("답변 생성 중…") → 첫 청크 도착 시 자연 전환

### 4. 사이드 패널 (`recipe_management_screen`)
햄버거 → 슬라이드 인. 메뉴(새 채팅, 게시판, 작성) + 내 채팅 ∨/∧ 접기/펼치기. ListView 로 스크롤, 유튜브 스타일 얇은 스크롤바.

### 5. 게시판 (`recipe_board_screen`)
사용자/표준 레시피 카드 목록. 좋아요/스크랩 카운트 표시, `ValueNotifier` 로 즉시 반영.

### 6. 상세 (`recipe_detail_screen`)
이미지, 설명, 재료, 조리 순서. 좋아요/스크랩 토글 → 카드/게시판에 즉시 반영.

---

## 🗄️ 데이터 모델

| 모델 | 주요 필드 | 비고 |
|---|---|---|
| `AppUser` | `userId`, `email`, `nickname`, `role` | 로그인 사용자 |
| `ChatRoom` | `roomId`, `serverRoomId`, `title`, `createdAt`, `updatedAt` | 백엔드 정수 ID 보존 |
| `ChatMessage` | `text` *(mutable)*, `isMe`, `imagePath`, `recipes`, `isStreaming` | SSE 청크 누적용 |
| `Recipe` | `id`, `title`, `ingredients`, `instructions`, `tags`, `videoUrl`, … | 백엔드 RecipeResponse 매핑 |
| `IngredientItem` | `name`, `amount`, `unit`, `type`, `note` | Recipe 안의 재료 |
| `RecipeItem` | `recipeId`, `likesCount`, `scrapCount`, `isLiked`, `isBookmarked` | 로컬 UI 용 (게시판/목 데이터) |

### `MockDataService` (`lib/data/`)
백엔드 동기화 전까지 쓰는 인메모리 저장소.
- `chatRooms`, `roomMessages` — 방 목록과 방별 메시지
- `createRoom()`, `updateRoomTitle()`, `updateServerRoomId()`, `addMessage()`
- `likesNotifier` — 좋아요 변경 알림

> ⚠️ 앱 재시작하면 휘발됩니다. 추후 SharedPreferences/DB 영속화 필요.

---

## 🎨 테마 / 반응형

```dart
// 색상
ThemeData theme = ThemeHelper().themeData();
color: theme.colorScheme.primary,

// 텍스트
Text('안녕하세요', style: TextStyleHelper.instance.title16);

// 반응형 (.h, .fSize)
Container(
  width: 50.h,
  height: 20.h,
  child: Text('hi', style: TextStyle(fontSize: 14.fSize)),
)
```

브랜드 컬러: `#FF5252` (빨강) / 배경 틴트: `#FFECEC`, `#FFF8F8`

---

## 📦 배포

```bash
flutter build apk --release          # Android
flutter build ios --release          # iOS
flutter build web --release          # Web
```

---

## ✨ 최근 작업 내역

| 시점 | 변경 | 파일 |
|---|---|---|
| 최근 | **채팅방 진짜 삭제** — 백엔드에 `DELETE /chat/rooms/{id}` 추가됨 → 호출 후 로컬 캐시 제거. 실패 시 롤백 + SnackBar. 임시 우회용 `hiddenServerRoomIds` 제거 | `naengo_api_service.dart`, `recipe_management_screen.dart`, `mock_data_service.dart` |
| 최근 | **백엔드 동기화** — 사이드 패널 = `GET /chat/rooms` 로 목록 fetch (자동 + 로딩 인디케이터), 채팅방 진입 = `GET /chat/rooms/{id}` 로 메시지 내역 복원 | `naengo_api_service.dart`, `recipe_management_screen.dart`, `chat_interface_screen.dart`, `mock_data_service.dart` |
| 최근 | **API 갈아끼우기** — MindLogic FactChat → Naengo 백엔드, SSE 스트리밍, 멀티모달 (image base64), 레시피 칩 | `naengo_api_service.dart`, `chat_interface_screen.dart`, `recipe.dart` |
| 최근 | **빈 placeholder 제거** — 첫 청크 도착 전엔 "답변 생성 중…" 만 보이도록 | `chat_interface_screen.dart` |
| 최근 | **카메라 흐름 정리** — 홈/채팅 양쪽 카메라 버튼 → 미리보기 다이얼로그(브랜드 톤) → 백엔드로 이미지 전송 | `recipe_recommendation_screen.dart`, `chat_interface_screen.dart`, `camera_service.dart` |
| 최근 | **사이드 패널 스크롤 + 토글 복구** — 채팅방 많을 때 overflow 해결, ∨/∧ 토글 유지 | `recipe_management_screen.dart` |
| 최근 | **클린업** — Vision API 의존성 제거 (`googleapis`, `googleapis_auth`), `vision_service.dart`, `ingredient_translator.dart`, 서비스 계정 키, 구 `api_service.dart` (×2) 삭제, 로컬 `camera-vision` 브랜치 정리 | — |
| `feat: 좋아요 개수, 버그 수정` | 레시피 카드/상세 좋아요 표시, `likesNotifier` 즉시 반영 | — |
| `feat: 채팅 기록, 버그 수정` | `ChatRoom`/`ChatMessage`/`AppUser` 모델, 사이드 패널 채팅 복귀 | — |
| `Initial clean commit` | 초기 스캐폴드 (화면 / 테마 / 라우팅 / 위젯) | — |

---

## 📦 주요 의존성 (`pubspec.yaml`)

- `flutter_svg` ^2.0.12 — SVG 아이콘
- `cached_network_image` ^3.4.1 — 네트워크 이미지 캐싱
- `shared_preferences` ^2.3.3 — 로컬 저장소
- `connectivity_plus` ^6.1.0 — 네트워크 상태
- `gradient_borders` ^1.0.2 — 그라디언트 테두리
- `http` ^1.6.0 — SSE 스트리밍 (`http.Client.send`)
- `image_picker` ^1.1.2 — 카메라 / 갤러리 접근
- `universal_html` ^2.2.4 — 웹 호환

폰트: Urbanist, Inter, Noto Sans KR, Tmoney RoundWind, NanumSquare ac

---

## 🚧 미진행 / 다음 단계

- **레시피 칩 → 상세** — 칩 탭 시 `RecipeDetailScreen` 으로 이동 (현재 비활성)
- **`serverRoomId` 디스크 영속화** — `SharedPreferences` 등에 저장해 앱 재시작 후에도 같은 방 유지
- **인증 / 사용자 식별** — 백엔드가 현재 `user_id = 1` 고정. 추후 OAuth 등 도입 시 헤더 추가
- **HTTPS 전환** — 평문 HTTP cleartext 예외 제거
- **에러 UX** — 타임아웃 / 재시도 / 오프라인 표시
- **이미지 메시지 영속화** — 현재 백엔드는 텍스트 `content` 만 저장 → 과거에 보낸 사진은 history 복원 시 사라짐. 백엔드에 image_url 컬럼 추가 후 매핑 가능
