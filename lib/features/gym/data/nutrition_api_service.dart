import 'dart:convert';
import 'package:http/http.dart' as http;

import 'common_foods_data.dart';

/// Service to search food nutrition data from CalorieNinjas API.
/// Get a free API key at https://calorieninjas.com/
class NutritionApiService {
  NutritionApiService._();
  static final instance = NutritionApiService._();

  static const _apiKey = 'EVYKTRtk7k7GvRxTovrRag==n9vKgJmUpgcs0gny';
  static const _baseUrl = 'https://api.calorieninjas.com/v1/nutrition';

  bool get hasApiKey => _apiKey != 'YOUR_API_KEY_HERE' && _apiKey.isNotEmpty;

  /// Search for food nutrition data. Returns list of [CommonFoodItem].
  /// The query supports natural language like "2 cups rice" or "1 roti with ghee".
  Future<List<CommonFoodItem>> search(String query) async {
    if (!hasApiKey || query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl?query=${Uri.encodeComponent(query)}');
      final response = await http.get(uri, headers: {
        'X-Api-Key': _apiKey,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];

      return items.map((item) {
        final m = item as Map<String, dynamic>;
        final servingG = (m['serving_size_g'] as num?)?.toDouble() ?? 100;
        return CommonFoodItem(
          name: _capitalize(m['name'] as String? ?? 'Unknown'),
          servingSize: '${servingG.round()}g',
          calories: (m['calories'] as num?)?.toDouble() ?? 0,
          protein: (m['protein_g'] as num?)?.toDouble() ?? 0,
          carbs: (m['carbohydrates_total_g'] as num?)?.toDouble() ?? 0,
          fat: (m['fat_total_g'] as num?)?.toDouble() ?? 0,
          fiber: (m['fiber_g'] as num?)?.toDouble() ?? 0,
          sodium: (m['sodium_mg'] as num?)?.toDouble() ?? 0,
          sugar: (m['sugar_g'] as num?)?.toDouble() ?? 0,
          cholesterol: (m['cholesterol_mg'] as num?)?.toDouble() ?? 0,
          iron: (m['iron_mg'] as num?)?.toDouble() ?? 0,
          calcium: (m['calcium_mg'] as num?)?.toDouble() ?? 0,
          potassium: (m['potassium_mg'] as num?)?.toDouble() ?? 0,
          category: 'API Results',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
