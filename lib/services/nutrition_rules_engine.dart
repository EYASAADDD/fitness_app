import 'dart:convert';
import 'package:flutter/services.dart';

class NutritionRulesEngine {
  late Map<String, dynamic> _rulesData;
  late Map<String, dynamic> _foodsData;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final rulesJson = await rootBundle.loadString('assets/rules/nutrition_rules.json');
      final foodsJson = await rootBundle.loadString('assets/rules/foods_database.json');

      _rulesData = jsonDecode(rulesJson);
      _foodsData = jsonDecode(foodsJson);
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to load nutrition rules: $e');
    }
  }

  /// Get disease configuration by disease name
  Map<String, dynamic>? getDisease(String diseaseName) {
    final diseases = _rulesData['diseases'] as Map<String, dynamic>;
    return diseases[diseaseName.toLowerCase()];
  }

  /// Get food nutrition data
  Map<String, dynamic>? getFood(String foodName) {
    final foods = _foodsData['foods'] as Map<String, dynamic>;
    return foods[foodName.toLowerCase()];
  }

  /// Analyze if a food is safe for a disease
  Map<String, dynamic> analyzeFoodForDisease(
    String foodName,
    String diseaseName,
  ) {
    final food = getFood(foodName);
    final disease = getDisease(diseaseName);

    if (food == null) {
      return {
        'success': false,
        'message': 'Aliment "$foodName" non trouvé dans la base de données',
        'recommendations': [],
      };
    }

    if (disease == null) {
      return {
        'success': false,
        'message': 'Maladie "$diseaseName" non trouvée dans la base de données',
        'recommendations': [],
      };
    }

    final alerts = disease['alerts'] as List<dynamic>;
    final nutrition = food['nutrition'] as Map<String, dynamic>;
    final recommendations = <Map<String, dynamic>>[];

    for (final alert in alerts) {
      final nutrient = alert['nutrient'] as String;
      final maxValue = alert['max_per_100g'] as num;
      final severity = alert['severity'] as String;
      final message = alert['message'] as String;

      final foodValue = nutrition[nutrient] as num?;
      if (foodValue != null && foodValue > maxValue) {
        recommendations.add({
          'nutrient': nutrient,
          'value': foodValue.toStringAsFixed(1),
          'max': maxValue,
          'severity': severity,
          'message': message,
        });
      }
    }

    final verdict = recommendations.isEmpty ? 'safe' : 'warning';
    final adviceText = recommendations.isEmpty
        ? '✅ ${food['name']} est sûr pour votre ${disease['name']}'
        : '⚠️ Attention: ${food['name']} contient des valeurs élevées pour votre ${disease['name']}';

    return {
      'success': true,
      'food': food['name'],
      'disease': disease['name'],
      'verdict': verdict,
      'advice': adviceText,
      'recommendations': recommendations,
      'nutrition': nutrition,
      'tags': food['tags'] ?? [],
    };
  }

  /// Get recommended foods for a disease
  List<String> getRecommendedFoods(String diseaseName) {
    final disease = getDisease(diseaseName);
    if (disease == null) return [];

    final foods = _foodsData['foods'] as Map<String, dynamic>;
    final recommended = disease['recommended'] as List<dynamic>? ?? [];
    final recommendedFoods = <String>[];

    for (final food in foods.entries) {
      final foodData = food.value as Map<String, dynamic>;
      final tags = foodData['tags'] as List<dynamic>? ?? [];

      for (final tag in tags) {
        if (recommended.contains(tag)) {
          recommendedFoods.add(foodData['name'] as String);
          break;
        }
      }
    }

    return recommendedFoods;
  }

  /// Get all available diseases
  List<String> getAvailableDiseases() {
    final diseases = _rulesData['diseases'] as Map<String, dynamic>;
    return diseases.keys.cast<String>().toList();
  }

  /// Get all available foods
  List<String> getAvailableFoods() {
    final foods = _foodsData['foods'] as Map<String, dynamic>;
    return foods.keys.cast<String>().toList();
  }

  /// Compare multiple nutrients against disease rules
  Map<String, dynamic> compareNutrients(
    Map<String, dynamic> nutrients,
    String diseaseName,
  ) {
    final disease = getDisease(diseaseName);
    if (disease == null) {
      return {'success': false, 'message': 'Maladie non trouvée'};
    }

    final alerts = disease['alerts'] as List<dynamic>;
    final violations = <Map<String, dynamic>>[];

    for (final alert in alerts) {
      final nutrient = alert['nutrient'] as String;
      final maxValue = alert['max_per_100g'] as num;
      final severity = alert['severity'] as String;
      final message = alert['message'] as String;

      if (nutrients.containsKey(nutrient)) {
        final value = nutrients[nutrient] as num;
        if (value > maxValue) {
          violations.add({
            'nutrient': nutrient,
            'value': value,
            'max': maxValue,
            'severity': severity,
            'message': message,
          });
        }
      }
    }

    return {
      'success': true,
      'disease': disease['name'],
      'violations': violations,
      'isSafe': violations.isEmpty,
    };
  }

  /// Extract nutrient value from text (e.g., "Sucre: 10g")
  double? extractNutrientValue(String text, String nutrient) {
    final patterns = {
      'sugar': [r'sucre[:\s]+(\d+(?:[.,]\d+)?)\s*g', r'sugar[:\s]+(\d+(?:[.,]\d+)?)\s*g'],
      'sodium': [r'sodium[:\s]+(\d+(?:[.,]\d+)?)\s*mg', r'sel[:\s]+(\d+(?:[.,]\d+)?)\s*mg'],
      'fat': [r'(?:gra?s|fat)[:\s]+(\d+(?:[.,]\d+)?)\s*g', r'lipides[:\s]+(\d+(?:[.,]\d+)?)\s*g'],
      'calories': [r'(?:calories|energy|kcal)[:\s]+(\d+(?:[.,]\d+)?)', r'énergie[:\s]+(\d+(?:[.,]\d+)?)'],
      'protein': [r'prot[eé]ine?s?[:\s]+(\d+(?:[.,]\d+)?)\s*g', r'protein[:\s]+(\d+(?:[.,]\d+)?)\s*g'],
    };

    final patternsList = patterns[nutrient.toLowerCase()];
    if (patternsList == null) return null;

    for (final pattern in patternsList) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        final valueStr = match.group(1)!.replaceAll(',', '.');
        return double.tryParse(valueStr);
      }
    }

    return null;
  }
}
