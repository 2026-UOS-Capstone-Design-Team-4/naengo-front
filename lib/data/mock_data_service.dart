import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/recipe_item.dart';
import '../models/user.dart';

/// 백엔드 연결 전 테스트용 목 데이터.
/// DB정리.md 스키마를 기준으로 작성됨.
class MockDataService {
  MockDataService._();

  // ──────────────────────────────────────────────
  // 현재 로그인된 사용자 (Users 테이블)
  // ──────────────────────────────────────────────
  static final AppUser currentUser = AppUser(
    userId: 1,
    email: 'test@naengo.com',
    nickname: '냉장고지기',
    role: 'USER',
    provider: 'LOCAL',
    createdAt: DateTime(2025, 1, 10),
  );

  // ──────────────────────────────────────────────
  // 채팅방 목록 (Chat_Rooms 테이블) - 변경 가능한 목록
  // ──────────────────────────────────────────────
  static List<ChatRoom> chatRooms = [
    
  ];

  /// 새 채팅방 생성 (목록 맨 앞에 추가)
  static ChatRoom createRoom() {
    final room = ChatRoom(
      roomId: 'room-${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUser.userId,
      title: '새로운 레시피',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    chatRooms.insert(0, room);
    return room;
  }

  /// 채팅방 제목 업데이트
  static void updateRoomTitle(String roomId, String title) {
    final index = chatRooms.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      chatRooms[index] = chatRooms[index].copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// 채팅방 삭제 (메시지도 함께 삭제)
  static void removeRoom(String roomId) {
    chatRooms.removeWhere((r) => r.roomId == roomId);
    roomMessages.remove(roomId);
  }

  // ──────────────────────────────────────────────
  // 채팅 메시지 (Session_Logs.chat_messages 대응)
  // roomId → 메시지 목록
  // ──────────────────────────────────────────────
  static final Map<String, List<ChatMessage>> roomMessages = {};

  /// 방의 메시지 목록 반환 (없으면 생성 후 반환 — 항상 동일 참조 보장)
  static List<ChatMessage> getMessages(String roomId) {
    roomMessages.putIfAbsent(roomId, () => []);
    return roomMessages[roomId]!;
  }

  /// 메시지 추가
  static void addMessage(String roomId, ChatMessage message) {
    roomMessages.putIfAbsent(roomId, () => []);
    roomMessages[roomId]!.add(message);
  }

  // ──────────────────────────────────────────────
  // 레시피 목록 (Recipes + Recipe_Stats + Likes + Scraps 조합)
  // ──────────────────────────────────────────────
  static final List<RecipeItem> recipes = [
    RecipeItem(
      recipeId: 1,
      title: '에그 베네딕트',
      description: '클래식 브런치의 대표 메뉴! 촉촉한 수란과 진한 홀란다이즈 소스가 잘 구워진 잉글리시 머핀 위에 어우러진 레시피입니다.',
      ingredientsRaw: '계란, 잉글리시 머핀, 캐나다 베이컨, 홀란다이즈 소스',
      ingredientsList: [
        '계란 2개',
        '잉글리시 머핀 1개',
        '캐나다 베이컨 2장',
        '홀란다이즈 소스 3큰술',
        '버터 적당량',
        '식초 1큰술',
        '소금, 후추 약간',
      ],
      cookingSteps: [
        '냄비에 물을 넉넉히 붓고 식초를 넣어 끓입니다.',
        '소용돌이를 만든 뒤 계란을 깨서 넣어 3분간 익힙니다.',
        '잉글리시 머핀을 버터 발라 토스터에 굽습니다.',
        '캐나다 베이컨을 프라이팬에 살짝 굽습니다.',
        '머핀 위에 베이컨, 수란 순으로 올리고 홀란다이즈 소스를 뿌립니다.',
      ],
      source: 'STANDARD',
      status: 'APPROVED',
      createdAt: DateTime(2025, 4, 10),
      likesCount: 42,
      scrapCount: 18,
      isLiked: true,
      isBookmarked: true,
    ),
    RecipeItem(
      recipeId: 2,
      title: '소세지강정',
      description: '바삭하게 튀긴 소세지에 달콤 짭조름한 강정 소스를 입힌 인기 반찬입니다.',
      ingredientsRaw: '소세지, 간장, 고추장, 올리고당, 통깨',
      ingredientsList: [
        '소세지 200g',
        '간장 2큰술',
        '고추장 1큰술',
        '올리고당 3큰술',
        '다진 마늘 1큰술',
        '통깨 약간',
        '식용유 적당량',
      ],
      cookingSteps: [
        '소세지를 어슷하게 칼집을 내어 한입 크기로 자릅니다.',
        '170°C 기름에 바삭하게 튀겨냅니다.',
        '간장, 고추장, 올리고당, 다진 마늘로 소스를 만듭니다.',
        '팬에 소스를 끓이다가 튀긴 소세지를 넣어 버무립니다.',
        '통깨를 뿌려 완성합니다.',
      ],
      source: 'STANDARD',
      status: 'APPROVED',
      createdAt: DateTime(2025, 4, 9),
      likesCount: 28,
      scrapCount: 9,
    ),
    RecipeItem(
      recipeId: 3,
      title: '간장버터계란밥',
      description: '따뜻한 밥 위에 버터와 간장, 계란 노른자가 어우러진 고소하고 감칠맛 나는 계란밥입니다.',
      ingredientsRaw: '밥, 계란, 버터, 간장, 참기름, 통깨',
      ingredientsList: [
        '밥 1공기',
        '계란 1개',
        '버터 1/2큰술',
        '간장 1.5큰술',
        '참기름 1/2큰술',
        '통깨 약간',
      ],
      cookingSteps: [
        '따뜻한 밥을 그릇에 담습니다.',
        '계란 노른자와 흰자를 밥 위에 올립니다.',
        '버터를 밥 위에 올려 살살 녹입니다.',
        '간장을 골고루 뿌리고 참기름을 살짝 둘러줍니다.',
        '통깨를 뿌리고 비벼서 먹습니다.',
      ],
      source: 'USER',
      authorId: 2,
      status: 'APPROVED',
      createdAt: DateTime(2025, 4, 8),
      likesCount: 35,
      scrapCount: 12,
      isLiked: true,
      isBookmarked: true,
    ),
    RecipeItem(
      recipeId: 4,
      title: '새송이버섯볶음',
      description: '쫄깃한 새송이버섯을 버터에 볶아 감칠맛을 살린 반찬입니다.',
      ingredientsRaw: '새송이버섯, 버터, 진간장, 굴소스, 통깨',
      ingredientsList: [
        '새송이버섯 200g',
        '버터 1큰술',
        '다진 마늘 1큰술',
        '진간장 1큰술',
        '굴소스 1/2큰술',
        '참기름 1/2큰술',
        '통깨 약간',
      ],
      cookingSteps: [
        '새송이버섯을 먹기 좋은 크기로 찢거나 썹니다.',
        '버터를 녹인 후 마늘을 볶아 향을 냅니다.',
        '버섯을 넣고 중강불에서 노릇하게 볶습니다.',
        '진간장과 굴소스를 넣고 잘 섞어줍니다.',
        '불을 끄고 참기름, 통깨를 뿌려 마무리합니다.',
      ],
      source: 'STANDARD',
      status: 'APPROVED',
      createdAt: DateTime(2025, 4, 7),
      likesCount: 15,
      scrapCount: 5,
    ),
    RecipeItem(
      recipeId: 5,
      title: '참치마요덮밥',
      description: '냉장고 속 재료로 5분 만에 완성하는 간편 덮밥입니다.',
      ingredientsRaw: '참치캔, 마요네즈, 간장, 밥, 양파, 오이',
      ingredientsList: [
        '참치캔 1개 (150g)',
        '마요네즈 2큰술',
        '간장 1큰술',
        '밥 1공기',
        '양파 1/4개',
        '오이 1/4개',
        '소금, 후추 약간',
      ],
      cookingSteps: [
        '참치캔의 기름을 빼고 그릇에 담습니다.',
        '마요네즈, 간장, 소금, 후추를 넣고 섞어 참치마요를 만듭니다.',
        '양파와 오이를 잘게 다져 섞습니다.',
        '따뜻한 밥 위에 참치마요를 올립니다.',
        '기호에 따라 깻잎이나 김 가루를 올려 완성합니다.',
      ],
      source: 'USER',
      authorId: 3,
      status: 'APPROVED',
      createdAt: DateTime(2025, 4, 6),
      likesCount: 9,
      scrapCount: 3,
    ),
    RecipeItem(
      recipeId: 6,
      title: '된장찌개',
      description: '두부, 애호박, 버섯이 들어간 구수하고 깊은 맛의 된장찌개입니다.',
      ingredientsRaw: '된장, 두부, 애호박, 느타리버섯, 대파, 양파, 다시마육수',
      ingredientsList: [
        '된장 2큰술',
        '두부 1/2모',
        '애호박 1/4개',
        '느타리버섯 50g',
        '대파 1/2대',
        '양파 1/4개',
        '다시마육수 또는 물 2컵',
        '다진 마늘 1/2큰술',
        '고춧가루 1/2큰술 (선택)',
      ],
      cookingSteps: [
        '냄비에 육수를 붓고 된장을 풀어줍니다.',
        '양파와 마늘을 넣고 중불에서 끓입니다.',
        '애호박과 버섯을 넣고 5분간 더 끓입니다.',
        '두부를 깍둑썰기하여 넣습니다.',
        '대파를 넣고 한소끔 더 끓인 후 마무리합니다.',
      ],
      source: 'STANDARD',
      status: 'APPROVED',
      createdAt: DateTime(2025, 4, 5),
      likesCount: 61,
      scrapCount: 30,
    ),
    RecipeItem(
      recipeId: 7,
      title: '제육볶음',
      description: '고추장 양념에 달콤 매콤하게 볶은 돼지고기 볶음으로, 밥도둑 반찬입니다.',
      ingredientsRaw: '돼지고기, 고추장, 간장, 설탕, 참기름, 양파, 대파',
      ingredientsList: [
        '돼지고기 앞다리살 300g',
        '고추장 2큰술',
        '간장 1큰술',
        '설탕 1큰술',
        '다진 마늘 1큰술',
        '생강 약간',
        '참기름 1큰술',
        '양파 1/2개',
        '대파 1/2대',
        '통깨 약간',
      ],
      cookingSteps: [
        '고추장, 간장, 설탕, 마늘, 생강, 참기름을 섞어 양념장을 만듭니다.',
        '돼지고기를 양념장에 30분 재웁니다.',
        '팬을 강불로 달궈 돼지고기를 볶습니다.',
        '고기가 반쯤 익으면 양파와 대파를 넣고 같이 볶습니다.',
        '통깨를 뿌려 완성합니다.',
      ],
      source: 'STANDARD',
      status: 'APPROVED',
      createdAt: DateTime(2025, 4, 4),
      likesCount: 88,
      scrapCount: 40,
    ),
    RecipeItem(
      recipeId: 8,
      title: '달걀말이',
      description: '폭신하고 촉촉한 계란말이. 도시락 반찬으로도 최고입니다.',
      ingredientsRaw: '계란, 당근, 대파, 소금, 식용유',
      ingredientsList: [
        '계란 3개',
        '당근 30g',
        '대파 1/4대',
        '소금 1/4 작은술',
        '식용유 적당량',
      ],
      cookingSteps: [
        '계란을 풀고 소금으로 간합니다.',
        '당근과 대파를 잘게 다져 계란물에 섞습니다.',
        '기름 두른 팬을 약불로 달궈 계란물 1/3을 붓습니다.',
        '반쯤 익으면 한쪽으로 말아줍니다.',
        '남은 계란물을 2번 더 부어가며 말아 완성합니다.',
        '한 김 식힌 후 먹기 좋게 썹니다.',
      ],
      source: 'USER',
      authorId: 2,
      status: 'APPROVED',
      createdAt: DateTime(2025, 4, 3),
      likesCount: 50,
      scrapCount: 22,
      isLiked: true,
    ),
    RecipeItem(
      recipeId: 9,
      title: '미역국',
      description: '생일, 산후 조리에 빠질 수 없는 깊고 구수한 미역국입니다.',
      ingredientsRaw: '미역, 소고기, 참기름, 간장, 다진 마늘',
      ingredientsList: [
        '건미역 20g',
        '소고기 (국거리) 150g',
        '참기름 1.5큰술',
        '간장 2큰술',
        '다진 마늘 1큰술',
        '물 6컵',
        '소금 약간',
      ],
      cookingSteps: [
        '미역을 찬물에 15~20분 불려 먹기 좋게 자릅니다.',
        '냄비에 참기름을 두르고 소고기를 볶습니다.',
        '소고기가 익으면 미역을 넣고 함께 볶습니다.',
        '물을 붓고 간장으로 간한 뒤 끓입니다.',
        '끓어오르면 다진 마늘을 넣고 약불로 20분 더 끓입니다.',
        '소금으로 마지막 간을 맞춥니다.',
      ],
      source: 'STANDARD',
      status: 'APPROVED',
      createdAt: DateTime(2025, 4, 2),
      likesCount: 73,
      scrapCount: 35,
    ),
    RecipeItem(
      recipeId: 10,
      title: '김치볶음밥',
      description: '신 김치와 참기름으로 만드는 정석 김치볶음밥. 5분이면 뚝딱 완성!',
      ingredientsRaw: '밥, 김치, 돼지고기, 참기름, 간장, 고추장',
      ingredientsList: [
        '밥 1공기',
        '신 김치 100g',
        '돼지고기 50g (없어도 됨)',
        '참기름 1큰술',
        '간장 1/2큰술',
        '고추장 1/2큰술 (선택)',
        '계란 1개',
        '통깨 약간',
      ],
      cookingSteps: [
        '김치를 잘게 자르고 기름 두른 팬에 볶습니다.',
        '돼지고기를 넣고 같이 볶습니다.',
        '밥을 넣고 눌러가며 볶습니다.',
        '간장과 고추장으로 간을 맞춥니다.',
        '참기름을 두르고 통깨를 뿌립니다.',
        '반숙 계란 후라이를 올려 완성합니다.',
      ],
      source: 'USER',
      authorId: 1,
      status: 'APPROVED',
      createdAt: DateTime(2025, 4, 1),
      likesCount: 120,
      scrapCount: 55,
      isLiked: true,
      isBookmarked: true,
    ),
  ];

  /// 추천 레시피 n개 반환 (좋아요 순 상위)
  static List<RecipeItem> getRecommendations({int count = 3}) {
    final sorted = List<RecipeItem>.from(recipes)
      ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
    return sorted.take(count).toList();
  }
}
