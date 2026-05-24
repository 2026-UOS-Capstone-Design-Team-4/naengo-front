import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/mock_data_service.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../models/recipe.dart';
import '../../models/recipe_item.dart';
import '../../services/camera_service.dart';
import '../../services/auth_service.dart';
import '../../services/naengo_api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_image_view.dart';
import '../recipe_detail_screen/recipe_detail_screen.dart';
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

  /// 비로그인 상태에서 사용자가 보낸 메시지가 20개 이상이면 true.
  bool get _isGuestLimitReached =>
      !AuthServiceLocator.instance.isLoggedIn &&
      _messages.where((m) => m.isMe).length >= 20;

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
    if (_isGuestLimitReached) return;

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

    // ── 4. SSE 스트림 — 로그인 여부로 분기 ──
    final isLoggedIn = AuthServiceLocator.instance.isLoggedIn;
    final Stream<ChatEvent> stream;
    if (!isLoggedIn) {
      // 비로그인: 서버에 방을 만들지 않고 게스트 엔드포인트 사용.
      // 현재 메시지 이전 대화를 history로 전달 (마지막 2개 = user+AI placeholder 제외).
      stream = NaengoApi.guestChat(
        prompt: prompt,
        imageDataUrl: imageDataUrl,
        history: _buildGuestHistory(),
      );
    } else if (_serverRoomId == null) {
      stream = NaengoApi.createRoomAndChat(
        prompt: prompt,
        imageDataUrl: imageDataUrl,
      );
    } else {
      stream = NaengoApi.sendInRoom(
        roomId: _serverRoomId!,
        prompt: prompt,
        imageDataUrl: imageDataUrl,
      );
    }

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
          // AI 메시지 버블 아래에 레시피 카드들이 붙음
          aiMessage.recipes = event.recipes;
          setState(() {});

          // 팁이 있으면 카드 다음에 별도 AI 채팅 버블로 추가
          final tipsText = _formatRecipesTips(event.recipes);
          if (tipsText.isNotEmpty) {
            _addMessage(ChatMessage(
              text: tipsText,
              isMe: false,
              sentAt: DateTime.now(),
              isStreaming: false,
            ));
            _scrollToBottom();
          }
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

  /// 게스트 채팅 history 생성.
  /// _messages 에서 현재 전송 중인 user 메시지 + AI placeholder(마지막 2개) 제외,
  /// 최대 20개까지만 포함 (API 제한).
  List<Map<String, String>> _buildGuestHistory() {
    final end = _messages.length - 2;
    if (end <= 0) return const [];
    final start = end > 20 ? end - 20 : 0;
    return _messages.sublist(start, end).map((m) {
      return {
        'role': m.isMe ? 'user' : 'assistant',
        'content': m.text,
      };
    }).toList();
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
                    child: _buildMessageText(message),
                  ),
                // AI 응답에 추천 레시피가 있으면 카드로 표시 (탭하면 상세화면)
                if (!message.isMe && message.hasRecipes) ...[
                  SizedBox(height: 8.h),
                  _buildRecipeCards(message.recipes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AI 메시지 아래에 붙는 레시피 카드 묶음 — 탭하면 상세화면으로 이동.
  ///
  /// 한 줄에 한 개씩 세로로 쌓되, 좌우 폭은 채팅 버블과 비슷하게 컴팩트하게 유지.
  Widget _buildRecipeCards(List<Recipe> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < recipes.length; i++) ...[
          if (i > 0) SizedBox(height: 6.h),
          _buildRecipeCard(recipes[i]),
        ],
      ],
    );
  }

  /// 클릭 가능한 레시피 카드 한 장. 게시판 카드의 컴팩트 버전.
  ///
  /// `GestureDetector` 대신 `Material` + `InkWell` 조합 사용:
  ///   - ListView 의 스크롤 제스처와 제대로 cooperation → 탭이 누락되는 일 줄어듦
  ///   - Material 디자인 ripple 피드백 (탭 시 빨강 잔물결)
  /// 외곽의 그림자는 Material 의 elevation 으로 완전히 대체하면 색감이 바뀌므로,
  /// shadow 만 별도 Container 로 감싸서 유지.
  Widget _buildRecipeCard(Recipe r) {
    return Container(
      constraints: BoxConstraints(maxWidth: 260.h),
      decoration: BoxDecoration(
        // 그림자만 여기서 — 내부 Material 위에 띄움
        borderRadius: BorderRadius.circular(14.h),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5252).withAlpha(28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.h),
        clipBehavior: Clip.antiAlias, // 카드 모서리 밖으로 ripple 새지 않게
        child: InkWell(
          onTap: () { _navigateToRecipeDetail(r); },
          splashColor: const Color(0xFFFF5252).withAlpha(40),
          highlightColor: const Color(0xFFFF5252).withAlpha(15),
          child: Container(
            padding: EdgeInsets.all(10.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFFF5252).withAlpha(80),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(14.h),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 썸네일 — image_url 있으면 이미지, 없으면 기본 아이콘
                Container(
                  width: 44.h,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB3B3),
                    borderRadius: BorderRadius.circular(10.h),
                  ),
                  child: (r.imageUrl != null && r.imageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.h),
                          child: Image.network(
                            r.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.restaurant_rounded,
                                size: 22.h,
                                color: Colors.white.withAlpha(220),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            size: 22.h,
                            color: Colors.white.withAlpha(220),
                          ),
                        ),
                ),
                SizedBox(width: 10.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r.title,
                        style: TextStyleHelper.instance.body15BoldNanumSquareAc
                            .copyWith(
                          fontSize: 13.fSize,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        r.ingredientsRaw.isNotEmpty
                            ? r.ingredientsRaw
                            : '재료 정보 없음',
                        style: TextStyle(
                          fontSize: 10.fSize,
                          color: const Color(0xFF999999),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 화살표 — 탭 가능함을 시각적 신호
                Icon(
                  Icons.chevron_right,
                  size: 18.h,
                  color: const Color(0xFFFF5252).withAlpha(180),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 채팅 SSE RecipeResponse에는 is_liked/is_scrapped/counts가 없으므로,
  /// 단건 조회 API로 최신 상태를 가져온 뒤 상세 화면으로 이동한다.
  Future<void> _navigateToRecipeDetail(Recipe r) async {
    Recipe full;
    try {
      full = await NaengoApi.getRecipe(r.id);
    } catch (_) {
      full = r;
    }
    if (!mounted) return;
    final item = RecipeItem(
      recipeId: full.id,
      title: full.title,
      description: full.description,
      ingredientsRaw: full.ingredientsRaw,
      ingredientsList: full.ingredients.map((i) {
        final note = (i.note ?? '').trim();
        final base = '${i.name} ${i.amount}${i.unit}'.trim();
        return note.isEmpty ? base : '$base ($note)';
      }).toList(),
      cookingSteps: full.instructions,
      imageUrl: full.imageUrl,
      source: full.authorType == 'USER' ? 'USER' : 'STANDARD',
      status: 'APPROVED',
      createdAt: full.createdAt ?? DateTime.now(),
      likesCount: full.likesCount,
      scrapCount: full.scrapCount,
      isLiked: full.isLiked,
      isBookmarked: full.isScrapped,
    );
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a, b) => RecipeDetailScreen(recipe: item),
        transitionsBuilder: (c, a, b, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  /// 메시지 텍스트 위젯. AI 응답에는 간단한 마크다운(`**bold**`, `# heading`) 적용.
  /// 사용자 메시지엔 그대로 — 입력한 그대로 보여줘야 헷갈림 없음.
  Widget _buildMessageText(ChatMessage message) {
    final text = message.text.isEmpty && message.isStreaming
        ? '…'
        : message.text;
    final baseStyle = TextStyleHelper.instance.body15MediumNotoSansKR
        .copyWith(fontSize: 12.fSize);

    if (message.isMe) {
      return Text(text, style: baseStyle);
    }
    return Text.rich(
      TextSpan(children: _parseSimpleMarkdown(text, baseStyle)),
    );
  }

  /// 채팅 AI 응답용 초경량 마크다운 파서.
  ///   - 줄 시작 `# `, `## `, `### ` → 헤딩 (각각 +3 / +2 / +1 폰트 크기)
  ///   - 인라인 `**...**` → 볼드 (FontWeight.w800)
  /// 그 외(이탤릭, 코드 블록, 링크, 리스트 등)는 그대로 출력 — 채팅 응답에선 거의 안 나옴.
  ///
  /// 스트리밍 중에 마크다운이 미완성이면(`**hel` 처럼 닫는 `**` 없음) 그냥 plain 으로 표시.
  /// 다음 청크에 닫는 `**` 가 도착하면 자동으로 볼드 적용 — 자연스러운 점진적 렌더.
  List<InlineSpan> _parseSimpleMarkdown(String text, TextStyle baseStyle) {
    if (text.isEmpty) return [TextSpan(text: text, style: baseStyle)];

    final spans = <InlineSpan>[];
    final lines = text.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final headingMatch = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(line);

      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final content = headingMatch.group(2)!;
        // # → +3, ## → +2, ### → +1 (heading level 작을수록 큼)
        final extra = (4 - level).toDouble();
        final headingStyle = baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 12.fSize) + extra,
          fontWeight: FontWeight.w800,
          height: 1.5,
        );
        spans.addAll(_parseInlineBold(content, headingStyle));
      } else {
        spans.addAll(_parseInlineBold(line, baseStyle));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  /// `**bold**` 부분만 볼드 처리, 나머지는 base style 그대로.
  List<InlineSpan> _parseInlineBold(String text, TextStyle baseStyle) {
    if (text.isEmpty) return const [];

    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*'); // non-greedy
    var lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.w800),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }
    return spans;
  }

  /// 추천된 레시피들의 [Recipe.tips] 를 한국어 채팅 메시지로 묶어 반환.
  /// 모든 레시피의 팁이 비어있으면 빈 문자열 → 호출 측이 아무 메시지도 안 추가.
  ///
  /// 형식:
  ///   💡 김치두부찌개 팁
  ///   • 김치는 잘 익은 걸 쓰면 더 맛있어요.
  ///   • ...
  ///
  ///   💡 다른요리 팁
  ///   • ...
  String _formatRecipesTips(List<Recipe> recipes) {
    final buf = StringBuffer();
    for (final r in recipes) {
      if (r.tips.isEmpty) continue;
      if (buf.isNotEmpty) buf.write('\n\n');
      buf.write('💡 ${r.title} 팁\n');
      for (final tip in r.tips) {
        buf.write('• $tip\n');
      }
    }
    return buf.toString().trimRight();
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

  Widget _buildGuestLimitBanner() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.h),
          decoration: BoxDecoration(
            color: appTheme.maximumlight,
            borderRadius: BorderRadius.circular(16.h),
            border: Border.all(color: appTheme.mainUI.withAlpha(80)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '게스트 채팅은 20개까지만 이용할 수 있어요.',
                style: TextStyle(
                  fontSize: 13.fSize,
                  color: appTheme.text,
                  fontFamily: 'Noto Sans KR',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.loginScreen),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.mainUI,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.h),
                    ),
                  ),
                  child: Text(
                    '로그인하고 계속하기',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.fSize,
                      fontFamily: 'Noto Sans KR',
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

  Widget _buildInputArea(BuildContext context) {
    if (_isGuestLimitReached) return _buildGuestLimitBanner();

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
