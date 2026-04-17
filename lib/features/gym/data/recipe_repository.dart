import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/recipe_model.dart';

class RecipeRepository {
  RecipeRepository();

  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.recipesCollection);

  // In-memory cache per category
  final Map<RecipeCategory, List<RecipeModel>> _cache = {};

  Future<List<RecipeModel>> getByCategory(RecipeCategory category) async {
    if (_cache.containsKey(category)) return _cache[category]!;

    final snapshot =
        await _collection.where('category', isEqualTo: category.name).get();

    final recipes = snapshot.docs
        .map((doc) => RecipeModel.fromFirestore(doc.id, doc.data()))
        .toList();

    _cache[category] = recipes;
    return recipes;
  }

  Future<bool> isSeeded() async {
    final snapshot = await _collection.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> seedRecipes(List<RecipeModel> recipes) async {
    const batchSize = 500;
    for (var i = 0; i < recipes.length; i += batchSize) {
      final batch = _firestore.batch();
      final end =
          (i + batchSize > recipes.length) ? recipes.length : i + batchSize;
      for (var j = i; j < end; j++) {
        final doc = _collection.doc();
        batch.set(doc, recipes[j].toFirestore());
      }
      await batch.commit();
    }
  }

  /// Loads all categories into cache and returns a flat list of all recipes.
  Future<List<RecipeModel>> getAll() async {
    for (final category in RecipeCategory.values) {
      if (!_cache.containsKey(category)) {
        final snapshot = await _collection
            .where('category', isEqualTo: category.name)
            .get();
        _cache[category] = snapshot.docs
            .map((doc) => RecipeModel.fromFirestore(doc.id, doc.data()))
            .toList();
      }
    }
    return _cache.values.expand((list) => list).toList();
  }

  void clearCache() => _cache.clear();
}
