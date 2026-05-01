import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/mock_data_service.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../models/recipe.dart';
import '../../services/camera_service.dart';
import '../../services/naengo_api_service.dart';
import '../../widgets/custom_app_bar.dart';
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

  /// Naengo 백엔드가 부여한 정수 room_id.
  /// `null` 이면 아직 첫 메시지를 안 보낸 상태 → POST /rooms 로 새 방 생성.
  /// 값이 있으면 POST /rooms/{id} 로 기존 방에 메시지 전송.
  int? _serverRoomId;

  /// 현재 활성 SSE 스트림 구독. 화면이 dispose 되거나 새 메시지 보낼 때 cancel.
  StreamSubscription<ChatEvent>? _activeStream;

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
      // 기존 채팅방으로 이동 — 저장된 메시지 + 백엔드 room_id 복원
      _currentRoom = args;
      _titleUpdated = true;
      _serverRoomId = args.serverRoomId;
      _messages = MockDataService.getMessages(_currentRoom.roomId);

      // 백엔드에 등록된 방이면 최신 내역을 가져옴 (캐시는 우선 노출).
      // 실패 시엔 기존 캐시 그대로 두고 조용히 로그만 남김.
      if (_serverRoomId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadHistoryFromServer(_serverRoomId!);
        });
      }
    } else {
      // 새 채팅방 생성
      _currentRoom = MockDataService.createRoom();
      _messages = MockDataService.getMessages(_currentRoom.roomId);

      // 진입 인자에 따라 첫 메시지 자동 전송
      if (args is String && args.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendInitialMessage(args);
        });
      } else if (args is Map && args['imagePath'] is String) {
        // 홈 화면에서 카메라로 찍고 진입 — 이미지를 첫 메시지로 전송
        final path = args['imagePath'] as String;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendChat(imageFile: File(path));
        });
      }
    }
  }

  @override
  void dispose() {
    _activeStream?.cancel();
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

  /// 텍스트 전송 — 입력창에서 종이비행기 버튼 눌렀을 때.
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;
    _messageController.clear();
    await _sendChat(text: text);
  }

  /// 텍스트 / 이미지 / 둘 다 — 모든 메시지 송신의 단일 진입점.
  ///
  /// 흐름:
  ///   1. 사용자 메시지를 즉시 채팅창에 추가
  ///   2. AI 응답용 빈 메시지(스트리밍 자리표시자) 추가
  ///   3. Naengo API 스트림 구독 → 청크가 도착할 때마다 AI 메시지에 누적
  ///   4. 첫 메시지면 `_serverRoomId` 가 채워지고, 이후 같은 방으로 라우팅
  Future<void> _sendChat({String text = '', File? imageFile}) async {
    if (text.isEmpty && imageFile == null) return;
    if (_isLoading) return;

    // ── 1. 사용자 메시지 추가 ──
    _addMessage(ChatMessage(
      text: text,
      isMe: true,
      sentAt: DateTime.now(),
      imagePath: imageFile?.path,
    ));

    // 첫 메시지면 방 제목 업데이트 (텍스트 우선, 사진만이면 별도 문구)
    final titleSeed = text.isNotEmpty
        ? text
        : (imageFile != null ? '사진으로 재료 인식' : '');
    if (titleSeed.isNotEmpty) _maybeUpdateTitle(titleSeed);

    // ── 2. AI 답변 자리표시자 (청크가 누적될 곳) ──
    final aiMessage = ChatMessage(
      isMe: false,
      sentAt: DateTime.now(),
      isStreaming: true,
    );
    _addMessage(aiMessage);

    setState(() => _isLoading = true);
    _scrollToBottom();

    // ── 3. 이미지가 있으면 base64 data URL 변환 ──
    String? imageDataUrl;
    if (imageFile != null) {
      try {
        imageDataUrl = await NaengoApi.encodeImageAsDataUrl(imageFile);
      } catch (e) {
        _finishStreamingWithError(aiMessage, '사진 처리 실패: $e');
        return;
      }
    }

    // 사진만 보낼 땐 백엔드에 줄 기본 prompt
    final prompt = text.isNotEmpty
        ? text
        : '사진 속 재료로 만들 수 있는 요리를 추천해주세요.';

    // ── 4. SSE 스트림 — 첫 메시지면 새 방, 아니면 기존 방 ──
    final stream = _serverRoomId == null
        ? NaengoApi.createRoomAndChat(
            prompt: prompt,
            imageDataUrl: imageDataUrl,
          )
        : NaengoApi.sendInRoom(
            roomId: _serverRoomId!,
            prompt: prompt,
            imageDataUrl: imageDataUrl,
          );

    await _activeStream?.cancel();

    var firstChunk = true;
    _activeStream = stream.listen(
      (event) {
        if (!mounted) return;
        if (event is RoomCreated) {
          _serverRoomId = event.roomId;
          // 다음 진입 시 같은 방으로 라우팅하도록 로컬 ChatRoom 에도 보존
          MockDataService.updateServerRoomId(
            _currentRoom.roomId,
            event.roomId,
          );
          _currentRoom = _currentRoom.copyWith(serverRoomId: event.roomId);
        } else if (event is MessageChunk) {
          // 첫 청크 도착 → 로딩 인디케이터 끄고 AI 버블 노출
          if (firstChunk) {
            firstChunk = false;
            setState(() => _isLoading = false);
          }
          aiMessage.text += event.content;
          setState(() {});
          _scrollToBottom();
        } else if (event is RecipesReceived) {
          aiMessage.recipes = event.recipes;
          setState(() {});
        } else if (event is ChatStreamError) {
          _finishStreamingWithError(aiMessage, event.message);
        }
      },
      onDone: () {
        if (!mounted) return;
        aiMessage.isStreaming = false;
        if (aiMessage.text.isEmpty) {
          aiMessage.text = '응답을 받지 못했어요. 다시 시도해주세요.';
        }
        setState(() => _isLoading = false);
        _scrollToBottom();
      },
      onError: (Object e) {
        if (!mounted) return;
        _finishStreamingWithError(aiMessage, e.toString());
      },
    );
  }

  /// 백엔드에서 채팅방 메시지 내역을 받아와 캐시 교체.
  /// 진입 시 1회 호출. 실패 시 기존 캐시 유지 + 디버그 로그.
  ///
  /// ⚠️ 백엔드는 텍스트 content 만 저장하므로 사용자가 과거에 보낸 사진은
  ///    내역에서 사라짐 (현재 v1 제약).
  Future<void> _loadHistoryFromServer(int roomId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final history = await NaengoApi.getRoomHistory(roomId);
      if (!mounted) return;
      MockDataService.replaceMessages(_currentRoom.roomId, history);
      // replaceMessages 가 새 List 인스턴스를 만들므로 참조를 다시 받아야 함.
      _messages = MockDataService.getMessages(_currentRoom.roomId);
      setState(() => _isLoading = false);
      _scrollToBottom();
    } catch (e, st) {
      debugPrint('[Chat] history load 실패: $e\n$st');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// 스트리밍 실패 시 자리표시자 메시지를 에러 안내로 마무리.
  void _finishStreamingWithError(ChatMessage msg, String reason) {
    msg.text = msg.text.isEmpty
        ? '오류가 발생했습니다. 잠시 후 다시 시도해주세요.\n($reason)'
        : '${msg.text}\n\n— 응답 중단됨 ($reason)';
    msg.isStreaming = false;
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  /// 카메라를 열어 사진 촬영 → 미리보기 → 확인 시 백엔드로 전송.
  /// Naengo API 가 멀티모달 지원 (`image` 필드에 base64 data URL) 이라 이미지 자체를 보냄.
  Future<void> _onCameraPressed() async {
    if (_isLoading) return;
    final photo = await CameraService.takePhoto();
    if (!mounted || photo == null) return;

    final file = File(photo.path);
    final confirmed = await _showPhotoPreview(file);
    if (!mounted || confirmed != true) return;

    // 입력창에 캡션을 입력했다면 같이 보낸다.
    final caption = _messageController.text.trim();
    _messageController.clear();

    await _sendChat(text: caption, imageFile: file);
  }

  Future<bool?> _showPhotoPreview(File file) {
    // 앱 브랜드 컬러. 채팅 입력창 테두리 / 환영 메시지와 동일.
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
                        '보내기',
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

  /// 홈 화면에서 텍스트를 들고 채팅방 진입했을 때.
  /// 통합된 `_sendChat` 를 그대로 재사용.
  Future<void> _sendInitialMessage(String text) async {
    await _sendChat(text: text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 메인 채팅 영역
          SafeArea(
            child: Column(
              children: [
                NaengoAppBar(
                  leadingIcon: ImageConstant.imgSidebarButton,
                  onLeadingPressed: _openPanel,
                  title: _currentRoom.title,
                  actionIcon: ImageConstant.imgPersonOutline,
                  onActionPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.profileSettingsScreen),
                ),
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
          Icon(Icons.chat_bubble_outline, size: 48, color: appTheme.cloudy.withAlpha(127)),
          SizedBox(height: 12.h),
          Text(
            '냉고에게 무엇이든 물어보세요!',
            style: TextStyleHelper.instance.body15MediumNotoSansKR.copyWith(
              color: appTheme.cloudy.withAlpha(127),
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
              color: appTheme.basis,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'AI',
                style: TextStyle(
                  color: appTheme.background,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.h),
            decoration: BoxDecoration(
              color: appTheme.verylight,
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
                    valueColor: AlwaysStoppedAnimation<Color>(appTheme.basis),
                  ),
                ),
                SizedBox(width: 8.h),
                Text(
                  '답변 생성 중...',
                  style: TextStyleHelper.instance.body15MediumNotoSansKR
                      .copyWith(color: appTheme.basis, fontSize: 12.fSize),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMessageBubble(ChatMessage message) {
    // 첫 청크가 도착하기 전엔 자리표시자 AI 버블을 그리지 않는다.
    // 하단의 "답변 생성 중..." 인디케이터(_buildLoadingBubble) 만 보이도록.
    // 첫 청크가 들어오면 text 가 채워지므로 자연스럽게 버블이 등장.
    if (!message.isMe &&
        !message.hasText &&
        !message.hasImage &&
        message.isStreaming) {
      return const SizedBox.shrink();
    }

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
                color: appTheme.basis,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: appTheme.background,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // 이미지 첨부가 있으면 사진 → 그 아래 캡션 텍스트 (있을 때만)
                if (message.hasImage) ...[
                  GestureDetector(
                    onTap: () => _showFullImage(message.imagePath!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(message.imagePath!),
                        width: 220.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (message.hasText) SizedBox(height: 6.h),
                ],
                // 텍스트 버블 — 사진만 보낸 경우엔 생략
                if (message.hasText || (!message.isMe && !message.hasImage))
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.h,
                      horizontal: 14.h,
                    ),
                    decoration: BoxDecoration(
                      color: message.isMe ? appTheme.lightbasis : appTheme.verylight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(message.isMe ? 20.0 : 4.0),
                        topRight: const Radius.circular(20.0),
                        bottomLeft: const Radius.circular(20.0),
                        bottomRight:
                            Radius.circular(message.isMe ? 4.0 : 20.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: appTheme.basis.withAlpha(51),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text.isEmpty && message.isStreaming
                          ? '…'
                          : message.text,
                      style: TextStyleHelper.instance.body15MediumNotoSansKR
                          .copyWith(fontSize: 12.fSize),
                    ),
                  ),
                // AI 응답에 추천 레시피가 첨부됐으면 칩으로 표시
                if (!message.isMe && message.hasRecipes) ...[
                  SizedBox(height: 8.h),
                  _buildRecipeChips(message.recipes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AI 메시지에 첨부된 레시피들 — 가로 스크롤 칩.
  Widget _buildRecipeChips(List<Recipe> recipes) {
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        separatorBuilder: (_, __) => SizedBox(width: 6.h),
        itemBuilder: (_, i) {
          final r = recipes[i];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
            decoration: BoxDecoration(
              color: appTheme.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: appTheme.basis, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, size: 14, color: appTheme.basis),
                SizedBox(width: 4.h),
                Text(
                  r.title,
                  style: TextStyleHelper.instance.body15MediumNotoSansKR
                      .copyWith(
                    fontSize: 11.fSize,
                    color: appTheme.basis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 채팅에서 이미지 탭 시 전체화면으로 펼쳐 보기 (핀치 줌 가능).
  void _showFullImage(String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(
            child: Image.file(File(path), fit: BoxFit.contain),
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
            color: appTheme.background,
            borderRadius: BorderRadius.circular(30.h),
            border: Border.all(
              color: _isLoading ? appTheme.cloudy.withAlpha(127) : appTheme.mainUI,
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
                    color: appTheme.text,
                    fontSize: 12.fSize,
                  ),
                  decoration: InputDecoration(
                    hintText: '냉고에게 물어보세요',
                    hintStyle: TextStyleHelper.instance.body15RegularNanumSquareAc
                        .copyWith(color: appTheme.cloudy.withAlpha(127), fontSize: 12.fSize),
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

