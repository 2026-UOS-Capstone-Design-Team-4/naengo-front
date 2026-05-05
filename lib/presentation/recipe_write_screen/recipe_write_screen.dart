import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../models/recipe_submit_request.dart';
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

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _contentController.dispose();
    super.dispose();
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
      final request = RecipeSubmitRequest(
        title: title,
        content: content,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        ingredientsRaw: _ingredientsController.text.trim().isEmpty
            ? null
            : _ingredientsController.text.trim(),
      );

      await _recipeService.submitRecipe(request);

      if (!mounted) return;
      _showSnackBar('레시피가 등록되었어요!');
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('[RecipeWrite] 등록 실패: $e');
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
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(color: appTheme.maximumlight),
        child: SafeArea(
          child: Column(
            children: [
              NaengoAppBar(
                showBackArrow: true,
                title: '작성하기',
              ),
              Expanded(
                child: ListView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.h, vertical: 20.h),
                  children: [
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
        ),
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
