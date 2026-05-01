import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/mock_data_service.dart';
import '../../models/chat_room.dart';
import '../../services/naengo_api_service.dart';
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

class _RecipeManagementScreenState extends State<RecipeManagementScreen> {
  bool _isChatExpanded = false;

  /// 백엔드에서 채팅방 목록을 fetching 중인지.
  bool _isLoadingRooms = false;

  /// 마지막 fetch 실패 사유 (null = 성공 또는 아직 시도 안 함).
  String? _loadError;

  @override
  void initState() {
    super.initState();
    // 패널 열리자마자 백엔드 동기화 — 이전 채팅들이 즉시 표시되도록.
    _refreshRoomsFromServer();
  }

  /// 백엔드에서 채팅방 목록을 새로 받아와 `MockDataService` cache 갱신.
  /// 실패해도 앱 죽이지 않고 기존 cache 그대로 보여줌 + 작은 에러 안내.
  Future<void> _refreshRoomsFromServer() async {
    setState(() {
      _isLoadingRooms = true;
      _loadError = null;
    });
    try {
      final rooms = await NaengoApi.listRooms();
      if (!mounted) return;
      MockDataService.mergeServerRooms(rooms);
      setState(() => _isLoadingRooms = false);
    } catch (e, st) {
      debugPrint('[Sidebar] listRooms 실패: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isLoadingRooms = false;
        _loadError = '목록 동기화 실패';
      });
    }
  }

  void _toggleChatExpand() {
    setState(() => _isChatExpanded = !_isChatExpanded);
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
      backgroundColor: appTheme.verylight,
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
            _buildChatHeader(),
            if (_isChatExpanded) Expanded(child: _buildChatList()),
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
              color: appTheme.mainUI,
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
          color: isActive ? appTheme.mainUI : Colors.transparent,
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
                color: isActive ? Colors.white : appTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // '내 채팅' 헤더 (접기/펼치기 토글) — 고정 영역
  Widget _buildChatHeader() {
    return GestureDetector(
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
                color: appTheme.mainUI,
              ),
            ),
            // 로딩 중일 때만 작은 스피너 표시 (수동 새로고침 버튼은 없음 —
            // 패널 열 때마다 자동 동기화)
            if (_isLoadingRooms) ...[
              SizedBox(width: 8.h),
              SizedBox(
                width: 12.h,
                height: 12.h,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(appTheme.mainUI),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 채팅방 목록 — 이 영역만 스크롤 (펼쳐진 경우에만 그려짐)
  Widget _buildChatList() {
    final rooms = MockDataService.chatRooms;

    // 첫 로딩 중에 cache 도 비어있으면 로딩 인디케이터만 표시.
    // (cache 가 있으면 일단 보여주고 백그라운드에서 갱신 — 깜빡임 방지)
    if (_isLoadingRooms && rooms.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: 60.h, top: 12.h),
        child: Row(
          children: [
            SizedBox(
              width: 14.h,
              height: 14.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(appTheme.mainUI),
              ),
            ),
            SizedBox(width: 8.h),
            Text(
              '채팅방 불러오는 중…',
              style: TextStyleHelper.instance.body15BoldNanumSquareAc.copyWith(
                color: appTheme.mainUI.withAlpha(150),
                fontSize: 12.fSize,
              ),
            ),
          ],
        ),
      );
    }

    if (rooms.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: 60.h, top: 8.h, bottom: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '채팅 기록이 없습니다',
              style: TextStyleHelper.instance.body15BoldNanumSquareAc
                  .copyWith(color: appTheme.mainUI.withAlpha(100)),
            ),
            if (_loadError != null) ...[
              SizedBox(height: 4.h),
              Text(
                '⚠️ $_loadError',
                style: TextStyle(
                  fontSize: 11.fSize,
                  color: appTheme.mainUI.withAlpha(150),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Scrollbar(
      child: ListView.builder(
        padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
        itemCount: rooms.length + (_loadError != null ? 1 : 0),
        itemBuilder: (context, index) {
          // cache 는 있는데 fetch 실패한 경우 — 마지막에 안내 한 줄
          if (_loadError != null && index == rooms.length) {
            return Padding(
              padding: EdgeInsets.only(left: 60.h, top: 8.h, bottom: 8.h),
              child: Text(
                '⚠️ $_loadError (캐시 표시 중)',
                style: TextStyle(
                  fontSize: 11.fSize,
                  color: appTheme.mainUI.withAlpha(150),
                ),
              ),
            );
          }
          return _buildRoomItem(rooms[index]);
        },
      ),
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
          color: isCurrent ? appTheme.mainUI : Colors.transparent,
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
                  color: isCurrent ? Colors.white : appTheme.text,
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
