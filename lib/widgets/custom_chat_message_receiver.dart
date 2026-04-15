import 'package:flutter/material.dart';

import '../core/app_export.dart';

/// CustomChatMessageReceiver - A chat bubble component for displaying received messages
/// with customizable styling, padding, margins, and background colors.
/// Supports responsive design and follows chat UI best practices.
class CustomChatMessageReceiver extends StatelessWidget {
  const CustomChatMessageReceiver({
    super.key,
    required this.message,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.margin,
    this.maxWidth,
    this.textAlign,
  });

  /// The message text to display
  final String message;

  /// Background color of the message bubble
  final Color? backgroundColor;

  /// Text color for the message
  final Color? textColor;

  /// Font size for the message text
  final double? fontSize;

  /// Font weight for the message text
  final FontWeight? fontWeight;

  /// Padding inside the message bubble
  final EdgeInsetsGeometry? padding;

  /// Margin around the message bubble
  final EdgeInsetsGeometry? margin;

  /// Maximum width of the message bubble
  final double? maxWidth;

  /// Text alignment within the bubble
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(top: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? MediaQuery.of(context).size.width * 0.72,
              ),
              padding:
                  padding ??
                  EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.h),
              decoration: BoxDecoration(
                color: backgroundColor ?? Color(0xFFFFCDCD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.h),
                  topRight: Radius.circular(0),
                  bottomLeft: Radius.circular(20.h),
                  bottomRight: Radius.circular(20.h),
                ),
              ),
              child: Text(
                message,
                textAlign: textAlign ?? TextAlign.left,
                style: TextStyleHelper.instance.textStyle15.copyWith(
                  color: textColor ?? Color(0xFF000000),
                  height: 1.07,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
