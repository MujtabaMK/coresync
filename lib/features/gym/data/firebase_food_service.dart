import 'package:cloud_firestore/cloud_firestore.dart';

import 'common_foods_data.dart';

/// Service to search food items stored in Firestore.
/// Foods are stored in a top-level `foods` collection with fields:
/// name, servingSize, calories, protein, carbs, fat, fiber, category, searchTerms
class FirebaseFoodService {
  FirebaseFoodService._();
  static final instance = FirebaseFoodService._();

  final _firestore = FirebaseFirestore.instance;
  CollectionReference get _foodsCol => _firestore.collection('foods');

  /// Search foods by query string. Uses Firestore array-contains on searchTerms.
  /// Falls back to prefix matching on the name field.
  Future<List<CommonFoodItem>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();

    try {
      // Search using searchTerms array-contains for exact keyword match
      final snapshot = await _foodsCol
          .where('searchTerms', arrayContains: q)
          .limit(50)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map(_fromDoc).toList();
      }

      // Fallback: prefix search on nameLower field
      final prefixEnd = q.substring(0, q.length - 1) +
          String.fromCharCode(q.codeUnitAt(q.length - 1) + 1);
      final prefixSnapshot = await _foodsCol
          .where('nameLower', isGreaterThanOrEqualTo: q)
          .where('nameLower', isLessThan: prefixEnd)
          .limit(50)
          .get();

      return prefixSnapshot.docs.map(_fromDoc).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get all food categories available in Firestore.
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _foodsCol
          .orderBy('category')
          .get();
      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }
      return categories.toList()..sort();
    } catch (_) {
      return [];
    }
  }

  /// Get foods by category.
  Future<List<CommonFoodItem>> getFoodsByCategory(String category) async {
    try {
      final snapshot = await _foodsCol
          .where('category', isEqualTo: category)
          .orderBy('name')
          .limit(100)
          .get();
      return snapshot.docs.map(_fromDoc).toList();
    } catch (_) {
      return [];
    }
  }

  CommonFoodItem _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommonFoodItem(
      name: d['name'] as String? ?? '',
      servingSize: d['servingSize'] as String? ?? '1 serving',
      calories: (d['calories'] as num?)?.toDouble() ?? 0,
      protein: (d['protein'] as num?)?.toDouble() ?? 0,
      carbs: (d['carbs'] as num?)?.toDouble() ?? 0,
      fat: (d['fat'] as num?)?.toDouble() ?? 0,
      fiber: (d['fiber'] as num?)?.toDouble() ?? 0,
      sodium: (d['sodium'] as num?)?.toDouble() ?? 0,
      sugar: (d['sugar'] as num?)?.toDouble() ?? 0,
      cholesterol: (d['cholesterol'] as num?)?.toDouble() ?? 0,
      iron: (d['iron'] as num?)?.toDouble() ?? 0,
      calcium: (d['calcium'] as num?)?.toDouble() ?? 0,
      potassium: (d['potassium'] as num?)?.toDouble() ?? 0,
      vitaminA: (d['vitaminA'] as num?)?.toDouble() ?? 0,
      vitaminB12: (d['vitaminB12'] as num?)?.toDouble() ?? 0,
      vitaminC: (d['vitaminC'] as num?)?.toDouble() ?? 0,
      vitaminD: (d['vitaminD'] as num?)?.toDouble() ?? 0,
      zinc: (d['zinc'] as num?)?.toDouble() ?? 0,
      magnesium: (d['magnesium'] as num?)?.toDouble() ?? 0,
      vitaminE: (d['vitaminE'] as num?)?.toDouble() ?? 0,
      vitaminK: (d['vitaminK'] as num?)?.toDouble() ?? 0,
      vitaminB6: (d['vitaminB6'] as num?)?.toDouble() ?? 0,
      folate: (d['folate'] as num?)?.toDouble() ?? 0,
      phosphorus: (d['phosphorus'] as num?)?.toDouble() ?? 0,
      selenium: (d['selenium'] as num?)?.toDouble() ?? 0,
      manganese: (d['manganese'] as num?)?.toDouble() ?? 0,
      category: d['category'] as String? ?? '',
    );
  }

  /// Seed a single food item to Firestore (for admin/setup use).
  Future<void> seedFood(CommonFoodItem food) async {
    final nameLower = food.name.toLowerCase();
    final searchTerms = _buildSearchTerms(nameLower);

    await _foodsCol.doc(nameLower.replaceAll(RegExp(r'[^a-z0-9]'), '_')).set({
      'name': food.name,
      'nameLower': nameLower,
      'servingSize': food.servingSize,
      'calories': food.calories,
      'protein': food.protein,
      'carbs': food.carbs,
      'fat': food.fat,
      'fiber': food.fiber,
      'sodium': food.sodium,
      'sugar': food.sugar,
      'cholesterol': food.cholesterol,
      'iron': food.iron,
      'calcium': food.calcium,
      'potassium': food.potassium,
      'vitaminA': food.vitaminA,
      'vitaminB12': food.vitaminB12,
      'vitaminC': food.vitaminC,
      'vitaminD': food.vitaminD,
      'zinc': food.zinc,
      'magnesium': food.magnesium,
      'vitaminE': food.vitaminE,
      'vitaminK': food.vitaminK,
      'vitaminB6': food.vitaminB6,
      'folate': food.folate,
      'phosphorus': food.phosphorus,
      'selenium': food.selenium,
      'manganese': food.manganese,
      'category': food.category,
      'searchTerms': searchTerms,
    });
  }

  /// Batch seed multiple foods to Firestore.
  Future<int> seedFoods(List<CommonFoodItem> foods) async {
    int count = 0;
    // Firestore batch limit is 500
    for (int i = 0; i < foods.length; i += 450) {
      final batch = _firestore.batch();
      final end = (i + 450).clamp(0, foods.length);
      for (int j = i; j < end; j++) {
        final food = foods[j];
        final nameLower = food.name.toLowerCase();
        final docId = nameLower.replaceAll(RegExp(r'[^a-z0-9]'), '_');
        final ref = _foodsCol.doc(docId);
        batch.set(ref, {
          'name': food.name,
          'nameLower': nameLower,
          'servingSize': food.servingSize,
          'calories': food.calories,
          'protein': food.protein,
          'carbs': food.carbs,
          'fat': food.fat,
          'fiber': food.fiber,
          'sodium': food.sodium,
          'sugar': food.sugar,
          'cholesterol': food.cholesterol,
          'iron': food.iron,
          'calcium': food.calcium,
          'potassium': food.potassium,
          'vitaminA': food.vitaminA,
          'vitaminB12': food.vitaminB12,
          'vitaminC': food.vitaminC,
          'vitaminD': food.vitaminD,
          'zinc': food.zinc,
          'magnesium': food.magnesium,
          'vitaminE': food.vitaminE,
          'vitaminK': food.vitaminK,
          'vitaminB6': food.vitaminB6,
          'folate': food.folate,
          'phosphorus': food.phosphorus,
          'selenium': food.selenium,
          'manganese': food.manganese,
          'category': food.category,
          'searchTerms': _buildSearchTerms(nameLower),
        });
        count++;
      }
      await batch.commit();
    }
    return count;
  }

  List<String> _buildSearchTerms(String nameLower) {
    final words = nameLower.split(RegExp(r'[\s/()&,]+'))
        .where((w) => w.length > 1)
        .toList();
    // Add full name and individual words as search terms
    return <String>{nameLower, ...words}.toList();
  }
}