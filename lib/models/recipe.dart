/// Naengo 백엔드 (`/api/v1/...`) 가 반환하는 레시피 응답 모델.
///
/// SSE `event: recipes` 이벤트의 data 페이로드, `GET /chat/rooms/{id}` 의
/// `recipes` 필드, `GET /recipes?ids=...` 응답 등에서 동일한 구조로 사용됨.
class Recipe {
  final int id;
  final String title;
  final String description;
  final List<IngredientItem> ingredients;
  final String ingredientsRaw;
  final List<String> instructions;
  final double servings;
  final int cookingTime;
  final int? calories;
  final String difficulty; // 'easy' | 'normal' | 'hard'
  final List<String> category;
  final List<String> tags;
  final List<String> tips;
  final String? videoUrl;
  final String? imageUrl;
  final String authorType; // 'ADMIN' | 'USER'
  final int likesCount;
  final int scrapCount;
  final bool isLiked;
  final bool isScrapped;
  final DateTime? createdAt;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.ingredientsRaw,
    required this.instructions,
    required this.servings,
    required this.cookingTime,
    this.calories,
    required this.difficulty,
    required this.category,
    required this.tags,
    required this.tips,
    this.videoUrl,
    this.imageUrl,
    required this.authorType,
    this.likesCount = 0,
    this.scrapCount = 0,
    this.isLiked = false,
    this.isScrapped = false,
    this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ingredients: ((json['ingredients'] as List?) ?? const [])
          .map((e) => IngredientItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      ingredientsRaw: json['ingredients_raw'] as String? ?? '',
      instructions: ((json['instructions'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      servings: (json['servings'] as num?)?.toDouble() ?? 0,
      cookingTime: json['cooking_time'] as int? ?? 0,
      calories: json['calories'] as int?,
      difficulty: json['difficulty'] as String? ?? 'normal',
      category: ((json['category'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      tips: ((json['tips'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      videoUrl: json['video_url'] as String?,
      imageUrl: json['image_url'] as String?,
      authorType: json['author_type'] as String? ?? 'ADMIN',
      likesCount: json['likes_count'] as int? ?? 0,
      scrapCount: json['scrap_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isScrapped: json['is_scrapped'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }
}

/// 레시피 안의 개별 재료. 백엔드 IngredientItem 스키마 1:1 매핑.
class IngredientItem {
  final String name;
  final String amount;
  final String unit;
  final String type;
  final String? note;

  const IngredientItem({
    required this.name,
    required this.amount,
    required this.unit,
    required this.type,
    this.note,
  });

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    return IngredientItem(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      type: json['type'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}
