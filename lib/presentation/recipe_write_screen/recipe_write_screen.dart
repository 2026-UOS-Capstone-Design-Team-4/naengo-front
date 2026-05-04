import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../models/recipe_submit_request.dart';
import '../../services/camera_service.dart';
import '../../services/recipe_service.dart';
import '../../widgets/custom_app_bar.dart';

class RecipeWriteScreen extends StatefulWidget {
  const RecipeWriteScreen({super.key});

  @override
  State<RecipeWriteScreen> createState() => _RecipeWriteScreenState();
}

class _RecipeWriteScreenState extends State<RecipeWriteScreen> {
  final _recipeService = RecipeServiceLocator.instance;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _contentController = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── 이미지 선택 ────────────────────────────────────────

  Future<void> _setImage(XFile file) async {
    final bytes = await file.readAsBytes(); // 웹/모바일 모두 동작
    setState(() {
      _selectedImage = file;
      _selectedImageBytes = bytes;
    });
  }

  void _onAddPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.h)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 40.h,
              height: 4.h,
              decoration: BoxDecoration(
                color: appTheme.lightbasis,
                borderRadius: BorderRadius.circular(2.h),
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: appTheme.mainUI),
              title: Text('카메라로 촬영',
                  style: TextStyleHelper.instance.body15MediumNotoSansKR),
              onTap: () async {
                Navigator.pop(context);
                final file = await CameraService.takePhoto();
                if (file != null) _setImage(file);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: appTheme.mainUI),
              title: Text('갤러리에서 선택',
                  style: TextStyleHelper.instance.body15MediumNotoSansKR),
              onTap: () async {
                Navigator.pop(context);
                final file = await CameraService.pickFromGallery();
                if (file != null) _setImage(file);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: appTheme.mainUI),
                title: Text('사진 삭제',
                    style: TextStyleHelper.instance.body15MediumNotoSansKR
                        .copyWith(color: appTheme.mainUI)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _selectedImageBytes = null;
                  });
                },
              ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  // ── 제출 ───────────────────────────────────────────────

  Future<void> _onSubmit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('레시피 이름을 입력해주세요.');
      return;
    }
    if (content.isEmpty) {
      _showSnackBar('조리법을 입력해주세요.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Mock: bytes → base64 data URL로 변환해 imageUrl에 저장.
      // API 연결 후: POST /api/v1/recipes/image 호출 결과 URL로 이 줄만 교체.
      String? imageUrl;
      if (_selectedImageBytes != null) {
        final b64 = base64Encode(_selectedImageBytes!);
        imageUrl = 'data:image/jpeg;base64,$b64';
      }

      final request = RecipeSubmitRequest(
        title: title,
        content: content,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        ingredientsRaw: _ingredientsController.text.trim().isEmpty
            ? null
            : _ingredientsController.text.trim(),
        imageUrl: imageUrl,
      );

      await _recipeService.submitRecipe(request);

      if (!mounted) return;
      _showSnackBar('레시피가 등록되었어요!');
      Navigator.pop(context, true); // true = 새 레시피 추가됨
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('등록에 실패했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── 빌드 ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.maximumlight,
      appBar: NaengoAppBar(
        showBackArrow: true,
        title: '작성하기',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.h, vertical: 20.h),
              children: [
                _buildImagePicker(),
                SizedBox(height: 24.h),
                _buildTitleField(),
                SizedBox(height: 20.h),
                _buildSection(
                  label: '간단한 소개',
                  controller: _descriptionController,
                  hint: '간단한 설명',
                  minLines: 3,
                  maxLines: 5,
                ),
                SizedBox(height: 20.h),
                _buildSection(
                  label: '필요한 재료',
                  controller: _ingredientsController,
                  hint: '재료 작성',
                  minLines: 3,
                  maxLines: 8,
                ),
                SizedBox(height: 20.h),
                _buildSection(
                  label: '조리법',
                  controller: _contentController,
                  hint: '조리방법 작성',
                  minLines: 4,
                  maxLines: 12,
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ── 이미지 피커 영역 ───────────────────────────────────

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _onAddPhoto,
      child: _selectedImageBytes != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12.h),
              child: Image.memory(
                _selectedImageBytes!,
                height: 180.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          : Column(
              children: [
                Container(
                  width: 52.h,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: appTheme.verylight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: appTheme.mainUI, size: 32.h),
                ),
                SizedBox(height: 8.h),
                Text(
                  '사진 추가하기',
                  style: TextStyleHelper.instance.body15RegularNanumSquareAc
                      .copyWith(color: appTheme.mainUI),
                ),
              ],
            ),
    );
  }

  // ── 레시피 이름 입력 ───────────────────────────────────

  Widget _buildTitleField() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.h),
      decoration: BoxDecoration(
        color: appTheme.verylight,
        borderRadius: BorderRadius.circular(14.h),
      ),
      child: TextField(
        controller: _titleController,
        style: TextStyleHelper.instance.title18BoldNanumSquareAc
            .copyWith(color: appTheme.mainUI),
        decoration: InputDecoration(
          hintText: '이름을 입력하세요',
          hintStyle: TextStyleHelper.instance.title18BoldNanumSquareAc
              .copyWith(color: appTheme.mainUI.withValues(alpha: 0.45)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ── 공통 섹션 (라벨 + 텍스트필드) ────────────────────────

  Widget _buildSection({
    required String label,
    required TextEditingController controller,
    required String hint,
    required int minLines,
    required int maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyleHelper.instance.body15BoldNanumSquareAc
              .copyWith(color: appTheme.mainUI),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: appTheme.verylight,
            borderRadius: BorderRadius.circular(12.h),
          ),
          child: TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            style: TextStyleHelper.instance.body15RegularNanumSquareAc,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyleHelper.instance.body15RegularNanumSquareAc
                      .copyWith(color: appTheme.lightbasis),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.h, vertical: 12.h),
            ),
          ),
        ),
      ],
    );
  }

  // ── 하단 버튼 ──────────────────────────────────────────

  Widget _buildBottomButtons() {
    return Container(
      color: appTheme.background,
      padding: EdgeInsets.fromLTRB(16.h, 12.h, 16.h,
          12.h + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: appTheme.disabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.h),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: Text(
                '취소',
                style: TextStyleHelper.instance.body15BoldNanumSquareAc
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: FilledButton(
              onPressed: _isSubmitting ? null : _onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: appTheme.mainUI,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.h),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 18.h,
                      height: 18.h,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      '작성 완료',
                      style:
                          TextStyleHelper.instance.body15BoldNanumSquareAc
                              .copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
