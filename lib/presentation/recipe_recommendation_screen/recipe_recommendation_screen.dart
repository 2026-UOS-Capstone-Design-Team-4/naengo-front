import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/mock_data_service.dart';
import '../../models/recipe_item.dart';
import '../../widgets/custom_image_view.dart';
import '../recipe_detail_screen/recipe_detail_screen.dart';
import './widgets/recipe_card_widget.dart';

class RecipeRecommendationScreen extends StatefulWidget {
  const RecipeRecommendationScreen({super.key});

  @override
  State<RecipeRecommendationScreen> createState() =>
      _RecipeRecommendationScreenState();
}

class _RecipeRecommendationScreenState
    extends State<RecipeRecommendationScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final List<RecipeItem> _recommendations;

  @override
  void initState() {
    super.initState();
    _recommendations = MockDataService.getRecommendations(count: 3);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onSendMessagePressed() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _messageController.clear();
      Navigator.of(context).pushNamed(
        AppRoutes.chatInterfaceScreen,
        arguments: text,
      );
    }
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFECEC),
            Color(0xFFFFF8F8),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 20.h,
                vertical: 24.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeMessage(),
                  SizedBox(height: 40.h),
                  _buildRecipeRecommendationSection(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          _buildChatInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "안녕하세요, 냉고입니다.",
          style: TextStyleHelper.instance.title20ExtraBoldTmoneyRoundWind
              .copyWith(color: const Color(0xFFFF5252)),
        ),
        SizedBox(height: 4.h),
        Text(
          "오늘 뭐 해먹을까요?",
          style: TextStyleHelper.instance.headline30ExtraBoldTmoneyRoundWind
              .copyWith(color: const Color(0xFF1A1A1A)),
        ),
      ],
    );
  }

  Widget _buildRecipeRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "인기 레시피 추천",
          style: TextStyleHelper.instance.body15Regular.copyWith(
            color: const Color(0xFF999999),
          ),
        ),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _recommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final recipe = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < _recommendations.length - 1 ? 16.h : 0,
                ),
                child: RecipeCardWidget(
                  recipe: recipe,
                  onTap: () => _navigateToDetail(recipe),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChatInputArea() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.h),
            border: Border.all(color: const Color(0xFFFF5252), width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.chatInterfaceScreen);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 8.h),
                  child: CustomImageView(
                    imagePath: ImageConstant.imgCamera,
                    width: 34.h,
                    height: 34.h,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  onSubmitted: (_) => _onSendMessagePressed(),
                  style: TextStyleHelper.instance.body15NanumSquareAc.copyWith(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 12.fSize,
                  ),
                  decoration: InputDecoration(
                    hintText: '냉고에게 물어보세요',
                    hintStyle:
                        TextStyleHelper.instance.body15RegularNanumSquareAc
                            .copyWith(
                      fontSize: 12.fSize,
                      color: const Color(0xFFAAAAAA),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _onSendMessagePressed,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
                  child: CustomImageView(
                    imagePath: ImageConstant.imgPaperplane,
                    width: 28.h,
                    height: 28.h,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
