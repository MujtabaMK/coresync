import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/recipe_repository.dart';
import '../../data/recipe_seed_service.dart';
import '../../domain/recipe_model.dart';

enum RecipeSortType {
  none('None'),
  highestProtein('Highest Protein'),
  lowestCalories('Lowest Calories'),
  highestCarbs('Highest Carbs'),
  highestFat('Highest Fat'),
  lowestFat('Lowest Fat');

  const RecipeSortType(this.label);
  final String label;
}

class RecipeState {
  const RecipeState({
    this.recipes = const [],
    this.isLoading = false,
    this.isSeeding = false,
    this.error,
    this.selectedCategory = RecipeCategory.breakfast,
    this.searchQuery = '',
    this.sortType = RecipeSortType.none,
    this.searchResults = const [],
    this.isSearching = false,
    this.isCalorieSearch = false,
    this.calorieTarget = 0,
    this.vegOnly = false,
  });

  final List<RecipeModel> recipes;
  final bool isLoading;
  final bool isSeeding;
  final String? error;
  final RecipeCategory selectedCategory;
  final String searchQuery;
  final RecipeSortType sortType;
  final List<RecipeModel> searchResults;
  final bool isSearching;
  final bool isCalorieSearch;
  final int calorieTarget;
  final bool vegOnly;

  /// Active when there's a text search, calorie search, or a sort chip selected.
  bool get isInSearchMode =>
      searchQuery.isNotEmpty || sortType != RecipeSortType.none;

  RecipeState copyWith({
    List<RecipeModel>? recipes,
    bool? isLoading,
    bool? isSeeding,
    String? error,
    bool clearError = false,
    RecipeCategory? selectedCategory,
    String? searchQuery,
    RecipeSortType? sortType,
    List<RecipeModel>? searchResults,
    bool? isSearching,
    bool? isCalorieSearch,
    int? calorieTarget,
    bool? vegOnly,
  }) {
    return RecipeState(
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      isSeeding: isSeeding ?? this.isSeeding,
      error: clearError ? null : (error ?? this.error),
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      sortType: sortType ?? this.sortType,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      isCalorieSearch: isCalorieSearch ?? this.isCalorieSearch,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      vegOnly: vegOnly ?? this.vegOnly,
    );
  }
}

class RecipeCubit extends Cubit<RecipeState> {
  RecipeCubit({required RecipeRepository repository})
      : _repository = repository,
        super(const RecipeState());

  final RecipeRepository _repository;
  List<RecipeModel>? _allRecipesCache;

  List<RecipeModel> _applyVegFilter(List<RecipeModel> recipes) {
    if (!state.vegOnly) return recipes;
    return recipes.where((r) => r.isVegetarian).toList();
  }

  Future<void> toggleVegOnly() async {
    emit(state.copyWith(vegOnly: !state.vegOnly));
    if (state.isInSearchMode) {
      await searchRecipes(state.searchQuery);
    } else {
      await loadCategory(state.selectedCategory);
    }
  }

  Future<void> seedAndLoad() async {
    emit(state.copyWith(isSeeding: true, clearError: true));
    try {
      final seeded = await _repository.isSeeded();
      if (!seeded) {
        await RecipeSeedService(repository: _repository).seedIfNeeded();
      }
      emit(state.copyWith(isSeeding: false));
      await loadCategory(state.selectedCategory);
    } catch (e) {
      emit(state.copyWith(isSeeding: false, error: e.toString()));
    }
  }

  Future<void> loadCategory(RecipeCategory category) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      selectedCategory: category,
    ));
    try {
      final recipes = await _repository.getByCategory(category);
      emit(state.copyWith(recipes: _applyVegFilter(recipes), isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<List<RecipeModel>> _ensureAllRecipes() async {
    _allRecipesCache ??= await _repository.getAll();
    return _allRecipesCache!;
  }

  /// Parses calorie queries like "200", "200 kcal", "200 cal", "under 300".
  static int? _parseCalorieQuery(String lower) {
    // "200 kcal", "200 cal", "200kcal"
    final kcalMatch = RegExp(r'^(\d+)\s*(?:kcal|cal)$').firstMatch(lower);
    if (kcalMatch != null) return int.tryParse(kcalMatch.group(1)!);

    // "under 300", "below 250"
    final underMatch =
        RegExp(r'^(?:under|below)\s+(\d+)(?:\s*(?:kcal|cal))?$')
            .firstMatch(lower);
    if (underMatch != null) return int.tryParse(underMatch.group(1)!);

    // Plain number (3+ digits to avoid matching short strings)
    final plainMatch = RegExp(r'^(\d{3,})$').firstMatch(lower);
    if (plainMatch != null) return int.tryParse(plainMatch.group(1)!);

    return null;
  }

  Future<void> searchRecipes(String query) async {
    if (query.isEmpty) {
      // If a sort chip is still active, show all recipes with that sort
      if (state.sortType != RecipeSortType.none) {
        emit(state.copyWith(
          searchQuery: '',
          isSearching: true,
          isCalorieSearch: false,
          calorieTarget: 0,
        ));
        try {
          final all = await _ensureAllRecipes();
          final sorted = _applySorting(
              _applyVegFilter(List.of(all)), state.sortType);
          emit(state.copyWith(searchResults: sorted, isSearching: false));
        } catch (e) {
          emit(state.copyWith(isSearching: false, error: e.toString()));
        }
      } else {
        emit(state.copyWith(
          searchQuery: '',
          searchResults: const [],
          sortType: RecipeSortType.none,
          isSearching: false,
          isCalorieSearch: false,
          calorieTarget: 0,
        ));
      }
      return;
    }

    emit(state.copyWith(searchQuery: query, isSearching: true));

    try {
      final all = await _ensureAllRecipes();
      final lower = query.toLowerCase();

      // Check for calorie search pattern
      final kcalTarget = _parseCalorieQuery(lower);
      if (kcalTarget != null) {
        final min = (kcalTarget - 50).clamp(0, 99999);
        final max = kcalTarget + 50;
        var filtered = _applyVegFilter(all
            .where((r) => r.calories >= min && r.calories <= max)
            .toList())
          ..sort((a, b) =>
              (a.calories - kcalTarget).abs().compareTo(
                  (b.calories - kcalTarget).abs()));
        filtered = _applySorting(filtered, state.sortType);
        emit(state.copyWith(
          searchResults: filtered,
          isSearching: false,
          isCalorieSearch: true,
          calorieTarget: kcalTarget,
        ));
        return;
      }

      // Name search
      var filtered = _applyVegFilter(all
          .where((r) => r.name.toLowerCase().contains(lower))
          .toList());
      filtered = _applySorting(filtered, state.sortType);

      emit(state.copyWith(
        searchResults: filtered,
        isSearching: false,
        isCalorieSearch: false,
        calorieTarget: 0,
      ));
    } catch (e) {
      emit(state.copyWith(isSearching: false, error: e.toString()));
    }
  }

  Future<void> sortRecipes(RecipeSortType sortType) async {
    final newSort = state.sortType == sortType ? RecipeSortType.none : sortType;

    // If clearing sort and no text query, go back to tab view
    if (newSort == RecipeSortType.none && state.searchQuery.isEmpty) {
      emit(state.copyWith(
        sortType: RecipeSortType.none,
        searchResults: const [],
        isCalorieSearch: false,
        calorieTarget: 0,
      ));
      return;
    }

    emit(state.copyWith(sortType: newSort, isSearching: true));

    try {
      final all = await _ensureAllRecipes();
      List<RecipeModel> results;

      if (state.searchQuery.isNotEmpty) {
        // Re-run search with new sort
        final lower = state.searchQuery.toLowerCase();
        final kcalTarget = _parseCalorieQuery(lower);
        if (kcalTarget != null) {
          final min = (kcalTarget - 50).clamp(0, 99999);
          final max = kcalTarget + 50;
          results = _applyVegFilter(all
              .where((r) => r.calories >= min && r.calories <= max)
              .toList());
          if (newSort == RecipeSortType.none) {
            results.sort((a, b) =>
                (a.calories - kcalTarget).abs().compareTo(
                    (b.calories - kcalTarget).abs()));
          }
        } else {
          results = _applyVegFilter(all
              .where((r) => r.name.toLowerCase().contains(lower))
              .toList());
        }
      } else {
        // No text query — show all recipes with this sort
        results = _applyVegFilter(List.of(all));
      }

      results = _applySorting(results, newSort);
      emit(state.copyWith(searchResults: results, isSearching: false));
    } catch (e) {
      emit(state.copyWith(isSearching: false, error: e.toString()));
    }
  }

  List<RecipeModel> _applySorting(
      List<RecipeModel> recipes, RecipeSortType sort) {
    switch (sort) {
      case RecipeSortType.none:
        return recipes;
      case RecipeSortType.highestProtein:
        return recipes..sort((a, b) => b.protein.compareTo(a.protein));
      case RecipeSortType.lowestCalories:
        return recipes..sort((a, b) => a.calories.compareTo(b.calories));
      case RecipeSortType.highestCarbs:
        return recipes..sort((a, b) => b.carbs.compareTo(a.carbs));
      case RecipeSortType.highestFat:
        return recipes..sort((a, b) => b.fat.compareTo(a.fat));
      case RecipeSortType.lowestFat:
        return recipes..sort((a, b) => a.fat.compareTo(b.fat));
    }
  }
}
