import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/recipe_repository.dart';
import '../../data/recipe_seed_service.dart';
import '../../domain/recipe_model.dart';

class RecipeState {
  const RecipeState({
    this.recipes = const [],
    this.isLoading = false,
    this.isSeeding = false,
    this.error,
    this.selectedCategory = RecipeCategory.breakfast,
  });

  final List<RecipeModel> recipes;
  final bool isLoading;
  final bool isSeeding;
  final String? error;
  final RecipeCategory selectedCategory;

  RecipeState copyWith({
    List<RecipeModel>? recipes,
    bool? isLoading,
    bool? isSeeding,
    String? error,
    bool clearError = false,
    RecipeCategory? selectedCategory,
  }) {
    return RecipeState(
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      isSeeding: isSeeding ?? this.isSeeding,
      error: clearError ? null : (error ?? this.error),
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class RecipeCubit extends Cubit<RecipeState> {
  RecipeCubit({required RecipeRepository repository})
      : _repository = repository,
        super(const RecipeState());

  final RecipeRepository _repository;

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
      emit(state.copyWith(recipes: recipes, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
