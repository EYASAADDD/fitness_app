import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'nutrition_rules_engine.dart';

class ProductAnalyzerService {
  late TextRecognizer _textRecognizer;
  late NutritionRulesEngine _rulesEngine;
  bool _initialized = false;

  Future<void> initialize(NutritionRulesEngine rulesEngine) async {
    if (_initialized) return;

    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _rulesEngine = rulesEngine;
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize product analyzer: $e');
    }
  }

  /// Analyze product image (OCR + nutrient extraction + disease warnings)
  Future<Map<String, dynamic>> analyzeProductImage(
    InputImage inputImage,
    String? userDisease,
  ) async {
    if (!_initialized) {
      return {
        'success': false,
        'error': 'Service not initialized',
      };
    }

    try {
      // Step 1: OCR text extraction
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedText = recognizedText.text;

      if (extractedText.isEmpty) {
        return {
          'success': false,
          'error': 'Aucun texte détecté sur l\'emballage. Essayez de repositionner la caméra.',
          'extracted_text': '',
        };
      }

      // Step 2: Extract nutrients from text
      final nutrients = _extractNutrients(extractedText);

      if (nutrients.isEmpty) {
        return {
          'success': false,
          'error': 'Impossible d\'extraire les nutriments du texte détecté.',
          'extracted_text': extractedText,
        };
      }

      // Step 3: Generate warnings if disease is provided
      var warnings = <Map<String, dynamic>>[];
      var verdict = 'neutral';

      if (userDisease != null && userDisease.isNotEmpty) {
        final comparisonResult = _rulesEngine.compareNutrients(nutrients, userDisease);
        if (comparisonResult['success'] == true) {
          warnings = comparisonResult['violations'] as List<Map<String, dynamic>>;
          verdict = comparisonResult['isSafe'] == true ? 'safe' : 'warning';
        }
      }

      return {
        'success': true,
        'extracted_text': extractedText,
        'nutrients': nutrients,
        'disease': userDisease,
        'verdict': verdict,
        'warnings': warnings,
        'advice': _generateAdvice(nutrients, warnings, userDisease),
        'raw_text': extractedText,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors de l\'analyse: $e',
      };
    }
  }

  /// Extract nutrients from text
  Map<String, double> _extractNutrients(String text) {
    final nutrients = <String, double>{};
    final nutrientList = ['sugar', 'sodium', 'fat', 'calories', 'protein', 'carbs', 'fiber'];

    for (final nutrient in nutrientList) {
      final value = _rulesEngine.extractNutrientValue(text, nutrient);
      if (value != null) {
        nutrients[nutrient] = value;
      }
    }

    return nutrients;
  }

  /// Generate advice based on nutrients and disease
  String _generateAdvice(
    Map<String, double> nutrients,
    List<Map<String, dynamic>> warnings,
    String? disease,
  ) {
    if (warnings.isEmpty && disease != null) {
      return '✅ Ce produit semble adapté à votre condition "$disease".';
    }

    if (warnings.isNotEmpty) {
      final warningList =
          warnings.map((w) => '${w['message']}: ${w['value']}${_getUnit(w['nutrient'])}').join('\n');
      return '⚠️ ATTENTION - Nutriments à surveiller pour votre condition:\n$warningList';
    }

    if (nutrients.isEmpty) {
      return '⚠️ Information nutritionnelle incomplète. Vérifiez l\'étiquette manuellement.';
    }

    return 'ℹ️ Nutriments détectés. Consultez votre médecin pour des recommandations personnalisées.';
  }

  String _getUnit(String nutrient) {
    switch (nutrient) {
      case 'sodium':
        return 'mg';
      case 'calories':
        return 'kcal';
      default:
        return 'g';
    }
  }

  /// Extract product name from text (heuristic)
  String? extractProductName(String text) {
    // Look for common product name indicators
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      // Usually first non-empty line is product name
      return lines.firstWhere(
        (line) => line.trim().isNotEmpty && line.length < 50,
        orElse: () => '',
      );
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
