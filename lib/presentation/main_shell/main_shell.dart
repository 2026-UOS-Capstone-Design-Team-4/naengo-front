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

class _MainShellState extends State<MainShell>
    with TickerProviderStateMixin {
  _MainPage _currentPage = _MainPage.recommendation;
  bool _initialPageSet = false;

  late AnimationController _panelController;
  late Animation<Offset> _panelSlide;
  late Animation<double> _overlayFade;
  bool _isPanelOpen = false;

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
    _panelSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic));
    _overlayFade = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _panelController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  void _openPanel() {
    setState(() => _isPanelOpen = true);
    _panelController.forward();
  }

  void _closePanel() {
    _panelController.reverse().then((_) {
      if (mounted) setState(() => _isPanelOpen = false);
    });
  }

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        // 현재 페이지에 맞는 배경을 앱바 영역까지 확장
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
            SafeArea(
              child: Column(
                children: [
                  // ── 앱바 ───────────────────────────────────
                  NaengoAppBar(
                    leadingIcon: ImageConstant.imgSidebarButton,
                    onLeadingPressed: _openPanel,
                    title: _title,
                    actionIcon: ImageConstant.imgPersonOutline,
                    onActionPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.profileSettingsScreen),
                  ),
                  // ── 화면 콘텐츠 (슬라이드 없음) ────────────
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

            // 딤 오버레이 — 탭하면 사이드바 닫힘 (회색 영역)
            if (_isPanelOpen)
              AnimatedBuilder(
                animation: _overlayFade,
                builder: (context, _) => GestureDetector(
                  onTap: _closePanel,
                  child: Container(
                    color: Colors.black.withValues(alpha: _overlayFade.value),
                  ),
                ),
              ),

            // 사이드바 패널 — 내부 탭은 닫히지 않도록 GestureDetector로 흡수
            if (_isPanelOpen)
              SlideTransition(
                position: _panelSlide,
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
