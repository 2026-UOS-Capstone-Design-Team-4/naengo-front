import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

/// 앱 전체 공통 AppBar.
///
/// 규격 기준: '새 채팅' 화면
/// - 높이: 56.h
/// - 좌우 padding: 16.h
/// - 제목: Urbanist Bold 20, red_500
/// - 우측 액션: 흰 원형 버튼 + 붉은 그림자
///
/// 사용 예 (사이드바 있는 메인 화면):
/// ```dart
/// NaengoAppBar(
///   leadingIcon: ImageConstant.imgSidebarButton,
///   onLeadingPressed: _openPanel,
///   title: '새 채팅',
///   actionIcon: ImageConstant.imgPersonOutline,
///   onActionPressed: () => Navigator.of(context).pushNamed(AppRoutes.profileSettingsScreen),
/// )
/// ```
///
/// 사용 예 (푸시된 서브 화면):
/// ```dart
/// NaengoAppBar(
///   showBackArrow: true,
///   title: '개인정보 설정',
/// )
/// ```
class NaengoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NaengoAppBar({
    super.key,
    this.title,
    this.leadingIcon,
    this.actionIcon,
    this.onLeadingPressed,
    this.onActionPressed,
    this.showBackArrow = false,
  });

  final String? title;
  final String? leadingIcon;
  final String? actionIcon;
  final VoidCallback? onLeadingPressed;
  final VoidCallback? onActionPressed;

  /// true 이면 leadingIcon 대신 뒤로가기 화살표를 표시.
  /// onLeadingPressed 미설정 시 Navigator.pop() 자동 호출.
  final bool showBackArrow;

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      color: Colors.transparent,
      child: Row(
        children: [
          _buildLeading(context),
          SizedBox(width: 12.h),
          Expanded(
            child: title != null
                ? Text(
                    title!,
                    style:
                        TextStyleHelper.instance.headline24BoldUrbanist.copyWith(
                      color: appTheme.mainUI,
                      fontSize: 20.fSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
          ),
          if (actionIcon != null) _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (showBackArrow) {
      return GestureDetector(
        onTap: onLeadingPressed ?? () => Navigator.pop(context),
        child: SizedBox(
          width: 28.h,
          height: 24.h,
          child: Icon(
            Icons.arrow_back_ios_new,
            color: appTheme.mainUI,
            size: 20.h,
          ),
        ),
      );
    }
    if (leadingIcon != null) {
      return GestureDetector(
        onTap: onLeadingPressed,
        child: CustomImageView(
          imagePath: leadingIcon!,
          width: 28.h,
          height: 24.h,
          fit: BoxFit.contain,
        ),
      );
    }
    return SizedBox(width: 28.h);
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: onActionPressed,
      child: Container(
        width: 40.h,
        height: 40.h,
        decoration: BoxDecoration(
          color: appTheme.background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: appTheme.basis.withAlpha(38),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CustomImageView(
            imagePath: actionIcon!,
            height: 24.h,
            width: 24.h,
          ),
        ),
      ),
    );
  }
}
