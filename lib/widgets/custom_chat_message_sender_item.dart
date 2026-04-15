import 'package:flutter/material.dart';

import '../core/app_export.dart';

/// A customizable chat message component for displaying sender messages with optional styling.
/// Supports different background colors, border radius, padding, and responsive sizing.
/// Perfect for chat interfaces where messages need different visual treatments.
class CustomChatMessageSenderItem extends StatelessWidget {
  const CustomChatMessageSenderItem({
    super.key,
    required this.message,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.textStyle,
    this.width,
    this.maxWidth,
  });

  /// The message text content to display
  final String message;

  /// Background color of the message bubble
  final Color? backgroundColor;

  /// Border radius for the message bubble corners
  final BorderRadius? borderRadius;

  /// Internal padding of the message container
  final EdgeInsetsGeometry? padding;

  /// External margin of the message container
  final EdgeInsetsGeometry? margin;

  /// Text style for the message content
  final TextStyle? textStyle;

  /// Fixed width constraint for the message container
  final double? width;

  /// Maximum width constraint for the message container (as percentage of screen width)
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: SizeUtils.width * (maxWidth! / 100))
          : null,
      margin: margin,
      padding: padding ?? EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.h),
      decoration: _buildDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(message, style: _buildTextStyle())],
      ),
    );
  }

  /// Builds the container decoration with background and border radius
  BoxDecoration? _buildDecoration() {
    final hasBackground = backgroundColor != null;
    final hasBorderRadius = borderRadius != null;

    if (!hasBackground && !hasBorderRadius) return null;

    return BoxDecoration(color: backgroundColor, borderRadius: borderRadius);
  }

  /// Builds the text style with default values
  TextStyle _buildTextStyle() {
    return textStyle ??
        TextStyleHelper.instance.body15RegularNanumSquareAc.copyWith(
          height: 1.07,
        );
  }
}
