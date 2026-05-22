import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../widgets/naengo_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _doKakaoLogin() async {
    setState(() => _isLoading = true);
    try {
      await AuthServiceLocator.instance.loginWithKakao();
      if (!mounted) return;
      // 로그인 완료 → 메인 화면으로 이동 (스택 전체 교체)
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.mainShell,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      NaengoSnackBar.show(context, '카카오 로그인에 실패했어요. 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 뒤로 가기
            Padding(
              padding: EdgeInsets.only(left: 4.h, top: 4.h),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios,
                    size: 20.h, color: appTheme.disabled),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // 타이틀 영역
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 28.h).copyWith(top: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '만나서 반가워요!\n저는 냉고예요.',
                    style: TextStyle(
                      fontSize: 26.fSize,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'NanumSquare ac',
                      color: appTheme.mainUI,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '간편하게 로그인하고 다양한 서비스를\n이용해보세요.',
                    style: TextStyle(
                      fontSize: 14.fSize,
                      fontFamily: 'Noto Sans KR',
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 버튼 영역
            Padding(
              padding: EdgeInsets.fromLTRB(24.h, 0, 24.h, 52.h),
              child: Column(
                children: [
                  // 카카오 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _doKakaoLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE500),
                        disabledBackgroundColor:
                            const Color(0xFFFEE500).withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.h),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black45),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 카카오 말풍선 아이콘 (근사)
                                Icon(Icons.chat_bubble_rounded,
                                    size: 22.h,
                                    color: Colors.black87),
                                SizedBox(width: 8.h),
                                Text(
                                  '카카오 로그인',
                                  style: TextStyle(
                                    fontSize: 16.fSize,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Noto Sans KR',
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // 비로그인 이용
                  GestureDetector(
                    onTap: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      '로그인 안하고 이용할래요',
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontFamily: 'Noto Sans KR',
                        color: Colors.grey[500],
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.grey[400],
                      ),
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