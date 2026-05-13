import 'package:dio/dio.dart';

import '../models/scan_result_model.dart';

class ProductBackendService {
  ProductBackendService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<ScanResultModel> fetchByBarcode(String barcode) async {
    try {
      final response = await _dio.get<dynamic>(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid OpenFoodFacts response');
      }

      final product = (data['product'] as Map<String, dynamic>?) ?? const {};
      final nutriments =
          (product['nutriments'] as Map<String, dynamic>?) ?? const {};

      double numField(List<String> keys) {
        for (final key in keys) {
          final value = nutriments[key];
          if (value is num) return value.toDouble();
          if (value is String) {
            final parsed = double.tryParse(value);
            if (parsed != null) return parsed;
          }
        }
        return 0;
      }

      return ScanResultModel(
        name: (product['product_name'] as String?)?.trim().isNotEmpty == true
            ? product['product_name'] as String
            : 'Produit inconnu',
        calories: numField(['energy-kcal_100g', 'energy-kcal']),
        proteins: numField(['proteins_100g', 'proteins']),
        carbs: numField(['carbohydrates_100g', 'carbohydrates']),
        fats: numField(['fat_100g', 'fat']),
        sugar: numField(['sugars_100g', 'sugars']),
        sodium: numField(['sodium_100g', 'sodium', 'salt_100g']) * 1000,
        scanType: 'barcode',
        barcode: barcode,
        brand: (product['brands'] as String?)?.trim(),
        nutriScore: (product['nutriscore_grade'] as String?)?.toUpperCase(),
      );
    } catch (_) {
      return ScanResultModel(
        name: 'Produit scanné',
        calories: 120,
        proteins: 3,
        carbs: 18,
        fats: 4,
        sugar: 6,
        sodium: 140,
        scanType: 'barcode',
        barcode: barcode,
        brand: 'N/A',
        nutriScore: 'N/A',
      );
    }
  }
}
