class ChatRoom {
  final String roomId; // room_id VARCHAR(100) PRIMARY KEY (UUID) — 로컬/UI용
  final int userId; // user_id → Users.user_id
  final String title; // title VARCHAR(100)
  final bool isActive; // is_active BOOLEAN
  final DateTime createdAt; // created_at
  final DateTime updatedAt; // updated_at

  /// Naengo 백엔드(`POST /chat/rooms` 응답)가 부여한 정수 room_id.
  /// 첫 메시지 보내고 SSE `event: room` 으로 받음. 이후 같은 방으로 메시지 라우팅에 사용.
  /// `null` = 아직 백엔드에 방이 만들어지지 않음 (첫 메시지 전).
  final int? serverRoomId;

  const ChatRoom({
    required this.roomId,
    required this.userId,
    required this.title,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.serverRoomId,
  });

  ChatRoom copyWith({
    String? title,
    bool? isActive,
    DateTime? updatedAt,
    int? serverRoomId,
  }) {
    return ChatRoom(
      roomId: roomId,
      userId: userId,
      title: title ?? this.title,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverRoomId: serverRoomId ?? this.serverRoomId,
    );
  }
}
