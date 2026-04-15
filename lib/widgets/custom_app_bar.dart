import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

/// CustomAppBar - A reusable AppBar component with customizable leading icon, title, and action button
/// 
/// This component provides a flexible AppBar implementation that supports:
/// - Customizable leading icon with rounded corners
/// - Dynamic title text with custom styling
/// - Circular action button with callback functionality
/// - Responsive design using SizeUtils
/// 
/// @param title - The title text to display in the center
/// @param leadingIcon - Path to the leading icon (SVG/PNG)
/// @param actionIcon - Path to the action icon (SVG/PNG)
/// @param titleStyle - Custom text style for the title
/// @param onActionPressed - Callback function when action button is tapped
/// @param onLeadingPressed - Callback function when leading icon is tapped
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.leadingIcon,
    this.actionIcon,
    this.titleStyle,
    this.onActionPressed,
    this.onLeadingPressed,
  });

  /// The title text to display in the app bar
  final String? title;

  /// Path to the leading icon image
  final String? leadingIcon;

  /// Path to the action icon image
  final String? actionIcon;

  /// Custom text style for the title
  final TextStyle? titleStyle;

  /// Callback function when action button is pressed
  final VoidCallback? onActionPressed;

  /// Callback function when leading icon is pressed
  final VoidCallback? onLeadingPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appTheme.transparentCustom,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 56.h,
      titleSpacing: 0,
      leading: leadingIcon != null
          ? GestureDetector(
              onTap: onLeadingPressed,
              child: Container(
                margin: EdgeInsets.only(left: 14.h),
                child: CustomImageView(
                  imagePath: leadingIcon!,
                  height: 34.h,
                  width: 40.h,
                  fit: BoxFit.contain,
                ),
              ),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: titleStyle ?? TextStyleHelper.instance.headline24Bold,
            )
          : null,
      actions: actionIcon != null
          ? [
              GestureDetector(
                onTap: onActionPressed,
                child: Container(
                  height: 40.h,
                  width: 40.h,
                  margin: EdgeInsets.only(right: 14.h),
                  decoration: BoxDecoration(
                    color: appTheme.whiteCustom,
                    borderRadius: BorderRadius.circular(18.h),
                  ),
                  child: Center(
                    child: CustomImageView(
                      imagePath: actionIcon!,
                      height: 40.h,
                      width: 40.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}
