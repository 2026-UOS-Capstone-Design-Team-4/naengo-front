import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

/// CustomChatBubble - A reusable chat message bubble component with customizable image icon, 
/// background color, and rounded corners. Designed for chat interfaces with consistent styling.
class CustomChatBubble extends StatelessWidget {
  const CustomChatBubble({
    super.key,
    this.imagePath,
    this.backgroundColor,
    this.width,
    this.height,
    this.imageWidth,
    this.imageHeight,
    this.onTap,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  /// Path to the image/icon to display inside the bubble
  final String? imagePath;

  /// Background color of the chat bubble
  final Color? backgroundColor;

  /// Width of the chat bubble
  final double? width;

  /// Height of the chat bubble
  final double? height;

  /// Width of the image inside the bubble
  final double? imageWidth;

  /// Height of the image inside the bubble
  final double? imageHeight;

  /// Callback function when bubble is tapped
  final VoidCallback? onTap;

  /// Custom border radius for the bubble
  final BorderRadius? borderRadius;

  /// Padding inside the bubble
  final EdgeInsetsGeometry? padding;

  /// Margin around the bubble
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 60.h,
      height: height ?? 40.h,
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                borderRadius ??
                BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(20.h),
                  bottomLeft: Radius.circular(20.h),
                  bottomRight: Radius.circular(20.h),
                ),
          ),
          padding: padding ?? EdgeInsets.all(8.h),
          child: Center(
            child: CustomImageView(
              imagePath: imagePath ?? ImageConstant.imgGroup5,
              width: imageWidth ?? 18.h,
              height: imageHeight ?? 4.h,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
