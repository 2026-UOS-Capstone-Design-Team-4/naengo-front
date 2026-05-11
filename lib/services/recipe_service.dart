import '../data/mock_data_service.dart';
import '../models/recipe_item.dart';
import '../models/recipe_submit_request.dart';
import 'naengo_api_service.dart';

/// 레시피 작성/조회/삭제 인터페이스.
///
/// UI는 이 인터페이스만 바라봄 →
/// [MockRecipeService] → 실제 API 서비스 교체 시 UI 코드 수정 불필요.
abstract class RecipeService {
  /// 레시피 제출.
  ///
  /// API 연결 후: POST /api/v1/recipes 호출로 교체.
  Future<RecipeItem> submitRecipe(RecipeSubmitRequest request);

  /// 내가 작성한 레시피 목록.
  ///
  /// API 연결 후: GET /api/v1/users/me/recipes 호출로 교체.
  List<RecipeItem> getMyRecipes();

  /// 내가 작성한 레시피 삭제.
  ///
  /// API 연결 후: DELETE /api/v1/users/me/recipes/{recipe_id} 호출로 교체.
  Future<void> deleteMyRecipe(int recipeId);
}

/// 앱 전역에서 사용할 RecipeService 인스턴스.
///
/// API 준비 완료 시:
///   RecipeServiceLocator.instance = RealRecipeService();
class RecipeServiceLocator {
  RecipeServiceLocator._();
  static RecipeService instance = RealRecipeService();
}

// ─────────────────────────────────────────────────────────
// Mock 구현 — API 연결 전까지 사용
// ─────────────────────────────────────────────────────────

class MockRecipeService implements RecipeService {
  @override
  Future<RecipeItem> submitRecipe(RecipeSubmitRequest request) async {
    await Future.delayed(const Duration(milliseconds: 400)); // 네트워크 시뮬레이션

    final recipe = RecipeItem(
      recipeId: DateTime.now().millisecondsSinceEpoch,
      title: request.title,
      description: request.description,
      ingredientsRaw: request.ingredientsRaw ?? '',
      ingredientsList: request.ingredientsRaw
              ?.split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      cookingSteps: request.content
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      source: 'USER',
      authorId: MockDataService.currentUser.userId,
      status: 'APPROVED',
      createdAt: DateTime.now(),
      difficulty: request.difficulty,
      cookingTime: request.cookingTime,
      servings: request.servings,
      calories: request.calories,
    );

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

// ─────────────────────────────────────────────────────────
// Real 구현 — POST/GET/DELETE /api/v1/pending-recipes
// ─────────────────────────────────────────────────────────

class RealRecipeService implements RecipeService {
  @override
  Future<RecipeItem> submitRecipe(RecipeSubmitRequest request) async {
    final id = await NaengoApi.submitPendingRecipe(request.toJson());
    final recipe = RecipeItem(
      recipeId: id,
      title: request.title,
      description: request.description,
      ingredientsRaw: request.ingredientsRaw ?? '',
      ingredientsList: request.ingredientsRaw
              ?.split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      cookingSteps: request.content
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      source: 'USER',
      authorId: 1,
      status: 'APPROVED', // TODO: 어드민 기능 개발 후 'PENDING'으로 교체
      createdAt: DateTime.now(),
      difficulty: request.difficulty,
      cookingTime: request.cookingTime,
      servings: request.servings,
      calories: request.calories,
    );
    MockDataService.addRecipe(recipe);
    return recipe;
  }

  @override
  List<RecipeItem> getMyRecipes() => [];

  @override
  Future<void> deleteMyRecipe(int recipeId) async {
    await NaengoApi.deletePendingRecipe(recipeId);
  }
}
