import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

/// A custom notification row component that displays an icon and text in a horizontal layout. This component is designed for notification-style content with configurable icon, text, and styling options.
class CustomNotificationRow extends StatelessWidget {
  const CustomNotificationRow({
    super.key,
    this.iconPath,
    this.text,
    this.textStyle,
    this.spacing,
    this.margin,
    this.onTap,
    this.mainAxisAlignment,
  });

  /// Path to the notification icon (SVG, PNG, or network image)
  final String? iconPath;

  /// The notification text content
  final String? text;

  /// Custom text style for the notification message
  final TextStyle? textStyle;

  /// Spacing between the icon and text
  final double? spacing;

  /// External margin for the entire component
  final EdgeInsetsGeometry? margin;

  /// Callback function when the notification row is tapped
  final VoidCallback? onTap;

  /// Alignment of the row contents
  final MainAxisAlignment? mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: 254.h),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomImageView(
              imagePath: iconPath ?? ImageConstant.imgBell,
              height: 24.h,
              width: 24.h,
            ),
            SizedBox(width: spacing ?? 24.h),
            Text(
              text ?? '알림 필요?',
              style: textStyle ?? _defaultTextStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _defaultTextStyle(BuildContext context) {
    return TextStyleHelper.instance.title18MediumInter.copyWith(
      height: 22.h / 18.fSize,
    );
  }
}
