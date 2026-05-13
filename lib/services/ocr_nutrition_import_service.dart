import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/meal_plan_item.dart';

class NutritionImportResult {
  const NutritionImportResult({
    required this.rawText,
    required this.meals,
    required this.importedAt,
  });

  final String rawText;
  final List<MealPlanItem> meals;
  final DateTime importedAt;

  bool get isEmpty => meals.isEmpty;
}

class OCRNutritionImportService {
  final ImagePicker _picker = ImagePicker();
  late TextRecognizer _recognizer;

  Future<void> initialize() async {
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  Future<XFile?> pickImage({bool fromCamera = true}) async {
    try {
      return await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Nutrition image pick error: $e');
      return null;
    }
  }

  Future<NutritionImportResult> extractMealPlanFromImage(String imagePath) async {
    try {
      final image = InputImage.fromFilePath(imagePath);
      final text = await _recognizer.processImage(image);
      final meals = _parseMealPlan(text.text);
      return NutritionImportResult(
        rawText: text.text,
        meals: meals,
        importedAt: DateTime.now(),
      );
    } catch (e) {
      return NutritionImportResult(
        rawText: 'Error: $e',
        meals: const [],
        importedAt: DateTime.now(),
      );
    }
  }

  List<MealPlanItem> _parseMealPlan(String raw) {
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final result = <MealPlanItem>[];
    String? currentMealName;
    final currentFoods = <MealFoodItem>[];

    void flushMeal() {
      final mealName = currentMealName;
      if (mealName == null || currentFoods.isEmpty) return;
      final calories = currentFoods.fold<int>(0, (sum, item) => sum + item.calories);
      result.add(
        MealPlanItem(
          id: '${DateTime.now().microsecondsSinceEpoch}-${result.length}',
          mealName: mealName,
          foods: List<MealFoodItem>.from(currentFoods),
          estimatedCalories: calories,
          plannedHour: _defaultHourForMeal(mealName),
        ),
      );
      currentFoods.clear();
    }

    for (final line in lines) {
      final lower = line.toLowerCase();
      final isMealHeader = lower.startsWith('breakfast') ||
          lower.startsWith('lunch') ||
          lower.startsWith('dinner') ||
          lower.startsWith('snack') ||
          lower.startsWith('dejeuner') ||
          lower.startsWith('petit') ||
          lower.startsWith('diner');

      if (isMealHeader) {
        flushMeal();
        currentMealName = line.replaceAll(':', '');
        continue;
      }

      final quantityMatch = RegExp(r'(\d+\s?(g|ml|pcs|x))', caseSensitive: false).firstMatch(line);
      final calories = _estimateCalories(line);
      final macro = _estimateMacros(line);

      currentFoods.add(
        MealFoodItem(
          name: _cleanFoodName(line),
          quantity: quantityMatch?.group(1),
          calories: calories,
          protein: macro.$1,
          carbs: macro.$2,
          fat: macro.$3,
        ),
      );
    }

    flushMeal();
    return result;
  }

  String _cleanFoodName(String line) {
    return line
        .replaceAll(RegExp(r'\d+\s?(g|ml|pcs|x)', caseSensitive: false), '')
        .replaceAll(':', '')
        .trim();
  }

  String _defaultHourForMeal(String meal) {
    final lower = meal.toLowerCase();
    if (lower.contains('break') || lower.contains('petit')) return '08:00';
    if (lower.contains('lunch') || lower.contains('dejeuner')) return '13:00';
    if (lower.contains('snack')) return '17:00';
    return '20:00';
  }

  int _estimateCalories(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('egg')) return 75;
    if (lower.contains('banana')) return 95;
    if (lower.contains('milk')) return 120;
    if (lower.contains('rice')) return 260;
    if (lower.contains('chicken')) return 220;
    if (lower.contains('salad')) return 70;
    if (lower.contains('fish') || lower.contains('salmon')) return 260;
    return 120;
  }

  (int, int, int) _estimateMacros(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('chicken') || lower.contains('egg') || lower.contains('fish')) {
      return (22, 2, 8);
    }
    if (lower.contains('rice') || lower.contains('banana') || lower.contains('bread')) {
      return (4, 42, 2);
    }
    if (lower.contains('salad') || lower.contains('vegetable')) {
      return (2, 8, 1);
    }
    return (4, 12, 4);
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
