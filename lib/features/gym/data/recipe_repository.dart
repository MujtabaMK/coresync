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

  Future<int> getSeededVersion() async {
    final doc = await _collection.doc('_meta').get();
    if (!doc.exists) return 0;
    return (doc.data()?['version'] as int?) ?? 0;
  }

  Future<void> deleteAllRecipes() async {
    _cache.clear();
    const batchSize = 500;
    while (true) {
      final snapshot = await _collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> seedRecipes(List<RecipeModel> recipes, {int version = 1}) async {
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
    // Store version metadata
    await _collection.doc('_meta').set({'version': version});
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
