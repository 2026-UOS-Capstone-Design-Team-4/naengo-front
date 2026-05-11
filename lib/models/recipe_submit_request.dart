/// 레시피 작성 제출 요청 DTO.
///
/// API 연결 시: POST /api/v1/recipes 의 request body 로 사용.
class RecipeSubmitRequest {
  final String title;
  final String content; // 조리법 (NOT NULL)
  final String? description;
  final String? ingredientsRaw;
  final String difficulty; // 'easy' | 'normal' | 'hard' (필수)
  final int? cookingTime; // 분 (선택)
  final double? servings; // 인분 (선택)
  final int? calories; // kcal (선택)
  final List<String> category;

  const RecipeSubmitRequest({
    required this.title,
    required this.content,
    this.description,
    this.ingredientsRaw,
    required this.difficulty,
    this.cookingTime,
    this.servings,
    this.calories,
    this.category = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'difficulty': difficulty,
        'category': category,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (ingredientsRaw != null && ingredientsRaw!.isNotEmpty)
          'ingredients_raw': ingredientsRaw,
        if (cookingTime != null) 'cooking_time': cookingTime,
        if (servings != null) 'servings': servings,
        if (calories != null) 'calories': calories,
      };
}
