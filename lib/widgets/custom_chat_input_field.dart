import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

/// A custom chat input field with camera and send icons
///
/// This component provides a text input field specifically designed for chat interfaces
/// with integrated camera and send button functionality.
///
/// @param controller - TextEditingController for managing input text
/// @param placeholder - Placeholder text displayed when field is empty
/// @param onSendPressed - Callback function triggered when send button is pressed
/// @param onCameraPressed - Callback function triggered when camera button is pressed
/// @param validator - Optional validation function for form validation
/// @param textColor - Color of the input text (defaults to black)
/// @param fontWeight - Font weight of the input text (defaults to normal)
/// @param keyboardType - Type of keyboard to display (defaults to text)
class CustomChatInputField extends StatelessWidget {
  const CustomChatInputField({
    super.key,
    required this.controller,
    this.placeholder,
    this.onSendPressed,
    this.onCameraPressed,
    this.validator,
    this.textColor,
    this.fontWeight,
    this.keyboardType,
  });

  /// Controller for managing the text input
  final TextEditingController controller;

  /// Placeholder text displayed when field is empty
  final String? placeholder;

  /// Callback function triggered when send button is pressed
  final VoidCallback? onSendPressed;

  /// Callback function triggered when camera button is pressed
  final VoidCallback? onCameraPressed;

  /// Optional validation function for form validation
  final String? Function(String?)? validator;

  /// Color of the input text
  final Color? textColor;

  /// Font weight of the input text
  final FontWeight? fontWeight;

  /// Type of keyboard to display
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.h),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType ?? TextInputType.text,
        style: TextStyleHelper.instance.body15NanumSquareAc.copyWith(
          color: textColor ?? Color(0xFF000000),
          height: 1.13,
        ),
        decoration: InputDecoration(
          hintText: placeholder ?? "냉고에게 물어보세요",
          hintStyle: TextStyleHelper.instance.body15RegularNanumSquareAc
              .copyWith(color: Color(0xff7fe4adad)),
          prefixIcon: Padding(
            padding: EdgeInsets.all(8.h),
            child: GestureDetector(
              onTap: onCameraPressed,
              child: CustomImageView(
                imagePath: ImageConstant.imgCameraoutline,
                width: 26.h,
                height: 36.h,
              ),
            ),
          ),
          suffixIcon: Padding(
            padding: EdgeInsets.all(8.h),
            child: GestureDetector(
              onTap: onSendPressed,
              child: CustomImageView(
                imagePath: ImageConstant.imgPaperplane,
                width: 48.h,
                height: 36.h,
              ),
            ),
          ),
          filled: true,
          fillColor: appTheme.white_A700,
          contentPadding: EdgeInsets.only(
            top: 6.h,
            right: 64.h,
            bottom: 6.h,
            left: 42.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26.h),
            borderSide: BorderSide(color: appTheme.red_500, width: 1.h),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26.h),
            borderSide: BorderSide(color: appTheme.red_500, width: 1.h),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26.h),
            borderSide: BorderSide(color: appTheme.red_500, width: 1.h),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26.h),
            borderSide: BorderSide(color: appTheme.redCustom, width: 1.h),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26.h),
            borderSide: BorderSide(color: appTheme.redCustom, width: 1.h),
          ),
        ),
      ),
    );
  }
}
