import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/mock_data_service.dart';
import '../../models/chat_room.dart';
import '../../services/auth_service.dart';
import '../../services/naengo_api_service.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/naengo_snackbar.dart';

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
  bool get _isLoggedIn => AuthServiceLocator.instance.isLoggedIn;

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
    if (!_isLoggedIn) return; // 비로그인 시 서버 동기화 불필요
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

  /// 채팅방 삭제.
  ///   - 먼저 확인 다이얼로그를 띄움 (브랜드 톤)
  ///   - 확인 시: serverRoomId 있음 → 낙관적 로컬 제거 + 백엔드 `DELETE` 호출.
  ///             실패 시 롤백 (다시 목록에 끼워 넣음) + SnackBar 안내.
  ///   - serverRoomId 없음 → 아직 첫 메시지 안 보낸 로컬 전용 방. 로컬에서만 제거.
  Future<void> _deleteRoom(ChatRoom room) async {
    final confirmed = await _showDeleteConfirmDialog(room);
    if (!mounted || confirmed != true) return;

    // 낙관적 제거 — 즉시 UI 반영
    final previousRooms = List<ChatRoom>.from(MockDataService.chatRooms);
    setState(() => MockDataService.removeRoom(room.roomId));

    if (room.serverRoomId == null) return; // 로컬 전용 방이면 끝

    try {
      await NaengoApi.deleteRoom(room.serverRoomId!);
    } catch (e, st) {
      debugPrint('[Sidebar] deleteRoom 실패: $e\n$st');
      if (!mounted) return;
      // 백엔드 삭제 실패 → 로컬 상태 롤백 (사라졌던 방 다시 표시)
      setState(() {
        MockDataService.chatRooms = previousRooms;
      });
      NaengoSnackBar.show(
        context,
        '채팅방 삭제에 실패했어요. 잠시 후 다시 시도해주세요.',
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// 삭제 확인 다이얼로그. 사진 미리보기 다이얼로그와 동일한 브랜드 톤.
  Future<bool?> _showDeleteConfirmDialog(ChatRoom room) {
    const primary = Color(0xFFFF5252);   // 브랜드 빨강 (입력창 테두리, 환영 메시지)
    const tint = Color(0xFFFFF8F8);      // 살짝 분홍빛 배경 틴트
    const darkText = Color(0xFF1A1A1A);
    const subText = Color(0xFF666666);

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
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '채팅방을 삭제할까요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '"${room.title}"\n삭제하면 되돌릴 수 없어요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: subText,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        '취소',
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
                        '삭제',
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
                widget.onNavigateToRecommendation?.call();
              },
            ),
            SizedBox(height: 8.h),
            _buildMenuItem(
              iconPath: ImageConstant.imgRed50024x24,
              title: '레시피 게시판',
              isActive: _isActive(AppRoutes.recipeBoardScreen),
              onTap: () => widget.onNavigateToBoard?.call(),
            ),
            SizedBox(height: 8.h),
            _buildMenuItem(
              iconPath: ImageConstant.imgPencilSharp,
              title: '레시피 작성하기',
              isActive: false,
              disabled: !_isLoggedIn,
              onTap: () async {
                widget.onClose?.call();
                final submitted = await Navigator.pushNamed(
                  context,
                  AppRoutes.recipeWriteScreen,
                );
                if (!mounted) return;
                if (submitted == true) {
                  widget.onNavigateToBoard?.call();
                }
              },
            ),
            SizedBox(height: 8.h),
            if (_isLoggedIn) ...[
              _buildChatHeader(),
              if (_isChatExpanded) Expanded(child: _buildChatList()),
            ] else ...[
              _buildCurrentChatSection(),
            ],
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
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
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
              color: disabled
                  ? appTheme.disabled
                  : (isActive ? Colors.white : null),
            ),
            SizedBox(width: 10.h),
            Text(
              title,
              style: TextStyleHelper.instance.title18BoldNanumSquareAc.copyWith(
                color: disabled
                    ? appTheme.disabled
                    : (isActive ? Colors.white : appTheme.text),
              ),
            ),
            if (disabled) ...[
              SizedBox(width: 6.h),
              Icon(Icons.lock_outline, size: 14.h, color: appTheme.disabled),
            ],
          ],
        ),
      ),
    );
  }

  // 비로그인 전용 — 현재 채팅방 1개만 표시
  Widget _buildCurrentChatSection() {
    final rooms = MockDataService.chatRooms;
    if (rooms.isEmpty) return const SizedBox.shrink();

    final current = rooms.firstWhere(
      (r) => r.roomId == widget.currentRoomId,
      orElse: () => rooms.first,
    );
    final isCurrent = current.roomId == widget.currentRoomId;

    return GestureDetector(
      onTap: isCurrent ? null : () => _openRoom(current),
      child: Container(
        margin: EdgeInsets.only(
          left: isCurrent ? 0 : 12.h,
          right: 50.h,
        ),
        padding: EdgeInsets.only(
          left: isCurrent ? 26.h : 14.h,
          right: 14.h,
          top: 12.h,
          bottom: 12.h,
        ),
        decoration: BoxDecoration(
          color: isCurrent ? appTheme.mainUI : Colors.transparent,
          borderRadius: isCurrent
              ? BorderRadius.only(
                  topRight: Radius.circular(14.h),
                  bottomRight: Radius.circular(14.h),
                )
              : BorderRadius.zero,
        ),
        child: Row(
          children: [
            CustomImageView(
              imagePath: ImageConstant.img24x24,
              width: 24.h,
              height: 24.h,
              color: isCurrent ? Colors.white : null,
            ),
            SizedBox(width: 10.h),
            Expanded(
              child: Text(
                '현재 채팅: ${current.title}',
                style: TextStyleHelper.instance.title18BoldNanumSquareAc
                    .copyWith(color: isCurrent ? Colors.white : appTheme.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                onTap: () => _deleteRoom(room),
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
