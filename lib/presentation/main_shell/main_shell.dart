import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../recipe_board_screen/recipe_board_screen.dart';
import '../recipe_management_screen/recipe_management_screen.dart';
import '../recipe_recommendation_screen/recipe_recommendation_screen.dart';

enum _MainPage { recommendation, board }

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  _MainPage _currentPage = _MainPage.recommendation;
  bool _initialPageSet = false;

  late AnimationController _panelController;
  bool _isPanelOpen = false;

  // 왼쪽 가장자리에서만 스와이프 열기 트리거되는 영역 너비
  static const double _kEdgeDragWidth = 44.0;
  bool _isEdgeDrag = false; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialPageSet) {
      _initialPageSet = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['page'] == 'board') {
        _currentPage = _MainPage.board;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  void _openPanel() {
    setState(() => _isPanelOpen = true);
    _panelController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _closePanel() {
    _panelController
        .animateTo(
          0.0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (mounted) setState(() => _isPanelOpen = false);
        });
  }

  // ── 제스처 핸들러 ──────────────────────────────────────────────────────────

  void _onEdgeDragStart(DragStartDetails _) {
    if (_isPanelOpen) return;
    _isEdgeDrag = true;
    setState(() => _isPanelOpen = true);
    _panelController.value = 0.0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final panelWidth = MediaQuery.of(context).size.width * 0.82;
    final delta = details.delta.dx / panelWidth;
    _panelController.value = (_panelController.value + delta).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isEdgeDrag) {
      // 엣지에서 시작한 스와이프는 속도/위치 무관하게 항상 열기
      _isEdgeDrag = false;
      _openPanel();
      return;
    }
    // 오버레이/패널에서의 드래그는 속도·위치 기반으로 닫기 판단
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 200 || (_panelController.value > 0.5 && velocity >= -200)) {
      _openPanel();
    } else {
      _closePanel();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────

  void _goToRecommendation() {
    _closePanel();
    setState(() => _currentPage = _MainPage.recommendation);
  }

  void _goToBoard() {
    _closePanel();
    setState(() => _currentPage = _MainPage.board);
  }

  String get _title {
    switch (_currentPage) {
      case _MainPage.recommendation:
        return '새 채팅';
      case _MainPage.board:
        return '레시피';
    }
  }

  String get _activeRoute {
    switch (_currentPage) {
      case _MainPage.recommendation:
        return AppRoutes.recipeRecommendationScreen;
      case _MainPage.board:
        return AppRoutes.recipeBoardScreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.of(context).size.width * 0.82;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: _currentPage == _MainPage.recommendation
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    appTheme.verylight,
                    appTheme.maximumlight,
                    appTheme.background,
                  ],
                ),
              )
            : BoxDecoration(color: appTheme.background),
        child: Stack(
          children: [
            // ── 메인 콘텐츠 ────────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  NaengoAppBar(
                    leadingIcon: ImageConstant.imgSidebarButton,
                    onLeadingPressed: _openPanel,
                    title: _title,
                    actionIcon: ImageConstant.imgPersonOutline,
                    onActionPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.profileSettingsScreen),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _currentPage.index,
                      children: const [
                        RecipeRecommendationScreen(),
                        RecipeBoardScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 왼쪽 엣지 감지 영역 (항상 존재, 오버레이/패널 아래) ────────
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _kEdgeDragWidth,
              child: GestureDetector(
                onHorizontalDragStart: _onEdgeDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                dragStartBehavior: DragStartBehavior.down,
                behavior: HitTestBehavior.translucent,
              ),
            ),

            // ── 딤 오버레이 — 탭 또는 좌측 스와이프로 닫기 ──────────────
            if (_isPanelOpen)
              AnimatedBuilder(
                animation: _panelController,
                builder: (context, _) => GestureDetector(
                  onTap: _closePanel,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: _panelController.value * 0.5,
                    ),
                  ),
                ),
              ),

            // ── 사이드바 패널 — 손가락과 함께 슬라이드 ───────────────────
            if (_isPanelOpen)
              AnimatedBuilder(
                animation: _panelController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                    (-1.0 + _panelController.value) * panelWidth,
                    0,
                  ),
                  child: child,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {},
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: _onDragEnd,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: panelWidth,
                      height: double.infinity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: Material(
                          elevation: 8,
                          child: RecipeManagementScreen(
                            onClose: _closePanel,
                            activeRoute: _activeRoute,
                            onNavigateToRecommendation: _goToRecommendation,
                            onNavigateToBoard: _goToBoard,
                            onNavigateToRoom: (room) {
                              _closePanel();
                              Navigator.of(context).pushNamed(
                                AppRoutes.chatInterfaceScreen,
                                arguments: room,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}
