import 'recipe.dart';

/// 채팅방의 단일 메시지.
///
/// 사용자 메시지 / AI 응답 모두 이 한 클래스로 표현.
/// 일부 필드는 **mutable** — SSE 스트리밍 응답이 들어올 때마다 텍스트를 누적해야 하므로
/// `text`, `recipes`, `isStreaming` 은 `final` 이 아닙니다.
/// 동일한 메시지 객체에 대해 setState 만 호출하면 UI 가 갱신됨.
class ChatMessage {
  /// 텍스트 본문. SSE 청크가 들어올 때마다 누적됨.
  String text;

  /// `true` = 사용자, `false` = AI 응답
  final bool isMe;

  final DateTime sentAt;

  /// 사용자가 첨부한 로컬 사진 경로. 없으면 null.
  /// AI 메시지에는 보통 사용 안 함.
  final String? imagePath;

  /// AI 메시지에 첨부된 추천 레시피 목록.
  /// SSE `event: recipes` 도착 시 채워짐. 사용자 메시지에는 항상 빈 리스트.
  List<Recipe> recipes;

  /// AI 응답을 아직 스트리밍 받는 중이면 `true`.
  /// 채팅 버블에 "..." 같은 인디케이터를 표시할 때 사용.
  bool isStreaming;

  ChatMessage({
    this.text = '',
    required this.isMe,
    required this.sentAt,
    this.imagePath,
    List<Recipe>? recipes,
    this.isStreaming = false,
  }) : recipes = recipes ?? <Recipe>[];

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasText => text.isNotEmpty;
  bool get hasRecipes => recipes.isNotEmpty;
}
