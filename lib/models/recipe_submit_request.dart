/// 레시피 작성 제출 요청 DTO.
///
/// API 연결 시: POST /api/v1/recipes 의 request body 로 사용.
class RecipeSubmitRequest {
  final String title;
  final String content; // 조리법 (NOT NULL)
  final String? description;
  final String? ingredientsRaw;

  const RecipeSubmitRequest({
    required this.title,
    required this.content,
    this.description,
    this.ingredientsRaw,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (ingredientsRaw != null && ingredientsRaw!.isNotEmpty)
          'ingredients_raw': ingredientsRaw,
      };
}
