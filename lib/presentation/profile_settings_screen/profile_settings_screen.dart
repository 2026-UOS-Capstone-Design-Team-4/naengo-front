import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _auth = AuthServiceLocator.instance;

  // 프로필 편집
  late final TextEditingController _nicknameController;

  // 취향 편집
  bool _isEditingPreference = false;
  late final TextEditingController _userInputController;
  bool _isSavingPreference = false;

  @override
  void initState() {
    super.initState();
    _nicknameController =
        TextEditingController(text: _auth.currentUser.nickname);
    _userInputController =
        TextEditingController(text: _auth.currentProfile.userInput.join('\n'));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _userInputController.dispose();
    super.dispose();
  }

  // ── 프로필 편집 ─────────────────────────────────────────

  void _startEditingProfile() {
    _nicknameController.text = _auth.currentUser.nickname;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => _ProfileEditDialog(
        nicknameController: _nicknameController,
        profileImageUrl: _auth.currentUser.profileImageUrl,
        onSave: _saveProfile,
      ),
    );
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;
    await _auth.updateNickname(nickname);
    if (mounted) setState(() {});
  }

  // ── 취향 편집 ───────────────────────────────────────────

  void _startEditingPreference() {
    setState(() => _isEditingPreference = true);
  }

  void _cancelEditingPreference() {
    _userInputController.text =
        _auth.currentProfile.userInput.join('\n');
    setState(() => _isEditingPreference = false);
  }

  Future<void> _savePreference() async {
    setState(() => _isSavingPreference = true);
    final lines = _userInputController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await _auth.updateUserInput(lines);
    if (!mounted) return;
    setState(() {
      _isEditingPreference = false;
      _isSavingPreference = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('취향이 저장되었어요.')),
    );
  }

  // ── 로그아웃 / 탈퇴 ─────────────────────────────────────

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 카카오 인증 붙으면 로그아웃 로직 연결
            },
            child: Text('로그아웃',
                style: TextStyle(color: appTheme.mainUI)),
          ),
        ],
      ),
    );
  }

  void _onDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('탈퇴 기능은 준비 중이에요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ── 빌드 ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: appTheme.maximumlight,
      appBar: NaengoAppBar(
        showBackArrow: true,
        title: '개인정보 설정',
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
        children: [
          _buildProfileCard(user.nickname, user.profileImageUrl),
          SizedBox(height: 20.h),
          _buildPreferenceSection(),
          SizedBox(height: 20.h),
          _buildActionSection(),
        ],
      ),
    );
  }

  // ── 프로필 카드 ──────────────────────────────────────────

  Widget _buildProfileCard(String nickname, String? imageUrl) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appTheme.mainUI, appTheme.basis],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.h),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.h,
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? Icon(Icons.person, color: Colors.white, size: 28.h)
                : null,
          ),
          SizedBox(width: 16.h),
          Expanded(
            child: Text(
              nickname,
              style: TextStyleHelper.instance.title18BoldNanumSquareAc
                  .copyWith(color: Colors.white),
            ),
          ),
          // 연필 아이콘만 탭 가능
          GestureDetector(
            onTap: _startEditingProfile,
            child: Padding(
              padding: EdgeInsets.all(4.h),
              child: Icon(
                Icons.edit,
                color: Colors.white.withOpacity(0.85),
                size: 20.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 취향 섹션 ────────────────────────────────────────────

  Widget _buildPreferenceSection() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '나의 취향은?',
                style: TextStyleHelper.instance.body15BoldNanumSquareAc,
              ),
              SizedBox(width: 4.h),
              GestureDetector(
                onTap: _isEditingPreference
                    ? null
                    : _startEditingPreference,
                child: Padding(
                  padding: EdgeInsets.all(4.h),
                  child: Icon(Icons.edit,
                      size: 16.h,
                      color: _isEditingPreference
                          ? appTheme.disabled
                          : appTheme.mainUI),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _userInputController,
            maxLines: 5,
            minLines: 3,
            readOnly: !_isEditingPreference,
            style: TextStyleHelper.instance.body15RegularNanumSquareAc,
            decoration: InputDecoration(
              hintText: '냉고가 참고해요!\n예: 새우 알레르기 있어요, 매운 음식 좋아해요',
              hintStyle: TextStyleHelper.instance.body15RegularNanumSquareAc
                  .copyWith(color: appTheme.disabled),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.h),
                borderSide: BorderSide(
                  color: _isEditingPreference
                      ? appTheme.lightbasis
                      : appTheme.maximumlight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.h),
                borderSide:
                    BorderSide(color: appTheme.mainUI, width: 1.5),
              ),
              filled: !_isEditingPreference,
              fillColor: appTheme.maximumlight,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
            ),
          ),
          if (_isEditingPreference) ...[
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSavingPreference ? null : _cancelEditingPreference,
                  child: Text('취소',
                      style: TextStyle(color: appTheme.disabled)),
                ),
                SizedBox(width: 8.h),
                FilledButton(
                  onPressed: _isSavingPreference ? null : _savePreference,
                  style: FilledButton.styleFrom(
                    backgroundColor: appTheme.mainUI,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.h),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.h, vertical: 8.h),
                  ),
                  child: _isSavingPreference
                      ? SizedBox(
                          width: 16.h,
                          height: 16.h,
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('저장',
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── 로그아웃 / 탈퇴 ─────────────────────────────────────

  Widget _buildActionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '로그아웃',
              style: TextStyleHelper.instance.body15MediumNotoSansKR,
            ),
            trailing:
                Icon(Icons.chevron_right, color: appTheme.disabled),
            onTap: _onLogout,
          ),
          Divider(height: 1, color: appTheme.maximumlight),
          ListTile(
            title: Text(
              '탈퇴하기',
              style: TextStyleHelper.instance.body15MediumNotoSansKR
                  .copyWith(color: appTheme.mainUI),
            ),
            trailing:
                Icon(Icons.chevron_right, color: appTheme.mainUI),
            onTap: _onDeleteAccount,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 프로필 수정 다이얼로그
// ─────────────────────────────────────────────────────────

class _ProfileEditDialog extends StatefulWidget {
  final TextEditingController nicknameController;
  final String? profileImageUrl;
  final Future<void> Function() onSave;

  const _ProfileEditDialog({
    required this.nicknameController,
    required this.profileImageUrl,
    required this.onSave,
  });

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  bool _isSaving = false;

  Future<void> _onSave() async {
    if (widget.nicknameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    await widget.onSave();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: appTheme.background,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.h)),
      child: Padding(
        padding: EdgeInsets.all(20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              '프로필 수정',
              style: TextStyleHelper.instance.title18BoldNanumSquareAc,
            ),
            SizedBox(height: 24.h),

            // 아바타 — 중앙
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 52.h,
                    backgroundColor: appTheme.verylight,
                    backgroundImage: widget.profileImageUrl != null
                        ? NetworkImage(widget.profileImageUrl!)
                        : null,
                    child: widget.profileImageUrl == null
                        ? Icon(Icons.person,
                            color: appTheme.mainUI, size: 56.h)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('프로필 사진 업로드는 준비 중이에요.')),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(6.h),
                        decoration: BoxDecoration(
                          color: appTheme.verylight,
                          shape: BoxShape.circle,
                          border: Border.all(color: appTheme.lightbasis),
                        ),
                        child: Icon(Icons.image_outlined,
                            color: appTheme.mainUI, size: 18.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // 이름 필드 — 밑줄만
            TextField(
              controller: widget.nicknameController,
              style: TextStyleHelper.instance.body15RegularNanumSquareAc,
              decoration: InputDecoration(
                hintText: '이름',
                hintStyle: TextStyleHelper.instance.body15RegularNanumSquareAc
                    .copyWith(color: appTheme.lightbasis),
                border: InputBorder.none,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: appTheme.lightbasis),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: appTheme.mainUI, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              ),
            ),
            SizedBox(height: 24.h),

            // 버튼 — 우측 정렬
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 80.h,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: appTheme.disabled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.h),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text('취소',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 10.h),
                SizedBox(
                  width: 80.h,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: appTheme.mainUI,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.h),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 16.h,
                            height: 16.h,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('수정',
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
