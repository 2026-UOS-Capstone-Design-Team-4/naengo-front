import 'package:flutter/material.dart';
import '../core/app_export.dart';

/// A helper class for managing text styles in the application
class TextStyleHelper {
  static TextStyleHelper? _instance;

  TextStyleHelper._();

  static TextStyleHelper get instance {
    _instance ??= TextStyleHelper._();
    return _instance!;
  }

  // Headline Styles
  // Medium-large text styles for section headers

  TextStyle get headline30ExtraBoldTmoneyRoundWind => TextStyle(
    fontSize: 30.fSize,
    fontWeight: FontWeight.w800,
    fontFamily: 'Tmoney RoundWind',
    color: appTheme.red_500,
  );

  TextStyle get headline24BoldUrbanist => TextStyle(
    fontSize: 24.fSize,
    fontWeight: FontWeight.w700,
    fontFamily: 'Urbanist',
    color: appTheme.red_500,
  );

  TextStyle get headline24Bold => TextStyle(
    fontSize: 24.fSize,
    fontWeight: FontWeight.w700,
    color: appTheme.red_500,
  );

  // Title Styles
  // Medium text styles for titles and subtitles

  TextStyle get title20RegularRoboto => TextStyle(
    fontSize: 20.fSize,
    fontWeight: FontWeight.w400,
    fontFamily: 'Roboto',
  );

  TextStyle get title20ExtraBoldNanumSquareAc => TextStyle(
    fontSize: 20.fSize,
    fontWeight: FontWeight.w800,
    fontFamily: 'NanumSquare ac',
    color: appTheme.red_500,
  );

  TextStyle get title20ExtraBoldTmoneyRoundWind => TextStyle(
    fontSize: 20.fSize,
    fontWeight: FontWeight.w800,
    fontFamily: 'Tmoney RoundWind',
    color: appTheme.red_500,
  );

  TextStyle get title18BoldNanumSquareAc => TextStyle(
    fontSize: 18.fSize,
    fontWeight: FontWeight.w700,
    fontFamily: 'NanumSquare ac',
    color: appTheme.black_900_01,
  );

  TextStyle get title18MediumInter => TextStyle(
    fontSize: 18.fSize,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
    color: appTheme.black_900_01,
  );

  // Body Styles
  // Standard text styles for body content

  TextStyle get body15BoldNanumSquareAc => TextStyle(
    fontSize: 15.fSize,
    fontWeight: FontWeight.w700,
    fontFamily: 'NanumSquare ac',
    color: appTheme.black_900,
  );

  TextStyle get body15MediumNotoSansKR => TextStyle(
    fontSize: 15.fSize,
    fontWeight: FontWeight.w500,
    fontFamily: 'Noto Sans KR',
    color: appTheme.gray_900,
  );

  TextStyle get body15RegularNanumSquareAc => TextStyle(
    fontSize: 15.fSize,
    fontWeight: FontWeight.w400,
    fontFamily: 'NanumSquare ac',
    color: appTheme.black_900,
  );

  TextStyle get body15RegularTmoneyRoundWind => TextStyle(
    fontSize: 15.fSize,
    fontWeight: FontWeight.w400,
    fontFamily: 'Tmoney RoundWind',
    color: appTheme.red_500,
  );

  TextStyle get body15NanumSquareAc =>
      TextStyle(fontSize: 15.fSize, fontFamily: 'NanumSquare ac');

  TextStyle get body15Regular => TextStyle(
    fontSize: 15.fSize,
    fontWeight: FontWeight.w400,
    color: appTheme.black_900,
  );

  // Label Styles
  // Small text styles for labels, captions, and hints

  TextStyle get label10MediumNotoSansKR => TextStyle(
    fontSize: 10.fSize,
    fontWeight: FontWeight.w500,
    fontFamily: 'Noto Sans KR',
    color: appTheme.red_A200,
  );

  // Other Styles
  // Miscellaneous text styles without specified font size

  TextStyle get textStyle15 => TextStyle();
}
