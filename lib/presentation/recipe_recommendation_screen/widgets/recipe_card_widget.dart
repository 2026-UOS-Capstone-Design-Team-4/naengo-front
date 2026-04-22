import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/mock_data_service.dart';
import '../../../models/recipe_item.dart';

class RecipeCardWidget extends StatefulWidget {
  final RecipeItem recipe;
  final VoidCallback? onTap;

  const RecipeCardWidget({super.key, required this.recipe, this.onTap});

  @override
  State<RecipeCardWidget> createState() => _RecipeCardWidgetState();
}

class _RecipeCardWidgetState extends State<RecipeCardWidget> {
  @override
  void initState() {
    super.initState();
    MockDataService.likesNotifier.addListener(_onLikesChanged);
  }

  @override
  void dispose() {
    MockDataService.likesNotifier.removeListener(_onLikesChanged);
    super.dispose();
  }

  void _onLikesChanged() => setState(() {});

  void _toggleLike() {
    widget.recipe.isLiked = !widget.recipe.isLiked;
    widget.recipe.likesCount += widget.recipe.isLiked ? 1 : -1;
    MockDataService.notifyLikesChanged();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return GestureDetector(
      onTap: widget.onTap,
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
                  GestureDetector(
                    onTap: _toggleLike,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Icon(
                          recipe.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 10.h,
                          color: appTheme.red_500,
                        ),
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
