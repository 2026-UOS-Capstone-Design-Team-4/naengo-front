class RecipeItem {
  final int recipeId; // recipe_id SERIAL PRIMARY KEY
  final String title; // title VARCHAR(255)
  final String? description; // description TEXT
  final String ingredientsRaw; // ingredients_raw TEXT
  final List<String> ingredientsList; // ingredients JSONB (parsed)
  final List<String> cookingSteps; // instructions JSONB (parsed)
  final String? imageUrl; // image_url VARCHAR(512)
  final String? videoUrl; // video_url VARCHAR(512)
  final String source; // 'STANDARD' | 'USER'
  final int? authorId; // author_id → Users.user_id
  final String status; // 'APPROVED' | 'PENDING' | 'REJECTED'
  final DateTime createdAt; // created_at

  // Recipe_Stats
  int likesCount; // likes_count
  int scrapCount; // scrap_count

  // Derived from Likes / Scraps for current user
  bool isLiked;
  bool isBookmarked;

  RecipeItem({
    required this.recipeId,
    required this.title,
    this.description,
    required this.ingredientsRaw,
    this.ingredientsList = const [],
    this.cookingSteps = const [],
    this.imageUrl,
    this.videoUrl,
    this.source = 'STANDARD',
    this.authorId,
    this.status = 'APPROVED',
    required this.createdAt,
    this.likesCount = 0,
    this.scrapCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });
}
