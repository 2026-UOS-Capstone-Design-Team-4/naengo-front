import 'package:flutter/material.dart';

import '../core/app_export.dart';

/// CustomChatMessage - A reusable chat message bubble component that supports both sender and receiver message styling with customizable appearance
/// @param message - The text content of the message
/// @param isReceived - Boolean to determine if this is a received message (true) or sent message (false)
/// @param backgroundColor - Custom background color for the message bubble
/// @param textStyle - Custom text style for the message content
/// @param padding - Custom padding for the message content
/// @param borderRadius - Custom border radius for the message bubble
class CustomChatMessage extends StatelessWidget {
  const CustomChatMessage({
    super.key,
    required this.message,
    this.isReceived,
    this.backgroundColor,
    this.textStyle,
    this.padding,
    this.borderRadius,
  });

  /// The text content of the message
  final String message;

  /// Boolean to determine message direction and styling (true for received, false for sent)
  final bool? isReceived;

  /// Background color for the message bubble
  final Color? backgroundColor;

  /// Custom text style for the message content
  final TextStyle? textStyle;

  /// Custom padding for the message content
  final EdgeInsetsGeometry? padding;

  /// Custom border radius for the message bubble
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final bool messageIsReceived = isReceived ?? true;
    final Color bubbleColor =
        backgroundColor ??
        (messageIsReceived ? Color(0xFFFFCDCD) : appTheme.transparentCustom);

    return Column(
      crossAxisAlignment: messageIsReceived
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: bubbleColor != appTheme.transparentCustom
              ? BoxDecoration(
                  color: bubbleColor,
                  borderRadius:
                      borderRadius ??
                      _getDefaultBorderRadius(messageIsReceived),
                )
              : null,
          padding:
              padding ?? EdgeInsets.symmetric(horizontal: 10.h, vertical: 10.h),
          child: Text(message, style: textStyle ?? _getDefaultTextStyle()),
        ),
      ],
    );
  }

  /// Get default border radius based on message direction
  BorderRadiusGeometry _getDefaultBorderRadius(bool isReceived) {
    if (isReceived) {
      return BorderRadius.only(
        topLeft: Radius.circular(18.h),
        topRight: Radius.circular(18.h),
        bottomRight: Radius.circular(18.h),
        bottomLeft: Radius.circular(0),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(18.h),
        topRight: Radius.circular(18.h),
        bottomLeft: Radius.circular(18.h),
        bottomRight: Radius.circular(0),
      );
    }
  }

  /// Get default text style for messages
  TextStyle _getDefaultTextStyle() {
    return TextStyleHelper.instance.body15Regular.copyWith(height: 1.13);
  }
}
