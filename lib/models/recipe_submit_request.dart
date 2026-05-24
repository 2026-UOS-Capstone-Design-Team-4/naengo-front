/// 레시피 작성 제출 요청 DTO. POST /api/v1/recipes 의 request body.
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
        'description': description ?? '',
        'difficulty': difficulty,
        'category': category,
        'tags': <String>[],
        'tips': <String>[],
        'warnings': <String>[],
        'ingredients': <Map<String, dynamic>>[],
        'steps': [
          if (content.isNotEmpty)
            {'step_no': 1, 'instruction': content},
        ],
        if (cookingTime != null) 'cooking_time_minutes': cookingTime,
        if (servings != null) 'servings': servings,
        if (calories != null) 'kcal_per_serving': calories,
      };
}
