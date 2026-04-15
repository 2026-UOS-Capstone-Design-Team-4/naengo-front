import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';

class RecipeManagementScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final String? activeRoute;
  final VoidCallback? onNavigateToRecommendation;
  final VoidCallback? onNavigateToBoard;

  const RecipeManagementScreen({
    super.key,
    this.onClose,
    this.activeRoute,
    this.onNavigateToRecommendation,
    this.onNavigateToBoard,
  });

  @override
  State<RecipeManagementScreen> createState() => _RecipeManagementScreenState();
}

class _RecipeManagementScreenState extends State<RecipeManagementScreen>
    with SingleTickerProviderStateMixin {
  bool _isChatExpanded = true;
  late AnimationController _chatExpandController;
  late Animation<double> _chatExpandAnimation;

  @override
  void initState() {
    super.initState();
    _chatExpandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0, // 기본 펼쳐진 상태
    );
    _chatExpandAnimation = CurvedAnimation(
      parent: _chatExpandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _chatExpandController.dispose();
    super.dispose();
  }

  void _toggleChatExpand() {
    setState(() => _isChatExpanded = !_isChatExpanded);
    if (_isChatExpanded) {
      _chatExpandController.forward();
    } else {
      _chatExpandController.reverse();
    }
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    }
  }

  bool _isActive(String route) => widget.activeRoute == route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.red_50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24.h),
            _buildMenuItem(
              iconPath: ImageConstant.imgRed500,
              title: '새 채팅',
              isActive: _isActive(AppRoutes.recipeRecommendationScreen),
              onTap: () => _onNewChatTapped(context),
            ),
            SizedBox(height: 8.h),
            _buildMenuItem(
              iconPath: ImageConstant.imgRed50024x24,
              title: '레시피 게시판',
              isActive: _isActive(AppRoutes.recipeBoardScreen),
              onTap: () => _onRecipeBoardTapped(context),
            ),
            SizedBox(height: 8.h),
            _buildMenuItem(
              iconPath: ImageConstant.imgPencilSharp,
              title: '레시피 작성하기',
              isActive: false,
              onTap: () => _onRecipeCreateTapped(context),
            ),
            SizedBox(height: 8.h),
            _buildChatMenuItem(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 12.h, right: 8.h),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: _handleClose,
          child: Container(
            padding: EdgeInsets.all(8.h),
            child: Icon(
              Icons.chevron_left,
              color: appTheme.red_500,
              size: 28.h,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String iconPath,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    // 비활성: 좌측 margin 26h (아이콘 위치 고정)
    // 활성: 좌측 끝에서 시작, 우측만 둥글게 (사이드바.png 스타일)
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          left: isActive ? 0 : 12.h,
          right: 50.h,
        ),
        padding: EdgeInsets.only(
          left: isActive ? 26.h : 14.h,
          right: 14.h,
          top: 12.h,
          bottom: 12.h,
        ),
        decoration: BoxDecoration(
          color: isActive ? appTheme.red_500 : Colors.transparent,
          borderRadius: isActive
              ? BorderRadius.only(
                  topRight: Radius.circular(14.h),
                  bottomRight: Radius.circular(14.h),
                )
              : BorderRadius.zero,
        ),
        child: Row(
          children: [
            CustomImageView(
              imagePath: iconPath,
              width: 24.h,
              height: 24.h,
              color: isActive ? Colors.white : null,
            ),
            SizedBox(width: 10.h),
            Text(
              title,
              style: TextStyleHelper.instance.title18BoldNanumSquareAc.copyWith(
                color: isActive ? Colors.white : appTheme.black_900_01,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMenuItem(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleChatExpand,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 12.h),
            child: Row(
              children: [
                CustomImageView(
                  imagePath: ImageConstant.img24x24,
                  width: 24.h,
                  height: 24.h,
                ),
                SizedBox(width: 10.h),
                Text(
                  '내 채팅',
                  style: TextStyleHelper.instance.title18BoldNanumSquareAc,
                ),
                SizedBox(width: 4.h),
                AnimatedRotation(
                  turns: _isChatExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20.h,
                    color: appTheme.red_500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _chatExpandAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              // 현재 채팅방 - 채팅 중일 때 강조 (우측만 둥글게, 좌측 시작)
              Container(
                margin: EdgeInsets.only(right: 50.h),
                padding: EdgeInsets.only(
                  top: 8.h,
                  bottom: 8.h,
                  left: 60.h,
                  right: 20.h,
                ),
                decoration: BoxDecoration(
                  color: _isActive(AppRoutes.chatInterfaceScreen)
                      ? appTheme.red_500
                      : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14.h),
                    bottomRight: Radius.circular(14.h),
                  ),
                ),
                child: Text(
                  '현재채팅방 이름',
                  style: TextStyleHelper.instance.body15BoldNanumSquareAc.copyWith(
                    color: _isActive(AppRoutes.chatInterfaceScreen)
                        ? Colors.white
                        : appTheme.black_900_01,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              _buildChatHistoryItem('이전채팅기록 1', () {}),
              SizedBox(height: 4.h),
              _buildChatHistoryItem('이전채팅기록 2', () {}),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatHistoryItem(String title, VoidCallback onDeleteTap) {
    return Container(
      margin: EdgeInsets.only(right: 50.h),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 60.h),
          Expanded(
            child: Text(
              title,
              style: TextStyleHelper.instance.body15BoldNanumSquareAc,
            ),
          ),
          GestureDetector(
            onTap: onDeleteTap,
            child: CustomImageView(
              imagePath: ImageConstant.imgTrashOutline,
              width: 22.h,
              height: 22.h,
            ),
          ),
        ],
      ),
    );
  }

  void _onNewChatTapped(BuildContext context) {
    if (widget.onNavigateToRecommendation != null) {
      widget.onNavigateToRecommendation!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.recipeRecommendationScreen,
        (route) => false,
      );
    }
  }

  void _onRecipeBoardTapped(BuildContext context) {
    if (widget.onNavigateToBoard != null) {
      widget.onNavigateToBoard!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.recipeBoardScreen,
        (route) => false,
      );
    }
  }

  void _onRecipeCreateTapped(BuildContext context) {}
}
