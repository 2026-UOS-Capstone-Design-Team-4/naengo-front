import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

/// A customizable icon button widget with configurable styling options.
/// 
/// This widget provides a flexible icon button implementation with support for:
/// - Custom background colors and shapes
/// - Configurable padding, margin, and border radius  
/// - SVG and image icon support via CustomImageView
/// - Responsive sizing using SizeUtils
/// - Material design touch feedback
/// 
/// @param iconPath - Path to the icon image (SVG, PNG, etc.)
/// @param onTap - Callback function triggered when button is tapped
/// @param width - Width of the button
/// @param height - Height of the button
/// @param backgroundColor - Background color of the button
/// @param borderRadius - Border radius for rounded corners
/// @param padding - Internal padding around the icon
/// @param margin - External margin around the button
/// @param iconSize - Size of the icon within the button
class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    super.key,
    this.iconPath,
    this.onTap,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.iconSize,
  });

  /// Path to the icon image (SVG, PNG, network URL, etc.)
  final String? iconPath;

  /// Callback function triggered when the button is tapped
  final VoidCallback? onTap;

  /// Width of the button
  final double? width;

  /// Height of the button
  final double? height;

  /// Background color of the button
  final Color? backgroundColor;

  /// Border radius for rounded corners
  final double? borderRadius;

  /// Internal padding around the icon
  final EdgeInsetsGeometry? padding;

  /// External margin around the button
  final EdgeInsetsGeometry? margin;

  /// Size of the icon within the button
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 34.h,
      height: height ?? 34.h,
      margin: margin ?? EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFFFF6464),
        borderRadius: BorderRadius.circular(borderRadius ?? 16.h),
      ),
      child: Material(
        color: appTheme.transparentCustom,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 16.h),
          child: Container(
            padding: padding ?? EdgeInsets.all(4.h),
            child: Center(
              child: CustomImageView(
                imagePath: iconPath ?? ImageConstant.imgCameraoutline,
                height: iconSize ?? 26.h,
                width: iconSize ?? 26.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
