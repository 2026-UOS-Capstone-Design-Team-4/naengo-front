import 'package:image_picker/image_picker.dart';

class RecipeSubmitRequest {
  final String title;
  final List<String> steps;
  final String? description;
  final String? ingredientsRaw;
  final String difficulty; // 'easy' | 'normal' | 'hard'
  final int? cookingTime;
  final double? servings;
  final int? calories;
  final List<String> category;
  final XFile? mainImage;

  const RecipeSubmitRequest({
    required this.title,
    required this.steps,
    this.description,
    this.ingredientsRaw,
    required this.difficulty,
    this.cookingTime,
    this.servings,
    this.calories,
    this.category = const [],
    this.mainImage,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description ?? '',
        'difficulty': difficulty,
        'category': category,
        'tags': <String>[],
        'tips': <String>[],
        'warnings': <String>[],
        'ingredients': ingredientsRaw == null || ingredientsRaw!.trim().isEmpty
            ? <Map<String, dynamic>>[]
            : ingredientsRaw!
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .map((line) => <String, dynamic>{'name': line, 'raw_text': line})
                .toList(),
        'steps': steps
            .asMap()
            .entries
            .map((e) => {'step_no': e.key + 1, 'instruction': e.value})
            .toList(),
        if (cookingTime != null) 'cooking_time_minutes': cookingTime,
        if (servings != null) 'servings': servings,
        if (calories != null) 'kcal_per_serving': calories,
      };
}
