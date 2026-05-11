import 'package:flutter/material.dart';

import '../core/app_export.dart';

class NaengoSnackBar {
  NaengoSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: appTheme.maximumlight,
              fontSize: 13.fSize,
              fontFamily: 'NanumSquare ac',
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: appTheme.basis,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.h),
            side: BorderSide(color: appTheme.mainUI, width: 1),   
          ),
          margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
          duration: duration,
        ),
      );
  }
}
