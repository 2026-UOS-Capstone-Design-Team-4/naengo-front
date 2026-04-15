class RecipeItem {
  final String id;
  final String name;
  final String ingredients;
  final String? imageAsset;
  bool isLiked;
  bool isBookmarked;
  final DateTime createdAt;
  int likeCount;
  final String? description;
  final List<String>? ingredientsList;
  final List<String>? cookingSteps;

  RecipeItem({
    required this.id,
    required this.name,
    required this.ingredients,
    this.imageAsset,
    this.isLiked = false,
    this.isBookmarked = false,
    required this.createdAt,
    this.likeCount = 0,
    this.description,
    this.ingredientsList,
    this.cookingSteps,
  });
}
