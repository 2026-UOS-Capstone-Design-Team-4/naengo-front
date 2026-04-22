class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime sentAt;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.sentAt,
  });
}
