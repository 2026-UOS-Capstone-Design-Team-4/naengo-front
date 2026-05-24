import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../models/recipe_submit_request.dart';
import '../../services/recipe_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/naengo_snackbar.dart';

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
  final _categoryController = TextEditingController();
  final _cookingTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _caloriesController = TextEditingController();

  String? _selectedDifficulty;
  bool _isDifficultyDropdownOpen = false;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _cookingTimeController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  // ── 제출 ───────────────────────────────────────────────

  Future<void> _onSubmit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final description = _descriptionController.text.trim();
    final ingredients = _ingredientsController.text.trim();
    final category = _categoryController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (title.isEmpty) {
      NaengoSnackBar.show(context,'레시피 이름을 입력해주세요.');
      return;
    }
    if (_selectedDifficulty == null) {
      NaengoSnackBar.show(context,'난이도를 선택해주세요.');
      return;
    }
    if (description.isEmpty) {
      NaengoSnackBar.show(context, '간단한 소개를 입력해주세요.');
      return;
    }
    if (ingredients.isEmpty) {
      NaengoSnackBar.show(context, '필요한 재료를 입력해주세요.');
      return;
    }
    if (content.isEmpty) {
      NaengoSnackBar.show(context,'조리법을 입력해주세요.');
      return;
    }
    if (category.isEmpty) {
      NaengoSnackBar.show(context, '카테고리를 입력해주세요.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cookingTimeRaw = _cookingTimeController.text.trim();
      final servingsRaw = _servingsController.text.trim();
      final caloriesRaw = _caloriesController.text.trim();
      final cookingTime = int.tryParse(cookingTimeRaw);
      final servings = double.tryParse(servingsRaw);

      if (cookingTime == null || cookingTime <= 0) {
        NaengoSnackBar.show(context, '조리시간을 숫자로 입력해주세요.');
        return;
      }
      if (servings == null || servings <= 0) {
        NaengoSnackBar.show(context, '인분을 숫자로 입력해주세요.');
        return;
      }

      final request = RecipeSubmitRequest(
        title: title,
        steps: content
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        difficulty: _selectedDifficulty!,
        description: description,
        ingredientsRaw: ingredients,
        cookingTime: cookingTime,
        servings: servings,
        calories: caloriesRaw.isEmpty ? null : int.tryParse(caloriesRaw),
        category: category,
      );

      await _recipeService.submitRecipe(request);

      if (!mounted) return;
      NaengoSnackBar.show(context,'레시피가 검토 요청되었어요!');
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('[RecipeWrite] 등록 실패: $e');
      if (!mounted) return;
      NaengoSnackBar.show(context,'등록에 실패했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── 빌드 ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isDifficultyDropdownOpen) {
          setState(() => _isDifficultyDropdownOpen = false);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
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
                    _buildMetaSection(),
                    SizedBox(height: 20.h),
                    _buildSection(
                      label: '카테고리',
                      controller: _categoryController,
                      hint: '예: 한식, 찌개',
                      minLines: 1,
                      maxLines: 2,
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

  // ── 레시피 정보 ─────────────────

  static const _difficultyOptions = [
    ('easy', '쉬움'),
    ('normal', '보통'),
    ('hard', '어려움'),
  ];

  Widget _buildMetaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '레시피 정보',
          style: TextStyleHelper.instance.body15BoldNanumSquareAc
              .copyWith(color: appTheme.mainUI),
        ),
        SizedBox(height: 8.h),
        _buildDifficultyButton(),
        if (_isDifficultyDropdownOpen) ...[
          SizedBox(height: 4.h),
          _buildDifficultyDropdown(),
        ],
        SizedBox(height: 10.h),
        Row(
          children: [
            _buildNumberField(
              controller: _cookingTimeController,
              hint: '조리시간',
              unit: '분',
            ),
            SizedBox(width: 8.h),
            _buildNumberField(
              controller: _servingsController,
              hint: '양',
              unit: '인분',
            ),
            SizedBox(width: 8.h),
            _buildNumberField(
              controller: _caloriesController,
              hint: '열량',
              unit: 'kcal',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyButton() {
    final selected = _difficultyOptions
        .where((o) => o.$1 == _selectedDifficulty)
        .map((o) => o.$2)
        .firstOrNull;
    final hasSelection = selected != null;
    final color = hasSelection ? appTheme.basis : appTheme.lightbasis;

    return GestureDetector(
      onTap: () =>
          setState(() => _isDifficultyDropdownOpen = !_isDifficultyDropdownOpen),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(20.h),
          color: appTheme.verylight,
        ),
        child: Row(
          children: [
            Icon(Icons.swap_vert, color: color, size: 14),
            SizedBox(width: 4.h),
            Expanded(
              child: Text(
                selected ?? '난이도 선택 (필수)',
                style: TextStyle(
                  color: color,
                  fontSize: 13.fSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              _isDifficultyDropdownOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: color,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyDropdown() {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12.h),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(6.h),
        decoration: BoxDecoration(
          color: appTheme.background,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(color: appTheme.basis, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _difficultyOptions.map((opt) {
            final isSelected = _selectedDifficulty == opt.$1;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedDifficulty = opt.$1;
                _isDifficultyDropdownOpen = false;
              }),
              child: Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(vertical: 9.h, horizontal: 12.h),
                decoration: BoxDecoration(
                  color: isSelected ? appTheme.verylight : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.h),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opt.$2,
                        style: TextStyle(
                          color: isSelected ? appTheme.basis : appTheme.disabled,
                          fontSize: 13.fSize,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_rounded, color: appTheme.basis, size: 15),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
    required String unit,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.verylight,
          borderRadius: BorderRadius.circular(12.h),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hint,
              style: TextStyle(
                fontSize: 10.fSize,
                color: appTheme.disabled,
                fontFamily: 'NanumSquare ac',
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: TextStyleHelper.instance.body15RegularNanumSquareAc
                        .copyWith(color: appTheme.text, height: 1),
                    decoration: InputDecoration(
                      hintText: '-',
                      hintStyle: TextStyleHelper
                          .instance.body15RegularNanumSquareAc
                          .copyWith(color: appTheme.lightbasis, height: 1),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11.fSize,
                    color: appTheme.disabled,
                    fontFamily: 'NanumSquare ac',
                  ),
                ),
              ],
            ),
          ],
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
