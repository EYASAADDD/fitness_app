class ScanResultModel {
  const ScanResultModel({
    required this.name,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.sugar,
    required this.sodium,
    required this.scanType,
    this.confidence,
    this.barcode,
    this.rawText,
    this.brand,
    this.nutriScore,
  });

  final String name;
  final double calories;
  final double proteins;
  final double carbs;
  final double fats;
  final double sugar;
  final double sodium;
  final String scanType;
  final double? confidence;
  final String? barcode;
  final String? rawText;
  final String? brand;
  final String? nutriScore;

  factory ScanResultModel.fromMap(Map<String, dynamic> map) {
    double readNum(String key) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return ScanResultModel(
      name: (map['name'] as String?) ?? 'Unknown',
      calories: readNum('calories'),
      proteins: readNum('proteins'),
      carbs: readNum('carbs'),
      fats: readNum('fats'),
      sugar: readNum('sugar'),
      sodium: readNum('sodium'),
      scanType: (map['scanType'] as String?) ?? 'unknown',
      confidence: map['confidence'] is num
          ? (map['confidence'] as num).toDouble()
          : null,
      barcode: map['barcode'] as String?,
      rawText: map['rawText'] as String?,
      brand: map['brand'] as String?,
      nutriScore: map['nutriScore'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'sugar': sugar,
      'sodium': sodium,
      'scanType': scanType,
      if (confidence != null) 'confidence': confidence,
      if (barcode != null) 'barcode': barcode,
      if (rawText != null) 'rawText': rawText,
      if (brand != null) 'brand': brand,
      if (nutriScore != null) 'nutriScore': nutriScore,
    };
  }
}
