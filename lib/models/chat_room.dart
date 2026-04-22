class ChatRoom {
  final String roomId; // room_id VARCHAR(100) PRIMARY KEY (UUID)
  final int userId; // user_id → Users.user_id
  final String title; // title VARCHAR(100)
  final bool isActive; // is_active BOOLEAN
  final DateTime createdAt; // created_at
  final DateTime updatedAt; // updated_at

  const ChatRoom({
    required this.roomId,
    required this.userId,
    required this.title,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatRoom copyWith({String? title, bool? isActive, DateTime? updatedAt}) {
    return ChatRoom(
      roomId: roomId,
      userId: userId,
      title: title ?? this.title,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
