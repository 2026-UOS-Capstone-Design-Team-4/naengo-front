class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime sentAt;

  /// 첨부된 이미지의 로컬 파일 경로 (없으면 null).
  /// 사용자가 카메라로 찍은 사진을 채팅방에 표시할 때 사용.
  final String? imagePath;

  ChatMessage({
    this.text = '',
    required this.isMe,
    required this.sentAt,
    this.imagePath,
  });

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasText => text.isNotEmpty;
}
