class RecipeStep {
  final int stepNo;
  final String instruction;
  final String? imageUrl;
  final String? aiImageUrl;

  const RecipeStep({
    required this.stepNo,
    required this.instruction,
    this.imageUrl,
    this.aiImageUrl,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        stepNo: json['step_no'] as int? ?? 0,
        instruction: json['instruction'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
        aiImageUrl: json['ai_image_url'] as String?,
      );
}

class Recipe {
  final int id;
  final String title;
  final String description;
  final List<IngredientItem> ingredients;
  final String ingredientsRaw;
  final List<RecipeStep> steps;
  final double servings;
  final int cookingTime;
  final int? calories;
  final String difficulty; // 'easy' | 'normal' | 'hard'
  final List<String> category;
  final List<String> tags;
  final List<String> tips;
  final String? imageUrl;
  final String authorType; // 'ADMIN' | 'USER' | 'SOURCE'
  final String? summary;
  final List<String> warnings;
  final String? sourceUrl;
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
    required this.steps,
    required this.servings,
    required this.cookingTime,
    this.calories,
    required this.difficulty,
    required this.category,
    required this.tags,
    required this.tips,
    this.imageUrl,
    required this.authorType,
    this.summary,
    this.warnings = const [],
    this.sourceUrl,
    this.likesCount = 0,
    this.scrapCount = 0,
    this.isLiked = false,
    this.isScrapped = false,
    this.createdAt,
  });

  List<String> get instructions =>
      steps.map((s) => s.instruction).where((s) => s.isNotEmpty).toList();

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ingredients: ((json['ingredients'] as List?) ?? const [])
          .map((e) => IngredientItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      ingredientsRaw:
          json['ingredients_raw'] as String? ??
          ((json['ingredients'] as List?) ?? const [])
              .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .join(', '),
      steps: ((json['steps'] as List?) ?? const [])
          .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      servings: (json['servings'] as num?)?.toDouble() ?? 0,
      cookingTime: json['cooking_time_minutes'] as int? ?? 0,
      calories: json['kcal_per_serving'] as int?,
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
      imageUrl: json['main_image_url'] as String?,
      authorType: json['author_type'] as String? ?? 'ADMIN',
      summary: json['summary'] as String?,
      warnings: ((json['warnings'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      sourceUrl: json['source_url'] as String?,
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
      amount: json['amount_text'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      type: json['type'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}
