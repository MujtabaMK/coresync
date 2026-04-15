import 'dart:convert';

import 'package:http/http.dart' as http;

import 'common_foods_data.dart';

/// Searches the USDA FoodData Central API for nutrition data.
/// Free API – no key required (DEMO_KEY has 30 req/hr limit).
class UsdaFoodService {
  UsdaFoodService._();
  static final instance = UsdaFoodService._();

  static const _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const _apiKey = 'DEMO_KEY';

  /// Search USDA for foods matching [query]. Returns up to [limit] results.
  Future<List<CommonFoodItem>> search(String query, {int limit = 5}) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_baseUrl/foods/search'
        '?api_key=$_apiKey'
        '&query=${Uri.encodeComponent(query)}'
        '&pageSize=$limit',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final foods = data['foods'] as List? ?? [];

      return foods.map((item) {
        final m = item as Map<String, dynamic>;
        return _parseFood(m);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  CommonFoodItem _parseFood(Map<String, dynamic> m) {
    final nutrients = <int, double>{};
    for (final n in (m['foodNutrients'] as List? ?? [])) {
      final nm = n as Map<String, dynamic>;
      final id = nm['nutrientId'] as int?;
      final val = (nm['value'] as num?)?.toDouble() ?? 0;
      if (id != null) nutrients[id] = val;
    }

    final servingSize = m['servingSize'] as num?;
    final servingUnit = m['servingSizeUnit'] as String? ?? 'g';
    final servingText = m['householdServingFullText'] as String? ?? '';
    final String servingDisplay;
    if (servingText.isNotEmpty && servingSize != null) {
      servingDisplay = '$servingText (${servingSize.round()}${servingUnit.toLowerCase()})';
    } else if (servingSize != null) {
      servingDisplay = '${servingSize.round()}${servingUnit.toLowerCase()}';
    } else {
      servingDisplay = '100g';
    }

    final name = _capitalize(m['description'] as String? ?? 'Unknown');

    return CommonFoodItem(
      name: name,
      servingSize: servingDisplay,
      calories: nutrients[1008] ?? 0, // Energy (kcal)
      protein: nutrients[1003] ?? 0, // Protein
      carbs: nutrients[1005] ?? 0, // Carbohydrate
      fat: nutrients[1004] ?? 0, // Total lipid (fat)
      fiber: nutrients[1079] ?? 0, // Fiber
      sugar: nutrients[2000] ?? 0, // Total Sugars
      sodium: nutrients[1093] ?? 0, // Sodium
      cholesterol: nutrients[1253] ?? 0, // Cholesterol
      iron: nutrients[1089] ?? 0, // Iron
      calcium: nutrients[1087] ?? 0, // Calcium
      potassium: nutrients[1092] ?? 0, // Potassium
      vitaminA: nutrients[1106] ?? 0, // Vitamin A (RAE)
      vitaminB12: nutrients[1178] ?? 0, // Vitamin B-12
      vitaminC: nutrients[1162] ?? 0, // Vitamin C
      vitaminD: nutrients[1114] ?? 0, // Vitamin D (D2 + D3)
      zinc: nutrients[1095] ?? 0, // Zinc
      magnesium: nutrients[1090] ?? 0, // Magnesium
      vitaminE: nutrients[1109] ?? 0, // Vitamin E (alpha-tocopherol)
      vitaminK: nutrients[1185] ?? 0, // Vitamin K (phylloquinone)
      vitaminB6: nutrients[1175] ?? 0, // Vitamin B-6
      folate: nutrients[1190] ?? 0, // Folate, DFE
      phosphorus: nutrients[1091] ?? 0, // Phosphorus
      selenium: nutrients[1103] ?? 0, // Selenium
      manganese: nutrients[1101] ?? 0, // Manganese
      category: m['foodCategory'] as String? ?? '',
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    // USDA names are ALL CAPS, convert to Title Case
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}
