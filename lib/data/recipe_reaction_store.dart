import 'package:flutter/foundation.dart';

class RecipeReactionStore {
  RecipeReactionStore._();

  // 좋아요/스크랩 상태 캐시 — 화면 간 동기화용
  static final ValueNotifier<int> reactionNotifier = ValueNotifier(0);
  static final Map<int, ({bool isLiked, bool isBookmarked, int likesCount, int scrapCount})> _reactionCache = {};

  static void updateReaction(
    int recipeId, {
    required bool isLiked,
    required bool isBookmarked,
    required int likesCount,
    required int scrapCount,
  }) {
    _reactionCache[recipeId] = (
      isLiked: isLiked,
      isBookmarked: isBookmarked,
      likesCount: likesCount,
      scrapCount: scrapCount,
    );
    reactionNotifier.value++;
  }

  static ({bool isLiked, bool isBookmarked, int likesCount, int scrapCount})? getReaction(int recipeId) =>
      _reactionCache[recipeId];
}
