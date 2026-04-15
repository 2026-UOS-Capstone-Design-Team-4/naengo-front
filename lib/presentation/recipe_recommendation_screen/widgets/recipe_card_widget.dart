import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class RecipeCardWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const RecipeCardWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120.h,
        height: 125.h,
        decoration: BoxDecoration(
          color: appTheme.gray_50,
          border: Border.all(color: appTheme.red_500, width: 2.h),
          borderRadius: BorderRadius.circular(10.h),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
              decoration: BoxDecoration(
                color: appTheme.color7FFFCD,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10.h),
                  bottomRight: Radius.circular(10.h),
                ),
              ),
              child: Text(
                "유저 레시피",
                style: TextStyleHelper.instance.body15RegularTmoneyRoundWind
                    .copyWith(color: appTheme.black_900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
