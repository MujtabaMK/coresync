import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/food_scan_model.dart';
import 'common_foods_data.dart';

class GeminiFoodService {
  GeminiFoodService._();
  static final instance = GeminiFoodService._();

  GenerativeModel? _model;

  GenerativeModel get _gemini {
    _model ??= GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: AppConstants.geminiApiKey,
    );
    return _model!;
  }

  Future<List<FoodItem>> analyzeFoodImage(Uint8List imageBytes) async {
    final prompt = TextPart(
      'Identify all food items in this image. For each item return: '
      'name, estimated calories, protein (g), carbs (g), fat (g), quantity. '
      'Return ONLY a valid JSON array with no extra text. Example format: '
      '[{"name":"Rice","calories":200,"protein":4,"carbs":45,"fat":1,"quantity":1}]',
    );

    final imagePart = DataPart('image/jpeg', imageBytes);

    final response = await _gemini.generateContent([
      Content.multi([prompt, imagePart]),
    ]);

    final text = response.text;
    if (text == null || text.isEmpty) return [];

    return _parseResponse(text);
  }

  /// Search for food nutrition data by name using Gemini AI.
  Future<List<CommonFoodItem>> searchFoodByName(String query) async {
    final prompt = TextPart(
      'Give me nutrition data for "$query". Return a JSON array of matching foods '
      '(up to 5 results). Each object must have these fields: '
      'name (string), servingSize (string like "1 cup (240g)" or "100g"), '
      'calories (number), protein (number, grams), carbs (number, grams), '
      'fat (number, grams), fiber (number, grams), sodium (number, mg), '
      'sugar (number, grams), cholesterol (number, mg), iron (number, mg), '
      'calcium (number, mg), potassium (number, mg), category (string like '
      '"Grains", "Protein", "Dairy", "Fruits", "Vegetables", "Snacks", "Beverages", "Other"). '
      'Return ONLY a valid JSON array with no extra text.',
    );

    final response = await _gemini.generateContent([
      Content.text(prompt.text),
    ]);

    final text = response.text;
    if (text == null || text.isEmpty) return [];

    return _parseFoodSearchResponse(text);
  }

  List<CommonFoodItem> _parseFoodSearchResponse(String text) {
    var cleaned = text.trim();
    // Extract JSON array from any surrounding text or markdown
    final start = cleaned.indexOf('[');
    final end = cleaned.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      cleaned = cleaned.substring(start, end + 1);
    }

    try {
      final list = jsonDecode(cleaned) as List<dynamic>;
      return list.map((e) {
        final j = e as Map<String, dynamic>;
        return CommonFoodItem(
          name: j['name'] as String? ?? '',
          servingSize: j['servingSize'] as String? ?? '1 serving',
          calories: (j['calories'] as num?)?.toDouble() ?? 0,
          protein: (j['protein'] as num?)?.toDouble() ?? 0,
          carbs: (j['carbs'] as num?)?.toDouble() ?? 0,
          fat: (j['fat'] as num?)?.toDouble() ?? 0,
          fiber: (j['fiber'] as num?)?.toDouble() ?? 0,
          sodium: (j['sodium'] as num?)?.toDouble() ?? 0,
          sugar: (j['sugar'] as num?)?.toDouble() ?? 0,
          cholesterol: (j['cholesterol'] as num?)?.toDouble() ?? 0,
          iron: (j['iron'] as num?)?.toDouble() ?? 0,
          calcium: (j['calcium'] as num?)?.toDouble() ?? 0,
          potassium: (j['potassium'] as num?)?.toDouble() ?? 0,
          category: j['category'] as String? ?? 'Other',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<FoodItem> _parseResponse(String text) {
    // Extract JSON array from response (handle markdown code blocks)
    var cleaned = text.trim();
    if (cleaned.contains('```')) {
      final start = cleaned.indexOf('[');
      final end = cleaned.lastIndexOf(']');
      if (start != -1 && end != -1) {
        cleaned = cleaned.substring(start, end + 1);
      }
    }

    try {
      final list = jsonDecode(cleaned) as List<dynamic>;
      return list
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
