import '../models/chat_message.dart';
import '../models/chat_room.dart';

class ChatStore {
  ChatStore._();

  // ──────────────────────────────────────────────
  // 채팅방 목록 (Chat_Rooms 테이블) - 변경 가능한 목록
  // ──────────────────────────────────────────────
  static List<ChatRoom> chatRooms = [

  ];

  /// 새 채팅방 생성 (목록 맨 앞에 추가)
  static ChatRoom createRoom({int userId = 0}) {
    final room = ChatRoom(
      roomId: 'room-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
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

  /// 백엔드가 부여한 정수 room_id 를 채팅방에 저장.
  /// `NaengoApi` 의 `event: room` 도착 시 호출 → 이후 같은 방으로 라우팅 가능하게 함.
  static void updateServerRoomId(String roomId, int serverRoomId) {
    final index = chatRooms.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      chatRooms[index] = chatRooms[index].copyWith(
        serverRoomId: serverRoomId,
      );
    }
  }

  /// 채팅방 삭제 (메시지도 함께 삭제).
  /// 백엔드 동기화는 호출 측 (Sidebar) 에서 `NaengoApi.deleteRoom` 으로 처리.
  static void removeRoom(String roomId) {
    chatRooms.removeWhere((r) => r.roomId == roomId);
    roomMessages.remove(roomId);
  }

  /// 백엔드 `GET /chat/rooms` 응답으로 `chatRooms` 캐시 갱신.
  ///
  /// 정책:
  ///   - 서버에서 받은 방은 source of truth → 그대로 반영
  ///   - [activeLocalRoomId]가 지정된 경우 해당 방만 보존 (현재 채팅 중인 신규 방)
  ///   - 비로그인 게스트 채팅 중 생성된 방은 포함하지 않음
  ///
  /// 결과는 `updatedAt` 내림차순 정렬.
  static void mergeServerRooms(
    List<ChatRoom> serverRooms, {
    String? activeLocalRoomId,
  }) {
    final pending = activeLocalRoomId != null
        ? chatRooms
            .where((r) =>
                r.serverRoomId == null && r.roomId == activeLocalRoomId)
            .toList(growable: false)
        : <ChatRoom>[];
    chatRooms = [...pending, ...serverRooms]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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

  /// 백엔드 `GET /chat/rooms/{id}` 응답으로 방의 메시지 캐시 통째로 교체.
  /// 새 List 인스턴스로 갈아끼우므로, 기존 list 참조를 들고 있던 화면은
  /// `getMessages()` 로 새 참조를 다시 받아야 함.
  static void replaceMessages(String roomId, List<ChatMessage> messages) {
    roomMessages[roomId] = List<ChatMessage>.from(messages);
  }
}
