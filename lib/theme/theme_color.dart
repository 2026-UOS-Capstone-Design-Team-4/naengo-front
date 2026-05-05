import 'package:flutter/material.dart';

String _appTheme = "lightCode";
AppColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();

/// Helper class for managing themes and colors.

// ignore_for_file: must_be_immutable
class ThemeHelper {
  // A map of custom color themes supported by the app
  final Map<String, AppColors> _supportedCustomColor = {
    'lightCode': AppColors(),
  };

  // A map of color schemes supported by the app
  final Map<String, ColorScheme> _supportedColorScheme = {
    'lightCode': ColorSchemes.lightCodeColorScheme,
  };

  /// Changes the app theme to [newTheme].
  void changeTheme(String newTheme) {
    _appTheme = newTheme;
  }

  /// Returns the lightCode colors for the current theme.
  AppColors _getThemeColors() {
    return _supportedCustomColor[_appTheme] ?? AppColors();
  }

  /// Returns the current theme data.
  ThemeData _getThemeData() {
    var colorScheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.lightCodeColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
    );
  }

  /// Returns the lightCode colors for the current theme.
  AppColors themeColor() => _getThemeColors();

  /// Returns the current theme data.
  ThemeData themeData() => _getThemeData();
}

class ColorSchemes {
  static final lightCodeColorScheme = ColorScheme.light();
}

class AppColors {
  // ────────────────────── app colors ──────────────────────
  Color get basis => const Color(0xFFFF6464);       // 기초 컬러
  Color get mainUI => const Color(0xFFFF4040);     // 버튼·강조 UI
  Color get lightbasis => const Color(0xFFFFCECE);       // 연한 포인트
  Color get background => const Color(0xFFFFFDFD);   // 카드·다이얼로그 배경
  Color get cloudy => const Color(0xFFE4AEAE);   // 비활성·보조 텍스트
  Color get text => const Color(0xFF000000);       // 텍스트 기본
  Color get verylight => const Color(0xFFFFF4F4);     // 아주 연한 배경
  Color get disabled => const Color(0xFF8391A1);       // 비활성 아이콘·보조
  Color get middle => const Color(0xFFFF7777);       // 중간 강조
  Color get maximumlight => const Color(0xFFFFFBFB); // 최대 연한 배경

  // ────────────────────── status colors ──────────────────────
  Color get approved => const Color(0xFF4CAF50); // 승인됨
  Color get pending  => const Color(0xFFFF9800); // 검토중
  Color get rejected => const Color(0xFFE53935); // 반려됨
}
