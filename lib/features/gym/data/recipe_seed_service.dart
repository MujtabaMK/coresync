import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/recipe_model.dart';
import 'recipe_repository.dart';

class RecipeSeedService {
  RecipeSeedService({required RecipeRepository repository})
      : _repository = repository;

  final RecipeRepository _repository;

  /// Bump this version whenever recipe data changes to trigger re-seeding.
  static const _currentVersion = 4;

  static const _assetFiles = [
    'assets/recipes/breakfast.json',
    'assets/recipes/lunch.json',
    'assets/recipes/dinner.json',
    'assets/recipes/snack.json',
    'assets/recipes/salad.json',
    'assets/recipes/soup.json',
    'assets/recipes/smoothie.json',
    'assets/recipes/healthyDessert.json',
  ];

  Future<void> seedIfNeeded() async {
    final storedVersion = await _repository.getSeededVersion();
    if (storedVersion >= _currentVersion) return;

    // Delete old recipes if they exist (version mismatch)
    if (await _repository.isSeeded()) {
      await _repository.deleteAllRecipes();
    }

    final allRecipes = <RecipeModel>[];

    for (final path in _assetFiles) {
      final jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      final recipes = jsonList
          .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      allRecipes.addAll(recipes);
    }

    await _repository.seedRecipes(allRecipes, version: _currentVersion);
  }
}
