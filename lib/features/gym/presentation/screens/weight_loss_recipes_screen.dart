import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_detail_sheet.dart';

class WeightLossRecipesScreen extends StatefulWidget {
  const WeightLossRecipesScreen({super.key});

  @override
  State<WeightLossRecipesScreen> createState() =>
      _WeightLossRecipesScreenState();
}

class _WeightLossRecipesScreenState extends State<WeightLossRecipesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: RecipeCategory.values.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);

    // Trigger initial seed + load
    context.read<RecipeCubit>().seedAndLoad();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final category = RecipeCategory.values[_tabController.index];
    context.read<RecipeCubit>().loadCategory(category);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      context.read<RecipeCubit>().searchRecipes('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<RecipeCubit>().searchRecipes(value.trim());
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    context.read<RecipeCubit>().searchRecipes('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecipeCubit, RecipeState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Healthy Recipes'),
            bottom: state.isInSearchMode
                ? null
                : TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: RecipeCategory.values
                        .map((c) => Tab(text: c.label))
                        .toList(),
                  ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, RecipeState state) {
    if (state.isSeeding) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Setting up recipes for the first time...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<RecipeCubit>().seedAndLoad(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name or kcal (e.g. "200 kcal")...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        // Sort chips — always visible
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: RecipeSortType.values
                .where((s) => s != RecipeSortType.none)
                .map((sort) {
              final selected = state.sortType == sort;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(sort.label),
                  selected: selected,
                  onSelected: (_) =>
                      context.read<RecipeCubit>().sortRecipes(sort),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ),
        ),
        // Calorie search banner
        if (state.isCalorieSearch && state.searchResults.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.local_fire_department,
                    size: 16,
                    color: theme.colorScheme.onTertiaryContainer),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Recipes around ${state.calorieTarget} kcal '
                    '(${(state.calorieTarget - 50).clamp(0, 99999)}–${state.calorieTarget + 50} kcal)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Content
        Expanded(
          child: state.isInSearchMode
              ? _buildSearchResults(state)
              : TabBarView(
                  controller: _tabController,
                  children: RecipeCategory.values
                      .map((c) => _RecipeList(
                            category: c,
                            recipes: state.selectedCategory == c
                                ? state.recipes
                                : const [],
                            isLoading:
                                state.isLoading && state.selectedCategory == c,
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(RecipeState state) {
    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.searchResults.isEmpty) {
      return Center(
        child: Text(
          state.searchQuery.isNotEmpty
              ? 'No recipes found for "${state.searchQuery}"'
              : 'No recipes found',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) {
        return _RecipeCard(recipe: state.searchResults[index]);
      },
    );
  }
}

class _RecipeList extends StatelessWidget {
  const _RecipeList({
    required this.category,
    required this.recipes,
    required this.isLoading,
  });

  final RecipeCategory category;
  final List<RecipeModel> recipes;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recipes.isEmpty) {
      return const Center(child: Text('No recipes yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _RecipeCard(recipe: recipe);
      },
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});
  final RecipeModel recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (recipe.isVegetarian)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Veg',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ChipInfo(
                    icon: Icons.local_fire_department,
                    label: '${recipe.calories} kcal',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _ChipInfo(
                    icon: Icons.egg_alt,
                    label: '${recipe.protein.toStringAsFixed(0)}g protein',
                    color: Colors.blue,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeDetailSheet(recipe: recipe),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
