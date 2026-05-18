
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/mock_data_service.dart';
import '../shared/recipe_reaction.dart';
import '../../models/recipe_item.dart';
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
  bool _hasNext = false;
  final ScrollController _scrollController = ScrollController();

  List<RecipeItem> _myRecipes = [];
  bool _isLoadingMine = false;
  String? _mineLoadError;

  @override
  void initState() {
    super.initState();
    MockDataService.recipesNotifier.addListener(_onRecipesChanged);
    _scrollController.addListener(_onScroll);
    _loadAllRecipes();
    _loadMyRecipes();
  }

  @override
  void dispose() {
    MockDataService.recipesNotifier.removeListener(_onRecipesChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_tab != _Tab.all) return;
    if (_isLoadingMore || !_hasNext) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreRecipes();
    }
  }

  void _onRecipesChanged() {
    if (mounted) setState(() => _tab = _Tab.mine);
    _loadAllRecipes();
    _loadMyRecipes();
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
      _hasNext = false;
    });
    try {
      final result = _currentSort == SortType.bookmarked
          ? await NaengoApi.getMyScraps()
          : await NaengoApi.getRecipes(
              sort: _currentSort == SortType.mostLiked ? 'likes' : 'latest',
            );
      if (!mounted) return;
      setState(() {
        _allRecipes = result.items.map(RecipeItem.fromRecipe).toList(growable: false);
        _nextCursor = result.nextCursor;
        _hasNext = result.hasNext;
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
    if (_isLoadingMore || !_hasNext || _nextCursor == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = _currentSort == SortType.bookmarked
          ? await NaengoApi.getMyScraps(cursor: _nextCursor)
          : await NaengoApi.getRecipes(
              sort: _currentSort == SortType.mostLiked ? 'likes' : 'latest',
              cursor: _nextCursor,
            );
      if (!mounted) return;
      setState(() {
        _allRecipes = [
          ..._allRecipes,
          ...result.items.map(RecipeItem.fromRecipe),
        ];
        _nextCursor = result.nextCursor;
        _hasNext = result.hasNext;
        _isLoadingMore = false;
      });
    } catch (e, st) {
      debugPrint('[RecipeBoard] loadMore 실패: $e\n$st');
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
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


  List<RecipeItem> get _sortedRecipes {
    final list = List<RecipeItem>.from(_allRecipes);
    switch (_currentSort) {
      case SortType.latest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.mostLiked:
        list.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        break;
      case SortType.bookmarked:
        list.sort((a, b) {
          if (a.isBookmarked == b.isBookmarked) {
            return b.createdAt.compareTo(a.createdAt);
          }
          return a.isBookmarked ? -1 : 1;
        });
        break;
    }
    return list;
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
    }
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
      if (_tab == _Tab.all) _loadAllRecipes();
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
        shadowColor: Colors.black.withValues(alpha: 0.1),
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
    final recipes = _sortedRecipes;
    if (_isLoadingAll && recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
        itemCount: recipes.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          if (index == recipes.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          final recipe = recipes[index];
          return GestureDetector(
            onTap: () => _navigateToDetail(recipe),
            child: _buildRecipeCard(recipe),
          );
        },
      ),
    );
  }

  Widget _buildMyList() {
    if (_isLoadingMine) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myRecipes.isEmpty) {
      return _buildMessageList(
        _mineLoadError ?? '작성한 레시피가 없어요.',
        onRefresh: _loadMyRecipes,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMyRecipes,
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
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 113.h),
      child: Container(
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: appTheme.background,
          borderRadius: BorderRadius.circular(12.h),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildThumbnail(recipe.imageUrl),
            SizedBox(width: 12.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipe.title,
                    style: TextStyleHelper.instance.body15BoldNanumSquareAc
                        .copyWith(fontSize: 15.fSize),
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
                  _buildLikeBookmarkRow(recipe),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRecipeCard(RecipeItem recipe) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 113.h),
      child: Container(
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: appTheme.background,
          borderRadius: BorderRadius.circular(12.h),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => toggleLike(recipe),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                recipe.isLiked ? Icons.favorite : Icons.favorite_border,
                color: recipe.isLiked ? appTheme.basis : appTheme.cloudy,
                size: 22.h,
              ),
              SizedBox(width: 3.h),
              Text(
                '${recipe.likesCount}',
                style: TextStyle(
                  fontSize: 12.fSize,
                  color: recipe.isLiked ? appTheme.basis : appTheme.cloudy,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.h),
        GestureDetector(
          onTap: () => toggleScrap(recipe),
          child: Icon(
            recipe.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: recipe.isBookmarked ? appTheme.basis : appTheme.cloudy,
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
        title: const Text('레시피 삭제'),
        content: Text('\'${recipe.title}\' 레시피를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
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
      MockDataService.deleteRecipe(recipe.recipeId);
      setState(() => _myRecipes.removeWhere((r) => r.recipeId == recipe.recipeId));
    } catch (_) {
      if (!mounted) return;
      NaengoSnackBar.show(context, '삭제에 실패했어요.');
    }
  }

  Widget _buildThumbnail(String? imageUrl) {
    Widget child;
    if (imageUrl != null && imageUrl.startsWith('data:')) {
      // base64 data URL → Image.memory 사용 불가 (String이라 직접 decode 필요)
      // 이미지 업로드 엔드포인트 구현 전까지 기본 아이콘 표시
      child = Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 32.h,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      );
    } else if (imageUrl != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(10.h),
        child: Image.network(imageUrl, fit: BoxFit.cover),
      );
    } else {
      child = Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 32.h,
          color: Colors.white.withValues(alpha: 0.7),
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
