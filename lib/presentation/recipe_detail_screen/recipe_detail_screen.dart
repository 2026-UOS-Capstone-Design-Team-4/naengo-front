import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../shared/recipe_reaction.dart';
import '../../models/recipe_item.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeItem recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with RecipeReactionMixin {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),
                      _buildRecipeCard(),
                      SizedBox(height: 14.h),
                      _buildDescription(),
                      SizedBox(height: 14.h),
                      _buildInfoRow(),
                      SizedBox(height: 18.h),
                      _buildSection(
                        title: '필요한 재료',
                        content: widget.recipe.ingredientsList.isNotEmpty
                            ? widget.recipe.ingredientsList.join('\n')
                            : widget.recipe.ingredientsRaw,
                      ),
                      SizedBox(height: 18.h),
                      _buildSection(
                        title: '조리법',
                        content: widget.recipe.cookingSteps.isNotEmpty
                            ? widget.recipe.cookingSteps
                                .asMap()
                                .entries
                                .map((e) => '${e.key + 1}. ${e.value}')
                                .join('\n')
                            : '조리법을 불러오는 중입니다...',
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(
        left: 12.h,
        right: 16.h,
        top: 8.h,
        bottom: 8.h,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.chevron_left,
              color: appTheme.mainUI,
              size: 32.h,
            ),
          ),
          SizedBox(width: 2.h),
          Text(
            '상세보기',
            style: TextStyle(
              color: appTheme.mainUI,
              fontSize: 22.fSize,
              fontWeight: FontWeight.w800,
              fontFamily: 'NanumSquare ac',
            ),
          ),
        ],
      ),
    );
  }

  /// data URL(Mock) 또는 네트워크 URL(API) 모두 처리.
  /// API 연결 후 data URL이 오지 않으면 Image.network 분기만 실행됨.
  Widget _buildRecipeImage(String imageUrl) {
    if (imageUrl.startsWith('data:')) {
      final bytes = base64Decode(imageUrl.split(',').last);
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    return Image.network(imageUrl, fit: BoxFit.cover);
  }

  Widget _buildRecipeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.h),
      child: SizedBox(
        height: 232.h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.recipe.imageUrl != null
                ? _buildRecipeImage(widget.recipe.imageUrl!)
                : Container(
                    decoration: BoxDecoration(
                      color: appTheme.lightbasis,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 56.h,
                        color: appTheme.background,
                      ),
                    ),
                  ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: appTheme.background,
                padding: EdgeInsets.symmetric(
                  horizontal: 14.h,
                  vertical: 10.h,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.recipe.title,
                        style: TextStyle(
                          color: appTheme.middle,
                          fontSize: 15.fSize,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NanumSquare ac',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.recipe.isOfficialRecipe) ...[
                      GestureDetector(
                        onTap: () => toggleLike(widget.recipe),
                        child: Icon(
                          widget.recipe.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: appTheme.mainUI,
                          size: 24.h,
                        ),
                      ),
                      SizedBox(width: 10.h),
                      GestureDetector(
                        onTap: () => toggleScrap(widget.recipe),
                        child: Icon(
                          widget.recipe.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: appTheme.mainUI,
                          size: 24.h,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.recipe.description ?? '작성자의 음식에 대한 간단한 설명',
          style: TextStyle(
            fontSize: 12.5.fSize,
            color: appTheme.text,
            height: 1.5,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: 30.h,
          height: 2.h,
          color: appTheme.mainUI,
        ),
      ],
    );
  }

  String _difficultyLabel(String? difficulty) {
    switch (difficulty) {
      case 'easy':
        return '쉬움';
      case 'hard':
        return '어려움';
      default:
        return '보통';
    }
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: appTheme.verylight,
          borderRadius: BorderRadius.circular(10.h),
          border: Border.all(color: appTheme.lightbasis, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: appTheme.mainUI, size: 20.h),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.fSize,
                color: appTheme.disabled,
                fontFamily: 'NanumSquare ac',
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.fSize,
                fontWeight: FontWeight.w700,
                color: appTheme.middle,
                fontFamily: 'NanumSquare ac',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    final r = widget.recipe;
    final servingsText = r.servings != null
        ? '${r.servings!.toStringAsFixed(r.servings! % 1 == 0 ? 0 : 1)}인분'
        : '-';
    return Row(
      children: [
        _buildInfoChip(
          icon: Icons.bar_chart_rounded,
          label: '난이도',
          value: _difficultyLabel(r.difficulty),
        ),
        SizedBox(width: 8.h),
        _buildInfoChip(
          icon: Icons.access_time_rounded,
          label: '조리시간',
          value: r.cookingTime != null ? '${r.cookingTime}분' : '-',
        ),
        SizedBox(width: 8.h),
        _buildInfoChip(
          icon: Icons.people_outline_rounded,
          label: '양',
          value: servingsText,
        ),
        SizedBox(width: 8.h),
        _buildInfoChip(
          icon: Icons.local_fire_department_rounded,
          label: '열량',
          value: r.calories != null ? '${r.calories} kcal' : '-',
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: appTheme.mainUI,
            fontSize: 16.fSize,
            fontWeight: FontWeight.w800,
            fontFamily: 'NanumSquare ac',
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          content,
          style: TextStyle(
            fontSize: 13.fSize,
            color: appTheme.text,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
