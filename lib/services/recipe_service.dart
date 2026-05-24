import '../models/recipe_item.dart';
import '../models/recipe_submit_request.dart';
import 'auth_service.dart';
import 'naengo_api_service.dart';

abstract class RecipeService {
  Future<RecipeItem> submitRecipe(RecipeSubmitRequest request);
  List<RecipeItem> getMyRecipes();
  Future<void> deleteMyRecipe(int recipeId);
}

class RecipeServiceLocator {
  RecipeServiceLocator._();
  static RecipeService instance = RealRecipeService();
}

class RealRecipeService implements RecipeService {
  @override
  Future<RecipeItem> submitRecipe(RecipeSubmitRequest request) async {
    final id = await NaengoApi.submitPendingRecipe(
      request.toJson(),
      mainImage: request.mainImage,
    );
    final recipe = RecipeItem.fromPendingJson({
      'user_recipe_id': id,
      'title': request.title,
      'description': request.description,
      'ingredients_raw': request.ingredientsRaw,
      'steps': request.steps.asMap().entries
          .map((e) => {'step_no': e.key + 1, 'instruction': e.value})
          .toList(),
      'image_url': null,
      'user_id': AuthServiceLocator.instance.currentUser.userId,
      'status': 'PENDING',
      'created_at': DateTime.now().toIso8601String(),
      'difficulty': request.difficulty,
      'cooking_time_minutes': request.cookingTime,
      'servings': request.servings,
      'kcal_per_serving': request.calories,
      'category': request.category,
    });
    return recipe;
  }

  @override
  List<RecipeItem> getMyRecipes() => [];

  @override
  Future<void> deleteMyRecipe(int recipeId) async {
    await NaengoApi.deletePendingRecipe(recipeId);
  }
}
