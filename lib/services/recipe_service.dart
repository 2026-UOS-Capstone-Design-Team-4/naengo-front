import '../data/mock_data_service.dart';
import '../models/recipe_item.dart';
import '../models/recipe_submit_request.dart';
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

class MockRecipeService implements RecipeService {
  @override
  Future<RecipeItem> submitRecipe(RecipeSubmitRequest request) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final recipe = RecipeItem.fromPendingJson({
      'user_recipe_id': DateTime.now().millisecondsSinceEpoch,
      'title': request.title,
      'description': request.description,
      'ingredients_raw': request.ingredientsRaw,
      'steps': request.steps.asMap().entries
          .map((e) => {'step_no': e.key + 1, 'instruction': e.value})
          .toList(),
      'image_url': null,
      'user_id': MockDataService.currentUser.userId,
      'status': 'PENDING',
      'created_at': DateTime.now().toIso8601String(),
      'difficulty': request.difficulty,
      'cooking_time': request.cookingTime,
      'servings': request.servings,
      'calories': request.calories,
      'category': request.category,
    });

    MockDataService.addRecipe(recipe);
    return recipe;
  }

  @override
  List<RecipeItem> getMyRecipes() => MockDataService.getMyRecipes();

  @override
  Future<void> deleteMyRecipe(int recipeId) async {
    MockDataService.deleteRecipe(recipeId);
  }
}

class RealRecipeService implements RecipeService {
  @override
  Future<RecipeItem> submitRecipe(RecipeSubmitRequest request) async {
    final id = await NaengoApi.submitPendingRecipe(request.toJson());
    final recipe = RecipeItem.fromPendingJson({
      'user_recipe_id': id,
      'title': request.title,
      'description': request.description,
      'ingredients_raw': request.ingredientsRaw,
      'steps': request.steps.asMap().entries
          .map((e) => {'step_no': e.key + 1, 'instruction': e.value})
          .toList(),
      'image_url': null,
      'user_id': 1,
      'status': 'PENDING',
      'created_at': DateTime.now().toIso8601String(),
      'difficulty': request.difficulty,
      'cooking_time': request.cookingTime,
      'servings': request.servings,
      'calories': request.calories,
      'category': request.category,
    });
    MockDataService.notifyRecipesChanged();
    return recipe;
  }

  @override
  List<RecipeItem> getMyRecipes() => [];

  @override
  Future<void> deleteMyRecipe(int recipeId) async {
    await NaengoApi.deletePendingRecipe(recipeId);
  }
}
