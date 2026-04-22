import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/mock_data_service.dart';
import '../../models/recipe_item.dart';
import '../recipe_detail_screen/recipe_detail_screen.dart';
export '../../models/recipe_item.dart';

enum SortType { latest, mostLiked, bookmarked }

class RecipeBoardScreen extends StatefulWidget {
  const RecipeBoardScreen({super.key});

  @override
  State<RecipeBoardScreen> createState() => _RecipeBoardScreenState();
}

class _RecipeBoardScreenState extends State<RecipeBoardScreen> {
  bool _isSortDropdownOpen = false;
  SortType _currentSort = SortType.latest;

  // MockDataService에서 가져온 레시피 목록
  final List<RecipeItem> _recipes = MockDataService.recipes;

  List<RecipeItem> get _sortedRecipes {
    final list = List<RecipeItem>.from(_recipes);
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
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a, b) => RecipeDetailScreen(recipe: recipe),
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
    if (mounted) setState(() {});
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
              Expanded(child: _buildRecipeList()),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        children: [
          _buildTab('전체 레시피', true),
          SizedBox(width: 20.h),
          _buildTab('내 레시피', false),
          const Spacer(),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Container(
      padding: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? const Color(0xFFFF5252) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyleHelper.instance.body15BoldNanumSquareAc.copyWith(
          color: isActive ? const Color(0xFFFF5252) : const Color(0xFF999999),
          fontSize: 13.fSize,
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
          border: Border.all(color: const Color(0xFFFF5252), width: 1),
          borderRadius: BorderRadius.circular(20.h),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert, color: Color(0xFFFF5252), size: 14),
            SizedBox(width: 4.h),
            Text(
              'Sort',
              style: TextStyle(
                color: const Color(0xFFFF5252),
                fontSize: 12.fSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.h),
            Icon(
              _isSortDropdownOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: const Color(0xFFFF5252),
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
        elevation: 4,
        borderRadius: BorderRadius.circular(12.h),
        child: Container(
          width: 120.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.h),
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
      onTap: () => setState(() {
        _currentSort = sort;
        _isSortDropdownOpen = false;
      }),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5252) : Colors.white,
          borderRadius: BorderRadius.circular(12.h),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF333333),
            fontSize: 13.fSize,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeList() {
    final recipes = _sortedRecipes;
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
      itemCount: recipes.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => _navigateToDetail(recipes[index]),
        child: _buildRecipeCard(recipes[index]),
      ),
    );
  }

  Widget _buildRecipeCard(RecipeItem recipe) {
    return Container(
      height: 113.h,
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76.h,
            height: 76.h,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB3B3),
              borderRadius: BorderRadius.circular(10.h),
            ),
            child: recipe.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.h),
                    child: Image.network(recipe.imageUrl!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 32.h,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: const Color(0xFF999999),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          recipe.isLiked = !recipe.isLiked;
                          recipe.likesCount += recipe.isLiked ? 1 : -1;
                        });
                        MockDataService.notifyLikesChanged();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            recipe.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: recipe.isLiked
                                ? const Color(0xFFFF5252)
                                : const Color(0xFFCCCCCC),
                            size: 22.h,
                          ),
                          SizedBox(width: 3.h),
                          Text(
                            '${recipe.likesCount}',
                            style: TextStyle(
                              fontSize: 12.fSize,
                              color: recipe.isLiked
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFFCCCCCC),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.h),
                    GestureDetector(
                      onTap: () => setState(() {
                        recipe.isBookmarked = !recipe.isBookmarked;
                        recipe.scrapCount += recipe.isBookmarked ? 1 : -1;
                      }),
                      child: Icon(
                        recipe.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: recipe.isBookmarked
                            ? const Color(0xFFFF5252)
                            : const Color(0xFFCCCCCC),
                        size: 22.h,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
