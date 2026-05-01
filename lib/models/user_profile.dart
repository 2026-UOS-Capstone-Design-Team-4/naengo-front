/// User_Profiles 테이블 대응 모델.
class UserProfile {
  final int userId;
  final List<String> userInput;
  final List<String>? allergies;
  final List<String>? dietaryRestrictions;
  final List<String>? preferredIngredients;
  final List<String>? dislikedIngredients;
  final List<String>? preferredCategories;
  final List<String>? frequentlyUsedIngredients;
  final List<String>? tasteKeywords;
  final String? cookingSkill; 
  final int? preferredCookingTime; // 분
  final double? servingSize;       // 인분
  final List<int>? recentRecipeIds;
  final DateTime? aiAnalyzedAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.userId,
    this.userInput = const [],
    this.allergies,
    this.dietaryRestrictions,
    this.preferredIngredients,
    this.dislikedIngredients,
    this.preferredCategories,
    this.frequentlyUsedIngredients,
    this.tasteKeywords,
    this.cookingSkill,
    this.preferredCookingTime,
    this.servingSize,
    this.recentRecipeIds,
    this.aiAnalyzedAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        userId: j['user_id'] as int,
        userInput: _toStringList(j['user_input']),
        allergies: _toStringListOrNull(j['allergies']),
        dietaryRestrictions: _toStringListOrNull(j['dietary_restrictions']),
        preferredIngredients: _toStringListOrNull(j['preferred_ingredients']),
        dislikedIngredients: _toStringListOrNull(j['disliked_ingredients']),
        preferredCategories: _toStringListOrNull(j['preferred_categories']),
        frequentlyUsedIngredients:
            _toStringListOrNull(j['frequently_used_ingredients']),
        tasteKeywords: _toStringListOrNull(j['taste_keywords']),
        cookingSkill: j['cooking_skill'] as String?,
        preferredCookingTime: j['preferred_cooking_time'] as int?,
        servingSize: (j['serving_size'] as num?)?.toDouble(),
        recentRecipeIds: (j['recent_recipe_ids'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList(),
        aiAnalyzedAt: j['ai_analyzed_at'] != null
            ? DateTime.parse(j['ai_analyzed_at'] as String)
            : null,
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  UserProfile copyWith({List<String>? userInput}) => UserProfile(
        userId: userId,
        userInput: userInput ?? this.userInput,
        allergies: allergies,
        dietaryRestrictions: dietaryRestrictions,
        preferredIngredients: preferredIngredients,
        dislikedIngredients: dislikedIngredients,
        preferredCategories: preferredCategories,
        frequentlyUsedIngredients: frequentlyUsedIngredients,
        tasteKeywords: tasteKeywords,
        cookingSkill: cookingSkill,
        preferredCookingTime: preferredCookingTime,
        servingSize: servingSize,
        recentRecipeIds: recentRecipeIds,
        aiAnalyzedAt: aiAnalyzedAt,
        updatedAt: DateTime.now(),
      );
}

List<String> _toStringList(dynamic v) =>
    (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [];

List<String>? _toStringListOrNull(dynamic v) =>
    v == null ? null : (v as List<dynamic>).map((e) => e as String).toList();
