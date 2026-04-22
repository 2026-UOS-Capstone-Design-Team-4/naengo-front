import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/mock_data_service.dart';
import '../../models/chat_room.dart';
import '../../widgets/custom_image_view.dart';

class RecipeManagementScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final String? activeRoute;
  final String? currentRoomId; // 현재 열려 있는 채팅방 ID (채팅 화면에서만 전달)
  final VoidCallback? onNavigateToRecommendation;
  final VoidCallback? onNavigateToBoard;
  final void Function(ChatRoom room)? onNavigateToRoom;

  const RecipeManagementScreen({
    super.key,
    this.onClose,
    this.activeRoute,
    this.currentRoomId,
    this.onNavigateToRecommendation,
    this.onNavigateToBoard,
    this.onNavigateToRoom,
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
      value: 1.0,
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

  bool _isActive(String route) => widget.activeRoute == route;

  void _deleteRoom(String roomId) {
    setState(() => MockDataService.removeRoom(roomId));
  }

  void _openRoom(ChatRoom room) {
    if (widget.onNavigateToRoom != null) {
      widget.onNavigateToRoom!(room);
    }
  }

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
              onTap: () {
                if (widget.onNavigateToRecommendation != null) {
                  widget.onNavigateToRecommendation!();
                }
              },
            ),
            SizedBox(height: 8.h),
            _buildMenuItem(
              iconPath: ImageConstant.imgRed50024x24,
              title: '레시피 게시판',
              isActive: _isActive(AppRoutes.recipeBoardScreen),
              onTap: () {
                if (widget.onNavigateToBoard != null) {
                  widget.onNavigateToBoard!();
                }
              },
            ),
            SizedBox(height: 8.h),
            _buildMenuItem(
              iconPath: ImageConstant.imgPencilSharp,
              title: '레시피 작성하기',
              isActive: false,
              onTap: () {},
            ),
            SizedBox(height: 8.h),
            _buildChatSection(),
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
          onTap: widget.onClose,
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

  Widget _buildChatSection() {
    final rooms = MockDataService.chatRooms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 내 채팅 헤더
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

        // 채팅방 목록
        SizeTransition(
          sizeFactor: _chatExpandAnimation,
          child: rooms.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(left: 60.h, top: 8.h, bottom: 8.h),
                  child: Text(
                    '채팅 기록이 없습니다',
                    style: TextStyleHelper.instance.body15BoldNanumSquareAc
                        .copyWith(color: appTheme.red_500.withAlpha(100)),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4.h),
                    ...rooms.map((room) => _buildRoomItem(room)),
                    SizedBox(height: 8.h),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildRoomItem(ChatRoom room) {
    final isCurrent = room.roomId == widget.currentRoomId;

    return GestureDetector(
      onTap: isCurrent ? null : () => _openRoom(room),
      child: Container(
        margin: EdgeInsets.only(right: 50.h, bottom: 4.h),
        padding: EdgeInsets.only(
          top: 8.h,
          bottom: 8.h,
          left: 60.h,
          right: 12.h,
        ),
        decoration: BoxDecoration(
          color: isCurrent ? appTheme.red_500 : Colors.transparent,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(14.h),
            bottomRight: Radius.circular(14.h),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                room.title,
                style: TextStyleHelper.instance.body15BoldNanumSquareAc.copyWith(
                  color: isCurrent ? Colors.white : appTheme.black_900_01,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 현재 방은 삭제 버튼 숨김
            if (!isCurrent)
              GestureDetector(
                onTap: () => _deleteRoom(room.roomId),
                child: Padding(
                  padding: EdgeInsets.only(left: 8.h),
                  child: CustomImageView(
                    imagePath: ImageConstant.imgTrashOutline,
                    width: 20.h,
                    height: 20.h,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
