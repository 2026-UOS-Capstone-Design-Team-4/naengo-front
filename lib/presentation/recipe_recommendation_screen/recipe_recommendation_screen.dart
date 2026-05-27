import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/recipe_reaction_store.dart';
import '../../models/recipe_item.dart';
import '../../services/camera_service.dart';
import '../../services/naengo_api_service.dart';
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
  List<RecipeItem> _recommendations = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    RecipeReactionStore.reactionNotifier.addListener(_onReactionChanged);
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final result = await NaengoApi.getRecipes(sort: 'likes', limit: 3);
      if (!mounted) return;
      setState(() {
        _recommendations = result.items.map(RecipeItem.fromRecipe).toList();
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      debugPrint('[Recommendation] 인기 레시피 로드 실패: $e');
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  @override
  void dispose() {
    RecipeReactionStore.reactionNotifier.removeListener(_onReactionChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onReactionChanged() {
    if (!mounted) return;
    setState(() {
      for (final recipe in _recommendations) {
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

  /// 카메라 → 촬영 → 미리보기 → 채팅방으로 진입.
  /// imagePath 를 arguments 로 넘기면 ChatInterfaceScreen 이 자동으로 첫 메시지로
  /// 사진을 Naengo API 에 전송하고 응답을 스트리밍.
  Future<void> _onCameraPressed() async {
    final photo = await CameraService.takePhoto();
    if (!mounted || photo == null) return;

    final confirmed = await _showPhotoPreview(File(photo.path));
    if (!mounted || confirmed != true) return;

    Navigator.of(context).pushNamed(
      AppRoutes.chatInterfaceScreen,
      arguments: {'imagePath': photo.path},
    );
  }

  /// 촬영한 사진 미리보기 다이얼로그. (앱 브랜드 톤과 동일한 컬러로 통일)
  Future<bool?> _showPhotoPreview(File file) {
    final primary = appTheme.basis;
    final tint = appTheme.maximumlight;
    final darkText = appTheme.text;

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: tint,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: Text(
                  '이 사진으로 보낼까요?',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(file, fit: BoxFit.cover),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        '다시 찍기',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        '사용',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            appTheme.verylight,
            appTheme.maximumlight,
            appTheme.background,
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 24.h, bottom: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.h),
                    child: _buildWelcomeMessage(),
                  ),
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
              .copyWith(color: appTheme.basis),
        ),
        SizedBox(height: 4.h),
        Text(
          "오늘 뭐 해먹을까요?",
          style: TextStyleHelper.instance.headline30ExtraBoldTmoneyRoundWind
              .copyWith(color: appTheme.text),
        ),
      ],
    );
  }

  Widget _buildRecipeRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.h),
          child: Text(
            "인기 레시피 추천",
            style: TextStyleHelper.instance.body15Regular.copyWith(
              color: appTheme.disabled,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        if (_isLoadingRecommendations)
          const Center(child: CircularProgressIndicator())
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.h),
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
            color: appTheme.background,
            borderRadius: BorderRadius.circular(30.h),
            border: Border.all(color: appTheme.basis, width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _onCameraPressed,
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
                    color: appTheme.text,
                    fontSize: 12.fSize,
                  ),
                  decoration: InputDecoration(
                    hintText: '냉고에게 물어보세요',
                    hintStyle:
                        TextStyleHelper.instance.body15RegularNanumSquareAc
                            .copyWith(
                      fontSize: 12.fSize,
                      color: appTheme.disabled,
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
