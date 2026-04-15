import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../models/recipe_item.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeItem recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late bool _isLiked;
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.recipe.isLiked;
    _isBookmarked = widget.recipe.isBookmarked;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      widget.recipe.isLiked = _isLiked;
      widget.recipe.likeCount += _isLiked ? 1 : -1;
    });
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
      widget.recipe.isBookmarked = _isBookmarked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      SizedBox(height: 18.h),
                      _buildSection(
                        title: '필요한 재료',
                        content: widget.recipe.ingredients,
                      ),
                      SizedBox(height: 18.h),
                      _buildSection(
                        title: '조리법',
                        content: widget.recipe.cookingSteps != null
                            ? widget.recipe.cookingSteps!.join('\n')
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

  /// 상단 헤더: < 상세보기
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
              color: const Color(0xFFFF4040),
              size: 32.h,
            ),
          ),
          SizedBox(width: 2.h),
          Text(
            '상세보기',
            style: TextStyle(
              color: const Color(0xFFFF4040),
              fontSize: 22.fSize,
              fontWeight: FontWeight.w800,
              fontFamily: 'NanumSquare ac',
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지 카드 + 이름/하트/북마크 오버레이
  Widget _buildRecipeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.h),
      child: SizedBox(
        height: 232.h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 음식 사진
            widget.recipe.imageAsset != null
                ? Image.asset(widget.recipe.imageAsset!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFCDCD), Color(0xFFFFB3B3)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 56.h,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),

            // 하단 반투명 이름 영역
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white.withOpacity(0.70),
                padding: EdgeInsets.symmetric(
                  horizontal: 14.h,
                  vertical: 10.h,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 레시피 이름
                    Expanded(
                      child: Text(
                        widget.recipe.name,
                        style: TextStyle(
                          color: const Color(0xFFFF7878),
                          fontSize: 15.fSize,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NanumSquare ac',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 하트 아이콘
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFFF4040),
                        size: 24.h,
                      ),
                    ),
                    SizedBox(width: 10.h),
                    // 북마크 아이콘
                    GestureDetector(
                      onTap: _toggleBookmark,
                      child: Icon(
                        _isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: const Color(0xFFFF4040),
                        size: 24.h,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 설명 텍스트 + 짧은 빨간 선
  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.recipe.description ?? '작성자의 음식에 대한 간단한 설명',
          style: TextStyle(
            fontSize: 12.5.fSize,
            color: const Color(0xFF222222),
            height: 1.5,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: 30.h,
          height: 2.h,
          color: const Color(0xFFFF4040),
        ),
      ],
    );
  }

  /// 필요한 재료 / 조리법 공통 섹션
  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFFFF4040),
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
            color: const Color(0xFF222222),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
