import 'recipe.dart';

class RecipeItem {
  static const int localOnlyIdThreshold = 9000;

  final int recipeId;
  final String title;
  final String? description;
  final String ingredientsRaw;
  final List<String> ingredientsList;
  final List<String> cookingSteps;
  final String? imageUrl;
  final String? sourceUrl;
  final String source;
  final int? authorId;
  final String? authorNickname;
  final String status;
  final DateTime createdAt;
  final String? difficulty;
  final int? cookingTime;
  final double? servings;
  final int? calories;
  final List<String> category;

  int likesCount;
  int scrapCount;
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
    this.sourceUrl,
    this.source = 'ADMIN',
    this.authorId,
    this.authorNickname,
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
        sourceUrl: r.sourceUrl,
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

  factory RecipeItem.fromPendingJson(Map<String, dynamic> j) => RecipeItem(
        recipeId: j['user_recipe_id'] as int? ?? j['pending_recipe_id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        ingredientsRaw: ((j['ingredients'] as List?) ?? const [])
            .map((e) => ((e as Map)['name'] as String? ?? '').trim())
            .where((e) => e.isNotEmpty)
            .join(', '),
        ingredientsList: ((j['ingredients'] as List?) ?? const [])
            .map((e) => ((e as Map)['name'] as String? ?? '').trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false),
        cookingSteps: _parsePendingSteps(j),
        imageUrl: j['main_image_url'] as String?,
        sourceUrl: j['source_url'] as String?,
        source: 'USER',
        authorId: j['user_id'] as int?,
        authorNickname: (j['user'] as Map?)?['nickname'] as String?,
        status: j['status'] as String? ?? 'PENDING',
        createdAt: DateTime.parse(j['created_at'] as String),
        difficulty: j['difficulty'] as String?,
        cookingTime: j['cooking_time_minutes'] as int?,
        servings: (j['servings'] as num?)?.toDouble(),
        calories: j['kcal_per_serving'] as int?,
        category: ((j['category'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(growable: false),
        isOfficialRecipe: false,
      );

  static List<String> _parsePendingSteps(Map<String, dynamic> j) {
    final steps = j['steps'] as List?;
    if (steps != null && steps.isNotEmpty) {
      return steps
          .map((e) => (e as Map<String, dynamic>)['instruction'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }
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
