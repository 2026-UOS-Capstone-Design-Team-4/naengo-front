import 'recipe.dart';

class RecipeItem {
  /// 로컬에서만 사용하는 임시 ID 기준값 (이 값 이상이면 서버 미연동 레시피).
  static const int localOnlyIdThreshold = 9000;

  final int recipeId;
  final String title;
  final String? description;
  final String ingredientsRaw;
  final List<String> ingredientsList;
  final List<String> cookingSteps;
  final String? imageUrl;
  final String? videoUrl;
  final String source;
  final int? authorId;
  final String status;
  final DateTime createdAt;
  final String? difficulty;
  final int? cookingTime;
  final double? servings;
  final int? calories;
  final List<String> category;

  // Recipe_Stats
  int likesCount;
  int scrapCount;

  // Derived from Likes / Scraps for current user
  bool isLiked;
  bool isBookmarked;
  final bool isOfficialRecipe;

  RecipeItem({
    required this.recipeId,
    required this.title,
    this.description,
    required this.ingredientsRaw,
    this.ingredientsList = const [],
    this.cookingSteps = const [],
    this.imageUrl,
    this.videoUrl,
    this.source = 'ADMIN',
    this.authorId,
    this.status = 'APPROVED',
    required this.createdAt,
    this.difficulty,
    this.cookingTime,
    this.servings,
    this.calories,
    this.category = const [],
    this.likesCount = 0,
    this.scrapCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isOfficialRecipe = true,
  });

  /// 승인된 레시피 API 응답([Recipe])으로부터 생성.
  factory RecipeItem.fromRecipe(Recipe r) => RecipeItem(
        recipeId: r.id,
        title: r.title,
        description: r.description,
        ingredientsRaw: r.ingredientsRaw,
        ingredientsList: r.ingredients
            .map((e) => [e.name, e.amount, e.unit]
                .where((part) => part.trim().isNotEmpty)
                .join(' '))
            .where((e) => e.trim().isNotEmpty)
            .toList(growable: false),
        cookingSteps: r.instructions,
        imageUrl: r.imageUrl,
        videoUrl: r.videoUrl,
        source: r.authorType,
        status: 'APPROVED',
        createdAt: r.createdAt ?? DateTime.now(),
        difficulty: r.difficulty,
        cookingTime: r.cookingTime,
        servings: r.servings,
        calories: r.calories,
        category: r.category,
        likesCount: r.likesCount,
        scrapCount: r.scrapCount,
        isLiked: r.isLiked,
        isBookmarked: r.isScrapped,
        isOfficialRecipe: true,
      );

  /// 유저 제출 레시피 API 응답(JSON)으로부터 생성.
  /// API v5: user_recipe_id (이전: pending_recipe_id) — 두 키 모두 허용.
  factory RecipeItem.fromPendingJson(Map<String, dynamic> j) => RecipeItem(
        recipeId: j['user_recipe_id'] as int? ?? j['pending_recipe_id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        ingredientsRaw: j['ingredients_raw'] as String? ?? '',
        ingredientsList: ((j['ingredients'] as List?) ?? const [])
            .map((e) => ((e as Map)['name'] as String? ?? '').trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false),
        cookingSteps: _parsePendingSteps(j),
        imageUrl: j['image_url'] as String?,
        videoUrl: j['video_url'] as String?,
        source: 'USER',
        authorId: j['user_id'] as int?,
        status: j['status'] as String? ?? 'PENDING',
        createdAt: DateTime.parse(j['created_at'] as String),
        difficulty: j['difficulty'] as String?,
        cookingTime: j['cooking_time'] as int?,
        servings: (j['servings'] as num?)?.toDouble(),
        calories: j['calories'] as int?,
        category: ((j['category'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(growable: false),
        isOfficialRecipe: false,
      );

  static List<String> _parsePendingSteps(Map<String, dynamic> j) {
    final instructions = j['instructions'] as List?;
    if (instructions != null) {
      return instructions.map((e) => e as String).toList(growable: false);
    }
    return (j['content'] as String? ?? '')
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
}
