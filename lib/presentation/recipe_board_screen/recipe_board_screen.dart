
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/recipe_reaction_store.dart';
import '../shared/recipe_reaction.dart';
import '../../models/recipe_item.dart';
import '../../services/auth_service.dart';
import '../../services/naengo_api_service.dart';
import '../recipe_detail_screen/recipe_detail_screen.dart';
import '../../widgets/naengo_snackbar.dart';

enum SortType { latest, mostLiked, bookmarked }
enum _Tab { all, mine }

class RecipeBoardScreen extends StatefulWidget {
  const RecipeBoardScreen({super.key});

  @override
  State<RecipeBoardScreen> createState() => _RecipeBoardScreenState();
}

class _RecipeBoardScreenState extends State<RecipeBoardScreen>
    with RecipeReactionMixin {
  bool _isSortDropdownOpen = false;
  SortType _currentSort = SortType.latest;
  _Tab _tab = _Tab.all;

  List<RecipeItem> _allRecipes = [];
  bool _isLoadingAll = false;
  bool _isLoadingMore = false;
  String? _allLoadError;
  String? _nextCursor;
  String? _nextUserRecipeCursor;
  bool _hasNext = false;
  bool _hasNextUserRecipes = false;
  final ScrollController _scrollController = ScrollController();

  List<RecipeItem> _myRecipes = [];
  bool _isLoadingMine = false;
  String? _mineLoadError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    RecipeReactionStore.reactionNotifier.addListener(_onReactionChanged);
    _loadAllRecipes();
    _loadMyRecipes();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    RecipeReactionStore.reactionNotifier.removeListener(_onReactionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onReactionChanged() {
    if (!mounted) return;
    setState(() {
      for (final recipe in [..._allRecipes, ..._myRecipes]) {
        final cached = RecipeReactionStore.getReaction(recipe.recipeId);
        if (cached != null) {
          recipe.isLiked = cached.isLiked;
          recipe.isBookmarked = cached.isBookmarked;
          recipe.likesCount = cached.likesCount;
          recipe.scrapCount = cached.scrapCount;
        }
      }
    });
  }

  void _onScroll() {
    if (_tab != _Tab.all) return;
    if (_isLoadingMore || (!_hasNext && !_hasNextUserRecipes)) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreRecipes();
    }
  }

  void _switchTab(_Tab tab) {
    setState(() => _tab = tab);
    if (tab == _Tab.all) _loadAllRecipes();
    if (tab == _Tab.mine) _loadMyRecipes();
  }

  Future<void> _loadAllRecipes() async {
    setState(() {
      _isLoadingAll = true;
      _allLoadError = null;
      _nextCursor = null;
      _nextUserRecipeCursor = null;
      _hasNext = false;
      _hasNextUserRecipes = false;
    });
    try {
      final officialResult = _currentSort == SortType.bookmarked
          ? await NaengoApi.getMyScraps()
          : await NaengoApi.getRecipes(
              sort: _currentSort == SortType.mostLiked ? 'likes' : 'latest',
            );
      final userResult = _currentSort == SortType.latest
          ? await NaengoApi.getApprovedUserRecipes()
          : null;
      if (!mounted) return;
      setState(() {
        _allRecipes = _mergeAllRecipes(
          officialResult.items.map(RecipeItem.fromRecipe),
          userResult?.items.map(RecipeItem.fromPendingJson) ?? const [],
        );
        _nextCursor = officialResult.nextCursor;
        _nextUserRecipeCursor = userResult?.nextCursor;
        _hasNext = officialResult.hasNext;
        _hasNextUserRecipes = userResult?.hasNext ?? false;
        _isLoadingAll = false;
      });
    } catch (e, st) {
      debugPrint('[RecipeBoard] getRecipes 실패: $e\n$st');
      if (!mounted) return;
      setState(() {
        _allLoadError = '전체 레시피를 불러오지 못했어요.';
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (_isLoadingMore) return;
    final shouldLoadOfficial = _hasNext && _nextCursor != null;
    final shouldLoadUserRecipes =
        _currentSort == SortType.latest &&
        _hasNextUserRecipes &&
        _nextUserRecipeCursor != null;
    if (!shouldLoadOfficial && !shouldLoadUserRecipes) return;
    setState(() => _isLoadingMore = true);
    try {
      final officialResult = shouldLoadOfficial
          ? (_currentSort == SortType.bookmarked
              ? await NaengoApi.getMyScraps(cursor: _nextCursor)
              : await NaengoApi.getRecipes(
                  sort: _currentSort == SortType.mostLiked ? 'likes' : 'latest',
                  cursor: _nextCursor,
                ))
          : null;
      final userResult = shouldLoadUserRecipes
          ? await NaengoApi.getApprovedUserRecipes(
              cursor: _nextUserRecipeCursor,
            )
          : null;
      if (!mounted) return;
      setState(() {
        final newItems = [
          ...?officialResult?.items.map(RecipeItem.fromRecipe),
          ...?userResult?.items.map(RecipeItem.fromPendingJson),
        ];
        if (_currentSort == SortType.latest) {
          newItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        _allRecipes = [..._allRecipes, ...newItems];
        if (officialResult != null) {
          _nextCursor = officialResult.nextCursor;
          _hasNext = officialResult.hasNext;
        }
        if (userResult != null) {
          _nextUserRecipeCursor = userResult.nextCursor;
          _hasNextUserRecipes = userResult.hasNext;
        }
        _isLoadingMore = false;
      });
    } catch (e, st) {
      debugPrint('[RecipeBoard] loadMore 실패: $e\n$st');
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  List<RecipeItem> _mergeAllRecipes(
    Iterable<RecipeItem> recipes, [
    Iterable<RecipeItem> userRecipes = const [],
  ]) {
    final merged = [...recipes, ...userRecipes];
    if (_currentSort == SortType.latest) {
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return merged;
  }

  Future<void> _loadMyRecipes() async {
    setState(() {
      _isLoadingMine = true;
      _mineLoadError = null;
    });
    try {
      final list = await NaengoApi.getMyPendingRecipes();
      if (!mounted) return;
      setState(() {
        _myRecipes = list.map((j) {
          return RecipeItem.fromPendingJson(j);
        }).toList();
        _isLoadingMine = false;
      });
    } catch (e, st) {
      debugPrint('[RecipeBoard] getMyPendingRecipes 실패: $e\n$st');
      if (!mounted) return;
      setState(() {
        _mineLoadError = '내 레시피를 불러오지 못했어요.';
        _isLoadingMine = false;
      });
    }
  }


  Future<void> _navigateToDetail(RecipeItem recipe) async {
    var detailRecipe = recipe;
    if (_tab == _Tab.all &&
        recipe.status == 'APPROVED' &&
        recipe.isOfficialRecipe) {
      try {
        detailRecipe = RecipeItem.fromRecipe(await NaengoApi.getRecipe(recipe.recipeId));
      } catch (e) {
        debugPrint('[RecipeBoard] getRecipe 실패: $e');
      }
    } else if (_tab == _Tab.mine) {
      try {
        detailRecipe = RecipeItem.fromPendingJson(
          await NaengoApi.getUserRecipe(recipe.recipeId),
        );
      } catch (e) {
        debugPrint('[RecipeBoard] getUserRecipe 실패: $e');
      }
    } else if (_tab == _Tab.all && !recipe.isOfficialRecipe) {
      try {
        detailRecipe = RecipeItem.fromPendingJson(
          await NaengoApi.getApprovedUserRecipe(recipe.recipeId),
        );
      } catch (e) {
        debugPrint('[RecipeBoard] getApprovedUserRecipe 실패: $e');
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a, b) => RecipeDetailScreen(recipe: detailRecipe),
        transitionsBuilder: (c, a, b, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
    if (mounted) {
      setState(() {});
      if (_tab == _Tab.mine) _loadMyRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isSortDropdownOpen) setState(() => _isSortDropdownOpen = false);
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: _tab == _Tab.all ? _buildAllList() : _buildMyList(),
              ),
            ],
          ),
          if (_isSortDropdownOpen) _buildSortDropdown(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      decoration: BoxDecoration(
        color: appTheme.background,
        border: Border(bottom: BorderSide(color: appTheme.verylight, width: 1)),
      ),
      child: Row(
        children: [
          _buildTab('전체 레시피', _tab == _Tab.all, () => _switchTab(_Tab.all)),
          SizedBox(width: 20.h),
          _buildTab('내 레시피', _tab == _Tab.mine, () => _switchTab(_Tab.mine)),
          const Spacer(),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? appTheme.basis : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyleHelper.instance.body15BoldNanumSquareAc.copyWith(
            color: isActive ? appTheme.basis : appTheme.disabled,
            fontSize: 13.fSize,
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: () => setState(() => _isSortDropdownOpen = !_isSortDropdownOpen),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
        decoration: BoxDecoration(
          border: Border.all(color: appTheme.basis, width: 1),
          borderRadius: BorderRadius.circular(20.h),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert, color: appTheme.basis, size: 14),
            SizedBox(width: 4.h),
            Text(
              'Sort',
              style: TextStyle(
                color: appTheme.basis,
                fontSize: 12.fSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.h),
            Icon(
              _isSortDropdownOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: appTheme.basis,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Positioned(
      top: 46.h,
      right: 16.h,
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12.h),
        shadowColor: appTheme.lightbasis,
        child: Container(
          width: 130.h,
          padding: EdgeInsets.all(6.h),
          decoration: BoxDecoration(
            color: appTheme.background,
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: appTheme.basis, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdownItem('최신 순', SortType.latest),
              _buildDropdownItem('좋아요 순', SortType.mostLiked),
              _buildDropdownItem('북마크', SortType.bookmarked),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(String label, SortType sort) {
    final isSelected = _currentSort == sort;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSort = sort;
          _isSortDropdownOpen = false;
        });
        if (_tab == _Tab.all) _loadAllRecipes();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? appTheme.verylight : Colors.transparent,
          borderRadius: BorderRadius.circular(8.h),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? appTheme.basis : appTheme.disabled,
                  fontSize: 13.fSize,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllList() {
    final recipes = _allRecipes;
    if (_isLoadingAll && recipes.isEmpty) {
      return Center(child: CircularProgressIndicator(color: appTheme.basis));
    }
    if (_allLoadError != null && recipes.isEmpty) {
      return _buildMessageList(_allLoadError!, onRefresh: _loadAllRecipes);
    }
    if (recipes.isEmpty) {
      return _buildMessageList(
        '전체 레시피가 아직 없어요.',
        onRefresh: _loadAllRecipes,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAllRecipes,
      color: appTheme.basis,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.h,
                mainAxisSpacing: 10.h,
                mainAxisExtent: 214.h,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final recipe = recipes[index];
                  return GestureDetector(
                    onTap: () => _navigateToDetail(recipe),
                    child: _buildRecipeCard(recipe),
                  );
                },
                childCount: recipes.length,
              ),
            ),
          ),
          if (_isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Center(child: CircularProgressIndicator(color: appTheme.basis)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyList() {
    if (_isLoadingMine) {
      return Center(child: CircularProgressIndicator(color: appTheme.basis));
    }
    if (_myRecipes.isEmpty) {
      return _buildMessageList(
        _mineLoadError ?? '작성한 레시피가 없어요.',
        onRefresh: _loadMyRecipes,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMyRecipes,
      color: appTheme.basis,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
        itemCount: _myRecipes.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _navigateToDetail(_myRecipes[index]),
          child: _buildMyRecipeCard(_myRecipes[index]),
        ),
      ),
    );
  }

  Widget _buildMessageList(
    String message, {
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: appTheme.basis,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 180.h),
          Center(
            child: Text(
              message,
              style: TextStyleHelper.instance.body15RegularNanumSquareAc
                  .copyWith(color: appTheme.disabled),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(RecipeItem recipe) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.maximumlight,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: appTheme.mainUI, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.h),
              topRight: Radius.circular(10.h),
            ),
            child: SizedBox(
              height: 110.h,
              width: double.infinity,
              child: recipe.imageUrl != null
                  ? Image.network(
                      recipe.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, c, progress) {
                        if (progress == null) return c;
                        return Container(
                          color: appTheme.lightbasis,
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      },
                      errorBuilder: (context, error, stack) {
                        debugPrint(
                            '[BoardCard] 이미지 로드 실패: ${recipe.imageUrl}\n$error');
                        return Container(
                          color: appTheme.lightbasis,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48.h,
                              color: appTheme.mainUI.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: appTheme.lightbasis,
                      child: Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          size: 48.h,
                          color: appTheme.mainUI.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: TextStyleHelper.instance.body15BoldNanumSquareAc
                            .copyWith(fontSize: 13.fSize),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      if (recipe.authorNickname != null)
                        Text(
                          recipe.authorNickname!,
                          style: TextStyle(
                            fontSize: 11.fSize,
                            color: appTheme.basis,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: 3.h),
                      Text(
                        recipe.ingredientsRaw,
                        style: TextStyle(
                          fontSize: 11.fSize,
                          color: appTheme.disabled,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if (recipe.isOfficialRecipe)
                    _buildLikeBookmarkRow(recipe)
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRecipeCard(RecipeItem recipe) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 113.h),
      child: Container(
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: appTheme.maximumlight,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(color: appTheme.mainUI, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildThumbnailWithStatus(recipe.imageUrl, recipe.status),
            SizedBox(width: 12.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: TextStyleHelper.instance.body15BoldNanumSquareAc
                              .copyWith(fontSize: 15.fSize),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _confirmDelete(recipe),
                        child: Icon(
                          Icons.close,
                          size: 18.h,
                          color: appTheme.disabled,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    recipe.ingredientsRaw,
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: appTheme.disabled,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeBookmarkRow(RecipeItem recipe) {
    final loggedIn = AuthServiceLocator.instance.isLoggedIn;
    final liked = loggedIn && recipe.isLiked;
    final bookmarked = loggedIn && recipe.isBookmarked;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => toggleLike(recipe),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: liked ? appTheme.basis : appTheme.disabled,
                size: 22.h,
              ),
              SizedBox(width: 3.h),
              Text(
                '${recipe.likesCount}',
                style: TextStyle(
                  fontSize: 12.fSize,
                  color: liked ? appTheme.basis : appTheme.disabled,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.h),
        GestureDetector(
          onTap: () => toggleScrap(recipe),
          child: Icon(
            bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: bookmarked ? appTheme.basis : appTheme.disabled,
            size: 22.h,
          ),
        ),
      ],
    );
  }


  Future<void> _confirmDelete(RecipeItem recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: appTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.h)),
        title: Text('레시피 삭제', style: TextStyleHelper.instance.body15BoldNanumSquareAc),
        content: Text('\'${recipe.title}\' 레시피를 삭제할까요?',
            style: TextStyleHelper.instance.body15RegularNanumSquareAc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: appTheme.disabled)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제', style: TextStyle(color: appTheme.basis)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await NaengoApi.deletePendingRecipe(recipe.recipeId);
      setState(() => _myRecipes.removeWhere((r) => r.recipeId == recipe.recipeId));
    } catch (_) {
      if (!mounted) return;
      NaengoSnackBar.show(context, '삭제에 실패했어요.');
    }
  }

  Widget _buildThumbnail(String? imageUrl) {
    final placeholderIcon = Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 32.h,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );

    Widget child;
    if (imageUrl == null || imageUrl.isEmpty) {
      child = placeholderIcon;
    } else if (imageUrl.startsWith('data:')) {
      // base64 data URL은 현재 미지원 — 기본 아이콘 표시
      child = placeholderIcon;
    } else {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(10.h),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, c, progress) {
            if (progress == null) return c;
            return Center(
              child: SizedBox(
                width: 18.h,
                height: 18.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stack) {
            debugPrint('[Thumbnail] 이미지 로드 실패: $imageUrl\n$error');
            return placeholderIcon;
          },
        ),
      );
    }

    return Container(
      width: 76.h,
      height: 76.h,
      decoration: BoxDecoration(
        color: appTheme.lightbasis,
        borderRadius: BorderRadius.circular(10.h),
      ),
      child: child,
    );
  }

  Widget _buildThumbnailWithStatus(String? imageUrl, String status) {
    final (label, color) = switch (status) {
      'APPROVED' => ('승인됨', appTheme.approved),
      'REJECTED' => ('반려됨', appTheme.rejected),
      _ => ('검토중', appTheme.pending),
    };
    return Stack(
      children: [
        _buildThumbnail(imageUrl),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.h),
              topRight: Radius.circular(10.h),
            ),
            child: Container(
              color: color.withValues(alpha: 0.85),
              padding: EdgeInsets.symmetric(vertical: 4.h),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.fSize,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
