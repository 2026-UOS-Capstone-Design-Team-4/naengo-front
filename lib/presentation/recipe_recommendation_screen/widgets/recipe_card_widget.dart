import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../models/recipe_item.dart';

class RecipeCardWidget extends StatelessWidget {
  final RecipeItem recipe;
  final VoidCallback? onTap;

  const RecipeCardWidget({super.key, required this.recipe, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130.h,
        height: 140.h,
        decoration: BoxDecoration(
          color: appTheme.gray_50,
          border: Border.all(color: appTheme.red_500, width: 2.h),
          borderRadius: BorderRadius.circular(10.h),
        ),
        child: Column(
          children: [
            // 이미지 영역
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.h),
                  topRight: Radius.circular(8.h),
                ),
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        width: double.infinity,
                        color: appTheme.red_100,
                        child: Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            size: 32.h,
                            color: appTheme.red_500.withOpacity(0.5),
                          ),
                        ),
                      ),
              ),
            ),
            // 하단 제목 + 좋아요
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 6.h),
              decoration: BoxDecoration(
                color: appTheme.color7FFFCD,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8.h),
                  bottomRight: Radius.circular(8.h),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipe.title,
                    style: TextStyleHelper.instance.body15RegularTmoneyRoundWind
                        .copyWith(
                      color: appTheme.black_900,
                      fontSize: 11.fSize,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.favorite,
                          size: 10.h, color: appTheme.red_500),
                      SizedBox(width: 2.h),
                      Text(
                        '${recipe.likesCount}',
                        style: TextStyle(
                          fontSize: 10.fSize,
                          color: appTheme.red_500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
