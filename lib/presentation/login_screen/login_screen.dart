import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _doCredentialsLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await AuthServiceLocator.instance.login(username, password);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.mainShell,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = e.toString().contains('INVALID_CREDENTIALS')
          ? '아이디 또는 비밀번호를 확인해주세요.'
          : e.toString().contains('USER_BLOCKED')
              ? '차단된 계정입니다.'
              : '로그인에 실패했어요. 다시 시도해주세요.';
      NaengoSnackBar.show(context, msg);
    }
  }

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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 24.h : 0,
            ),
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
                    '간편하게 로그인하고\n다양한 서비스를 이용해보세요.',
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

            SizedBox(height: 48.h),

            // 버튼 영역
            Padding(
              padding: EdgeInsets.fromLTRB(24.h, 0, 24.h, 0),
              child: Column(
                children: [
                  // ── 아이디/비밀번호 로그인 ──────────────────
                  // 아이디
                  Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 14.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _usernameController,
                            enabled: !_isLoading,
                            style: TextStyle(
                              fontSize: 14.fSize,
                              fontFamily: 'Noto Sans KR',
                            ),
                            decoration: InputDecoration(
                              hintText: '아이디',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14.fSize,
                                fontFamily: 'Noto Sans KR',
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // 비밀번호
                  Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 14.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !_isLoading,
                            style: TextStyle(
                              fontSize: 14.fSize,
                              fontFamily: 'Noto Sans KR',
                            ),
                            decoration: InputDecoration(
                              hintText: '비밀번호',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14.fSize,
                                fontFamily: 'Noto Sans KR',
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _doCredentialsLogin(),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18.h,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _doCredentialsLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.mainUI,
                        disabledBackgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.h),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              '로그인',
                              style: TextStyle(
                                fontSize: 15.fSize,
                                fontFamily: 'Noto Sans KR',
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 구분선
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.h),
                        child: Text(
                          '또는',
                          style: TextStyle(
                            fontSize: 12.fSize,
                            fontFamily: 'Noto Sans KR',
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // 카카오 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _doKakaoLogin,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE500),
                          borderRadius: BorderRadius.circular(6.h),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/images/kakao_login_medium_wide.svg',
                          height: 52.h,
                        ),
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

            SizedBox(height: 48.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}