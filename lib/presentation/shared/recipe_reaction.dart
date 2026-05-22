import 'package:flutter/material.dart';

import '../../data/mock_data_service.dart';
import '../../models/recipe_item.dart';
import '../../services/auth_service.dart';
import '../../services/naengo_api_service.dart';
import '../../widgets/naengo_snackbar.dart';

/// 레시피 좋아요/스크랩 토글 로직을 공유
///
/// [RecipeBoardScreen], [RecipeDetailScreen] 두 화면에서 공통으로 사용.
mixin RecipeReactionMixin<T extends StatefulWidget> on State<T> {
  Future<void> toggleLike(RecipeItem recipe) async {
    if (!AuthServiceLocator.instance.isLoggedIn) {
      NaengoSnackBar.show(context, '로그인 후 이용할 수 있어요.');
      return;
    }
    if (!recipe.isOfficialRecipe) return;
    final prevLiked = recipe.isLiked;
    final prevLikes = recipe.likesCount;
    final prevScraps = recipe.scrapCount;
    final nextLiked = !recipe.isLiked;
    setState(() {
      recipe.isLiked = nextLiked;
      recipe.likesCount += nextLiked ? 1 : -1;
    });
    if (recipe.recipeId >= RecipeItem.localOnlyIdThreshold) {
      MockDataService.notifyLikesChanged();
      return;
    }
    try {
      final stats =
          await NaengoApi.setRecipeLike(recipe.recipeId, liked: nextLiked);
      if (!mounted) return;
      setState(() {
        recipe.likesCount = stats['likes_count'] ?? recipe.likesCount;
        recipe.scrapCount = stats['scrap_count'] ?? recipe.scrapCount;
      });
      MockDataService.notifyLikesChanged();
    } catch (_) {
      if (await syncRecipeFromServer(recipe)) return;
      if (!mounted) return;
      setState(() {
        recipe.isLiked = prevLiked;
        recipe.likesCount = prevLikes;
        recipe.scrapCount = prevScraps;
      });
      NaengoSnackBar.show(context, '좋아요 변경에 실패했어요.');
    }
  }

  Future<void> toggleScrap(RecipeItem recipe) async {
    if (!AuthServiceLocator.instance.isLoggedIn) {
      NaengoSnackBar.show(context, '로그인 후 이용할 수 있어요.');
      return;
    }
    if (!recipe.isOfficialRecipe) return;
    final prevScrapped = recipe.isBookmarked;
    final prevLikes = recipe.likesCount;
    final prevScraps = recipe.scrapCount;
    final nextScrapped = !recipe.isBookmarked;
    setState(() {
      recipe.isBookmarked = nextScrapped;
      recipe.scrapCount += nextScrapped ? 1 : -1;
    });
    if (recipe.recipeId >= RecipeItem.localOnlyIdThreshold) return;
    try {
      final stats = await NaengoApi.setRecipeScrap(
        recipe.recipeId,
        scrapped: nextScrapped,
      );
      if (!mounted) return;
      setState(() {
        recipe.likesCount = stats['likes_count'] ?? recipe.likesCount;
        recipe.scrapCount = stats['scrap_count'] ?? recipe.scrapCount;
      });
    } catch (_) {
      if (await syncRecipeFromServer(recipe)) return;
      if (!mounted) return;
      setState(() {
        recipe.isBookmarked = prevScrapped;
        recipe.likesCount = prevLikes;
        recipe.scrapCount = prevScraps;
      });
      NaengoSnackBar.show(context, '스크랩 변경에 실패했어요.');
    }
  }

  Future<bool> syncRecipeFromServer(RecipeItem recipe) async {
    if (!recipe.isOfficialRecipe) return false;
    try {
      final fresh = await NaengoApi.getRecipe(recipe.recipeId);
      if (!mounted) return true;
      setState(() {
        recipe.isLiked = fresh.isLiked;
        recipe.isBookmarked = fresh.isScrapped;
        recipe.likesCount = fresh.likesCount;
        recipe.scrapCount = fresh.scrapCount;
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
