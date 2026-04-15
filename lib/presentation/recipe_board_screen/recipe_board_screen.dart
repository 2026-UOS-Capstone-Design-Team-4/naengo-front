import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../models/recipe_item.dart';
import '../../widgets/custom_image_view.dart';
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

  final List<RecipeItem> _recipes = [
    RecipeItem(
      id: '1',
      name: '에그 베네딕트',
      ingredients: '계란, 잉글리시 머핀, 베이컨, 홀란다이즈 소스',
      createdAt: DateTime(2025, 4, 10),
      likeCount: 42,
      isLiked: true,
      isBookmarked: true,
      description:
          '클래식 브런치의 대표 메뉴! 촉촉한 수란과 진한 홀란다이즈 소스가 잘 구워진 잉글리시 머핀 위에 어우러진 에그 베네딕트입니다.',
      ingredientsList: [
        '계란 2개', '잉글리시 머핀 1개', '캐나다 베이컨 2장',
        '홀란다이즈 소스 3큰술', '버터 적당량', '식초 1큰술', '소금, 후추 약간',
      ],
      cookingSteps: [
        '냄비에 물을 넉넉히 붓고 식초를 넣어 끓입니다.',
        '소용돌이를 만든 뒤 계란을 깨서 넣어 3분간 익힙니다.',
        '잉글리시 머핀을 버터 발라 토스터에 굽습니다.',
        '캐나다 베이컨을 프라이팬에 살짝 굽습니다.',
        '머핀 위에 베이컨, 수란 순으로 올리고 홀란다이즈 소스를 뿌립니다.',
      ],
    ),
    RecipeItem(
      id: '2',
      name: '소세지강정',
      ingredients: '소세지, 간장, 고추장, 올리고당, 통깨',
      createdAt: DateTime(2025, 4, 9),
      likeCount: 28,
      description: '바삭하게 튀긴 소세지에 달콤 짭조름한 강정 소스를 입힌 인기 반찬입니다.',
      cookingSteps: [
        '소세지를 어슷하게 칼집을 내어 한입 크기로 자릅니다.',
        '170°C 기름에 바삭하게 튀겨냅니다.',
        '간장, 고추장, 올리고당, 다진 마늘로 소스를 만듭니다.',
        '팬에 소스를 끓이다가 튀긴 소세지를 넣어 버무립니다.',
        '통깨를 뿌려 완성합니다.',
      ],
    ),
    RecipeItem(
      id: '3',
      name: '간장버터계란밥',
      ingredients: '밥, 계란, 버터, 간장, 참기름, 통깨',
      createdAt: DateTime(2025, 4, 8),
      likeCount: 35,
      isLiked: true,
      isBookmarked: true,
      description: '따뜻한 밥 위에 버터와 간장, 계란 노른자가 어우러진 고소하고 감칠맛 나는 계란밥입니다.',
      cookingSteps: [
        '따뜻한 밥을 그릇에 담습니다.',
        '계란 노른자와 흰자를 밥 위에 올립니다.',
        '버터를 밥 위에 올려 살살 녹입니다.',
        '간장을 골고루 뿌리고 참기름을 살짝 둘러줍니다.',
        '통깨를 뿌리고 비벼서 먹습니다.',
      ],
    ),
    RecipeItem(
      id: '4',
      name: '새송이버섯볶음',
      ingredients: '새송이버섯, 버터, 진간장, 굴소스, 통깨',
      createdAt: DateTime(2025, 4, 7),
      likeCount: 15,
      description: '쫄깃한 새송이버섯을 버터에 볶아 감칠맛을 살린 반찬입니다.',
      cookingSteps: [
        '새송이버섯을 먹기 좋은 크기로 찢거나 썹니다.',
        '버터를 녹인 후 마늘을 볶아 향을 냅니다.',
        '버섯을 넣고 중강불에서 노릇하게 볶습니다.',
        '진간장과 굴소스를 넣고 잘 섞어줍니다.',
        '불을 끄고 참기름, 통깨를 뿌려 마무리합니다.',
      ],
    ),
    RecipeItem(
      id: '5',
      name: '참치마요덮밥',
      ingredients: '참치캔, 마요네즈, 간장, 밥, 양파, 오이',
      createdAt: DateTime(2025, 4, 6),
      likeCount: 9,
      description: '냉장고 속 재료로 5분 만에 완성하는 간편 덮밥입니다.',
      cookingSteps: [
        '참치캔의 기름을 빼고 그릇에 담습니다.',
        '마요네즈, 간장, 소금, 후추를 넣고 섞어 참치마요를 만듭니다.',
        '양파와 오이를 잘게 다져 섞습니다.',
        '따뜻한 밥 위에 참치마요를 올립니다.',
        '기호에 따라 깻잎이나 김 가루를 올려 완성합니다.',
      ],
    ),
  ];

  List<RecipeItem> get _sortedRecipes {
    final list = List<RecipeItem>.from(_recipes);
    switch (_currentSort) {
      case SortType.latest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.mostLiked:
        list.sort((a, b) => b.likeCount.compareTo(a.likeCount));
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
      top: 46.h, // 탭바 바로 아래
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
            child: recipe.imageAsset != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.h),
                    child: Image.asset(recipe.imageAsset!, fit: BoxFit.cover),
                  )
                : null,
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: TextStyleHelper.instance.body15BoldNanumSquareAc
                      .copyWith(fontSize: 15.fSize),
                ),
                SizedBox(height: 4.h),
                Text(
                  recipe.ingredients,
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
                      onTap: () => setState(() {
                        recipe.isLiked = !recipe.isLiked;
                        recipe.likeCount += recipe.isLiked ? 1 : -1;
                      }),
                      child: Icon(
                        recipe.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: recipe.isLiked
                            ? const Color(0xFFFF5252)
                            : const Color(0xFFCCCCCC),
                        size: 22.h,
                      ),
                    ),
                    SizedBox(width: 10.h),
                    GestureDetector(
                      onTap: () => setState(() {
                        recipe.isBookmarked = !recipe.isBookmarked;
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
