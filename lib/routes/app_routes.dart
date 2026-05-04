import 'package:flutter/material.dart';
import '../presentation/main_shell/main_shell.dart';
import '../presentation/recipe_recommendation_screen/recipe_recommendation_screen.dart';
import '../presentation/chat_interface_screen/chat_interface_screen.dart';
import '../presentation/recipe_management_screen/recipe_management_screen.dart';
import '../presentation/recipe_board_screen/recipe_board_screen.dart';
import '../presentation/profile_settings_screen/profile_settings_screen.dart';
import '../presentation/recipe_write_screen/recipe_write_screen.dart';

class AppRoutes {
  static const String mainShell = '/';
  static const String recipeRecommendationScreen = '/recipe_recommendation_screen';
  static const String chatInterfaceScreen = '/chat_interface_screen';
  static const String recipeManagementScreen = '/recipe_management_screen';
  static const String recipeBoardScreen = '/recipe_board_screen';
  static const String profileSettingsScreen = '/profile_settings_screen';
  static const String recipeWriteScreen = '/recipe_write_screen';
  static const String initialRoute = '/';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case mainShell:
        page = const MainShell();
        break;
      case recipeRecommendationScreen:
        page = const RecipeRecommendationScreen();
        break;
      case chatInterfaceScreen:
        page = const ChatInterfaceScreen();
        break;
      case recipeManagementScreen:
        page = const RecipeManagementScreen();
        break;
      case recipeBoardScreen:
        page = const RecipeBoardScreen();
        break;
      case profileSettingsScreen:
        page = const ProfileSettingsScreen();
        break;
      case recipeWriteScreen:
        page = const RecipeWriteScreen();
        break;
      default:
        page = const MainShell();
    }

    // ChatInterface: 아래에서 위로 슬라이드
    if (settings.name == chatInterfaceScreen) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
    }

    // RecipeWrite / ProfileSettings: 오른쪽에서 슬라이드
    if (settings.name == recipeWriteScreen ||
        settings.name == profileSettingsScreen) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
    }

    // 기본: 애니메이션 없음 (Shell 내부 전환은 Shell이 처리)
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
      transitionDuration: Duration.zero,
    );
  }
}
