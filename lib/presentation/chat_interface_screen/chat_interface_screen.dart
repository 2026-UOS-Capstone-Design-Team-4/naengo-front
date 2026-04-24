import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/mock_data_service.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../services/api_service.dart';
import '../../services/camera_service.dart';
import '../../services/vision_service.dart';
import '../../widgets/custom_image_view.dart';
import '../recipe_management_screen/recipe_management_screen.dart';

class ChatInterfaceScreen extends StatefulWidget {
  const ChatInterfaceScreen({super.key});

  @override
  State<ChatInterfaceScreen> createState() => _ChatInterfaceScreenState();
}

class _ChatInterfaceScreenState extends State<ChatInterfaceScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _panelAnimationController;
  late Animation<Offset> _panelSlideAnimation;
  late Animation<double> _overlayFadeAnimation;

  bool _isPanelOpen = false;
  bool _isLoading = false;
  bool _didInitialize = false;
  bool _titleUpdated = false; // 첫 메시지로 방 제목 한 번만 업데이트

  late ChatRoom _currentRoom;
  // MockDataService에서 로드한 뒤 같은 참조를 유지
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _panelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _panelSlideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _panelAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _overlayFadeAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _panelAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    _didInitialize = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is ChatRoom) {
      // 기존 채팅방으로 이동 — 저장된 메시지 로드
      _currentRoom = args;
      _titleUpdated = true;
      _messages = MockDataService.getMessages(_currentRoom.roomId);
    } else {
      // 새 채팅방 생성
      _currentRoom = MockDataService.createRoom();
      _messages = MockDataService.getMessages(_currentRoom.roomId);

      if (args is String && args.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendInitialMessage(args);
        });
      } else if (args is Map &&
          args['imagePath'] is String &&
          (args['imagePath'] as String).isNotEmpty) {
        final path = args['imagePath'] as String;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendImageMessage(File(path));
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _panelAnimationController.dispose();
    super.dispose();
  }

  void _openPanel() {
    setState(() => _isPanelOpen = true);
    _panelAnimationController.forward();
  }

  void _closePanel() {
    _panelAnimationController.reverse().then((_) {
      if (mounted) setState(() => _isPanelOpen = false);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 첫 사용자 메시지로 채팅방 제목 업데이트
  void _maybeUpdateTitle(String text) {
    if (_titleUpdated) return;
    _titleUpdated = true;
    final title = text.length > 20 ? '${text.substring(0, 20)}…' : text;
    MockDataService.updateRoomTitle(_currentRoom.roomId, title);
    setState(() {
      _currentRoom = _currentRoom.copyWith(title: title);
    });
  }

  void _addMessage(ChatMessage message) {
    MockDataService.addMessage(_currentRoom.roomId, message);
    setState(() {}); // _messages는 같은 리스트 참조라 setState만 호출
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _maybeUpdateTitle(text);
    _addMessage(ChatMessage(text: text, isMe: true, sentAt: DateTime.now()));
    setState(() => _isLoading = true);
    _messageController.clear();
    _scrollToBottom();

    try {
      final reply = await ApiService.sendMessage(text);
      if (!mounted) return;
      _addMessage(ChatMessage(text: reply, isMe: false, sentAt: DateTime.now()));
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: '오류가 발생했습니다. 다시 시도해주세요.',
        isMe: false,
        sentAt: DateTime.now(),
      ));
      setState(() => _isLoading = false);
    }
    _scrollToBottom();
  }

  /// 카메라를 열어 사진 촬영 → 미리보기 → 확인 → Vision API 분석.
  Future<void> _onCameraPressed() async {
    if (_isLoading) return;
    final photo = await CameraService.takePhoto();
    if (!mounted || photo == null) return;

    final confirmed = await _showPhotoPreview(File(photo.path));
    if (!mounted || confirmed != true) return;

    await _sendImageMessage(File(photo.path));
  }

  /// 이미지 메시지 전송 → Vision API 호출 → AI 응답 추가.
  Future<void> _sendImageMessage(File imageFile) async {
    // 1. 사용자 쪽에 이미지 메시지 추가
    _addMessage(ChatMessage(
      isMe: true,
      sentAt: DateTime.now(),
      imagePath: imageFile.path,
    ));

    // 첫 이미지 메시지라면 방 제목을 업데이트 (파일명 대신 '사진 분석')
    if (!_titleUpdated) {
      _titleUpdated = true;
      MockDataService.updateRoomTitle(_currentRoom.roomId, '사진으로 재료 인식');
      setState(() {
        _currentRoom = _currentRoom.copyWith(title: '사진으로 재료 인식');
      });
    }

    setState(() => _isLoading = true);
    _scrollToBottom();

    // 2. Vision API 호출
    try {
      final ingredients = await VisionService.detectIngredients(imageFile);
      if (!mounted) return;

      final replyText = VisionService.formatAsMessage(ingredients);
      _addMessage(
        ChatMessage(text: replyText, isMe: false, sentAt: DateTime.now()),
      );
    } catch (e) {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: '사진을 분석하는 중에 문제가 생겼어요. 잠시 후 다시 시도해주세요.',
        isMe: false,
        sentAt: DateTime.now(),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<bool?> _showPhotoPreview(File file) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('다시 찍기'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('보내기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendInitialMessage(String text) async {
    _maybeUpdateTitle(text);
    _addMessage(ChatMessage(text: text, isMe: true, sentAt: DateTime.now()));
    setState(() => _isLoading = true);
    _scrollToBottom();

    try {
      final reply = await ApiService.sendMessage(text);
      if (!mounted) return;
      _addMessage(ChatMessage(text: reply, isMe: false, sentAt: DateTime.now()));
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: '오류가 발생했습니다. 다시 시도해주세요.',
        isMe: false,
        sentAt: DateTime.now(),
      ));
      setState(() => _isLoading = false);
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.white_A700_01,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 메인 채팅 영역
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: _messages.isEmpty && !_isLoading
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            vertical: 12.h,
                            horizontal: 16.h,
                          ),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length && _isLoading) {
                              return _buildLoadingBubble();
                            }
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                ),
                _buildInputArea(context),
              ],
            ),
          ),

          // 딤 오버레이 — 탭하면 사이드바 닫힘 (회색 영역)
          if (_isPanelOpen)
            AnimatedBuilder(
              animation: _overlayFadeAnimation,
              builder: (context, child) {
                return GestureDetector(
                  onTap: _closePanel,
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: _overlayFadeAnimation.value,
                    ),
                  ),
                );
              },
            ),

          // 사이드바 패널 — 내부 탭은 닫히지 않도록 GestureDetector로 흡수
          if (_isPanelOpen)
            SlideTransition(
              position: _panelSlideAnimation,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {}, // 패널 내부 빈 공간 탭 흡수
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.82,
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: Material(
                        elevation: 8,
                        child: _buildPanel(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPanel() {
    return RecipeManagementScreen(
      onClose: _closePanel,
      activeRoute: AppRoutes.chatInterfaceScreen,
      currentRoomId: _currentRoom.roomId,
      onNavigateToRoom: (room) {
        _closePanel();
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.chatInterfaceScreen,
          arguments: room,
        );
      },
      onNavigateToRecommendation: () {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.mainShell,
          (route) => false,
        );
      },
      onNavigateToBoard: () {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.mainShell,
          (route) => false,
          arguments: {'page': 'board'},
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: appTheme.red_200_7f),
          SizedBox(height: 12.h),
          Text(
            '냉고에게 무엇이든 물어보세요!',
            style: TextStyleHelper.instance.body15MediumNotoSansKR.copyWith(
              color: appTheme.red_200_7f,
              fontSize: 12.fSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32.h,
            height: 32.h,
            margin: EdgeInsets.only(right: 8.h),
            decoration: BoxDecoration(
              color: appTheme.red_A200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'AI',
                style: TextStyle(
                  color: appTheme.white_A700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.h),
            decoration: BoxDecoration(
              color: appTheme.red_50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4.0),
                topRight: Radius.circular(20.0),
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(appTheme.red_A200),
                  ),
                ),
                SizedBox(width: 8.h),
                Text(
                  '답변 생성 중...',
                  style: TextStyleHelper.instance.body15MediumNotoSansKR
                      .copyWith(color: appTheme.red_A200, fontSize: 12.fSize),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 14.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openPanel,
            child: CustomImageView(
              imagePath: ImageConstant.imgSidebarButton,
              width: 28.h,
              height: 24.h,
            ),
          ),
          SizedBox(width: 10.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                _currentRoom.title,
                style: TextStyleHelper.instance.title20ExtraBoldNanumSquareAc,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40.h,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5252).withAlpha(38),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: CustomImageView(
                  imagePath: ImageConstant.imgPersonOutline,
                  height: 24.h,
                  width: 24.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            Container(
              width: 32.h,
              height: 32.h,
              margin: EdgeInsets.only(right: 8.h),
              decoration: BoxDecoration(
                color: appTheme.red_A200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: appTheme.white_A700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: message.hasImage
                ? _buildImageBubble(message)
                : _buildTextBubble(message),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBubble(ChatMessage message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.h),
      decoration: BoxDecoration(
        color: message.isMe ? appTheme.red_100 : appTheme.red_50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(message.isMe ? 20.0 : 4.0),
          topRight: Radius.circular(20.0),
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(message.isMe ? 4.0 : 20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: appTheme.red_A200.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyleHelper.instance.body15MediumNotoSansKR
            .copyWith(fontSize: 12.fSize),
      ),
    );
  }

  Widget _buildImageBubble(ChatMessage message) {
    final radius = BorderRadius.only(
      topLeft: Radius.circular(message.isMe ? 20.0 : 4.0),
      topRight: Radius.circular(20.0),
      bottomLeft: Radius.circular(20.0),
      bottomRight: Radius.circular(message.isMe ? 4.0 : 20.0),
    );

    return Container(
      constraints: BoxConstraints(maxWidth: 220.h),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: appTheme.red_A200.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: GestureDetector(
          onTap: () => _showFullImage(message.imagePath!),
          child: Image.file(
            File(message.imagePath!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              padding: EdgeInsets.all(16.h),
              color: appTheme.red_50,
              child: Text(
                '이미지를 불러올 수 없습니다.',
                style: TextStyleHelper.instance.body15MediumNotoSansKR
                    .copyWith(fontSize: 12.fSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: InteractiveViewer(
          child: Center(
            child: Image.file(File(path)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
        child: Container(
          decoration: BoxDecoration(
            color: appTheme.white_A700,
            borderRadius: BorderRadius.circular(30.h),
            border: Border.all(
              color: _isLoading ? appTheme.red_200_7f : appTheme.red_500,
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _onCameraPressed,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 8.h),
                  child: Opacity(
                    opacity: _isLoading ? 0.4 : 1.0,
                    child: CustomImageView(
                      imagePath: ImageConstant.imgCamera,
                      width: 34.h,
                      height: 34.h,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  enabled: !_isLoading,
                  style: TextStyleHelper.instance.body15NanumSquareAc.copyWith(
                    color: appTheme.black_900,
                    fontSize: 12.fSize,
                  ),
                  decoration: InputDecoration(
                    hintText: '냉고에게 물어보세요',
                    hintStyle: TextStyleHelper.instance.body15RegularNanumSquareAc
                        .copyWith(color: appTheme.red_200_7f, fontSize: 12.fSize),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isLoading ? null : _sendMessage,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
                  child: Opacity(
                    opacity: _isLoading ? 0.4 : 1.0,
                    child: CustomImageView(
                      imagePath: ImageConstant.imgPaperplane,
                      width: 28.h,
                      height: 28.h,
                    ),
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

