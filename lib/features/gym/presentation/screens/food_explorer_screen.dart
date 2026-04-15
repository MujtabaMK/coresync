import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/common_foods_data.dart';
import '../../data/food_database_service.dart';

class FoodExplorerScreen extends StatefulWidget {
  const FoodExplorerScreen({super.key});

  @override
  State<FoodExplorerScreen> createState() => _FoodExplorerScreenState();
}

class _FoodExplorerScreenState extends State<FoodExplorerScreen> {
  final _searchCtrl = TextEditingController();
  final _foodDb = FoodDatabaseService.instance;

  String _query = '';
  List<CommonFoodItem> _results = [];
  bool _searching = false;

  // Nutrient mode
  bool _isNutrientMode = false;
  String _nutrientDisplayName = '';
  String _nutrientColumn = '';

  Timer? _debounce;

  static const _nutrientMap = {
    'vitamin a': 'vitaminA',
    'vitamin b6': 'vitaminB6',
    'vitamin b12': 'vitaminB12',
    'vitamin c': 'vitaminC',
    'vitamin d': 'vitaminD',
    'vitamin e': 'vitaminE',
    'vitamin k': 'vitaminK',
    'iron': 'iron',
    'calcium': 'calcium',
    'potassium': 'potassium',
    'zinc': 'zinc',
    'magnesium': 'magnesium',
    'sodium': 'sodium',
    'fiber': 'fiber',
    'fibre': 'fiber',
    'protein': 'protein',
    'carbs': 'carbs',
    'fat': 'fat',
    'sugar': 'sugar',
    'cholesterol': 'cholesterol',
    'folate': 'folate',
    'phosphorus': 'phosphorus',
    'selenium': 'selenium',
    'manganese': 'manganese',
    'calories': 'calories',
  };

  // Display name → unit for nutrient values
  static const _nutrientUnits = {
    'calories': 'kcal',
    'protein': 'g',
    'carbs': 'g',
    'fat': 'g',
    'fiber': 'g',
    'sugar': 'g',
    'sodium': 'mg',
    'cholesterol': 'mg',
    'iron': 'mg',
    'calcium': 'mg',
    'potassium': 'mg',
    'vitaminA': 'mcg',
    'vitaminB12': 'mcg',
    'vitaminC': 'mg',
    'vitaminD': 'mcg',
    'zinc': 'mg',
    'magnesium': 'mg',
    'vitaminE': 'mg',
    'vitaminK': 'mcg',
    'vitaminB6': 'mg',
    'folate': 'mcg',
    'phosphorus': 'mg',
    'selenium': 'mcg',
    'manganese': 'mg',
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();

    if (value.trim().length < 2) {
      setState(() {
        _results = [];
        _isNutrientMode = false;
        _searching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 200), () {
      _performSearch(value.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _searching = true);

    final lower = query.toLowerCase();

    // Check if query matches a nutrient keyword
    String? matchedColumn;
    String? matchedDisplay;
    for (final entry in _nutrientMap.entries) {
      if (lower == entry.key || lower.startsWith('${entry.key} ')) {
        matchedColumn = entry.value;
        matchedDisplay = entry.key;
        break;
      }
    }

    if (matchedColumn != null) {
      // Nutrient mode
      try {
        final results =
            await _foodDb.getTopFoodsByNutrient(matchedColumn, limit: 50);
        if (!mounted) return;
        setState(() {
          _results = results;
          _isNutrientMode = true;
          _nutrientColumn = matchedColumn!;
          _nutrientDisplayName = _capitalize(matchedDisplay!);
          _searching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _searching = false);
      }
    } else {
      // Food name search mode
      try {
        final results = await _foodDb.searchByName(query, limit: 50);
        if (!mounted) return;
        setState(() {
          _results = results;
          _isNutrientMode = false;
          _searching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _searching = false);
      }
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  double _getNutrientValue(CommonFoodItem food, String column) {
    switch (column) {
      case 'calories':
        return food.calories;
      case 'protein':
        return food.protein;
      case 'carbs':
        return food.carbs;
      case 'fat':
        return food.fat;
      case 'fiber':
        return food.fiber;
      case 'sodium':
        return food.sodium;
      case 'sugar':
        return food.sugar;
      case 'cholesterol':
        return food.cholesterol;
      case 'iron':
        return food.iron;
      case 'calcium':
        return food.calcium;
      case 'potassium':
        return food.potassium;
      case 'vitaminA':
        return food.vitaminA;
      case 'vitaminB12':
        return food.vitaminB12;
      case 'vitaminC':
        return food.vitaminC;
      case 'vitaminD':
        return food.vitaminD;
      case 'zinc':
        return food.zinc;
      case 'magnesium':
        return food.magnesium;
      case 'vitaminE':
        return food.vitaminE;
      case 'vitaminK':
        return food.vitaminK;
      case 'vitaminB6':
        return food.vitaminB6;
      case 'folate':
        return food.folate;
      case 'phosphorus':
        return food.phosphorus;
      case 'selenium':
        return food.selenium;
      case 'manganese':
        return food.manganese;
      default:
        return 0;
    }
  }

  String _formatNutrientValue(double value, String column) {
    final unit = _nutrientUnits[column] ?? '';
    if (value >= 100) {
      return '${value.round()} $unit';
    }
    return '${value.toStringAsFixed(1)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Food Explorer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search food or nutrient (e.g. "chicken", "vitamin d")...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(),
            ),
          if (_isNutrientMode && _results.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.star,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Showing foods highest in $_nutrientDisplayName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: _query.trim().length < 2
                ? _buildEmptyState(theme)
                : _results.isEmpty && !_searching
                    ? _buildNoResults(theme)
                    : _isNutrientMode
                        ? _buildNutrientRanking(theme)
                        : _buildFoodResults(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Search for a food or nutrient',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try "chicken", "vitamin d", "iron", "calcium"',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'No foods found for "$_query"',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nutrient Ranking Mode ──

  Widget _buildNutrientRanking(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final food = _results[index];
        final value = _getNutrientValue(food, _nutrientColumn);
        final formatted = _formatNutrientValue(value, _nutrientColumn);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: index < 3
                        ? Colors.amber.withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: index < 3 ? Colors.amber.shade800 : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Food info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${food.servingSize}  ·  ${food.calories.round()} kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _MacroChip('P', '${food.protein.round()}g',
                              Colors.blue),
                          const SizedBox(width: 6),
                          _MacroChip('C', '${food.carbs.round()}g',
                              Colors.orange),
                          const SizedBox(width: 6),
                          _MacroChip(
                              'F', '${food.fat.round()}g', Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Nutrient value highlight
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatted,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Food Name Search Mode ──

  Widget _buildFoodResults(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final food = _results[index];
        return _FoodDetailCard(food: food);
      },
    );
  }
}

// ── Macro Chip ──

class _MacroChip extends StatelessWidget {
  const _MacroChip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Food Detail Card with expandable micronutrients ──

class _FoodDetailCard extends StatefulWidget {
  const _FoodDetailCard({required this.food});
  final CommonFoodItem food;

  @override
  State<_FoodDetailCard> createState() => _FoodDetailCardState();
}

class _FoodDetailCardState extends State<_FoodDetailCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = widget.food;

    // Build micronutrient entries (non-zero only)
    final micros = <MapEntry<String, String>>[];
    void addIfNonZero(String label, double value, String unit) {
      if (value > 0) {
        final formatted = value >= 100
            ? '${value.round()} $unit'
            : '${value.toStringAsFixed(1)} $unit';
        micros.add(MapEntry(label, formatted));
      }
    }

    addIfNonZero('Fiber', food.fiber, 'g');
    addIfNonZero('Sugar', food.sugar, 'g');
    addIfNonZero('Sodium', food.sodium, 'mg');
    addIfNonZero('Cholesterol', food.cholesterol, 'mg');
    addIfNonZero('Iron', food.iron, 'mg');
    addIfNonZero('Calcium', food.calcium, 'mg');
    addIfNonZero('Potassium', food.potassium, 'mg');
    addIfNonZero('Vitamin A', food.vitaminA, 'mcg');
    addIfNonZero('Vitamin B6', food.vitaminB6, 'mg');
    addIfNonZero('Vitamin B12', food.vitaminB12, 'mcg');
    addIfNonZero('Vitamin C', food.vitaminC, 'mg');
    addIfNonZero('Vitamin D', food.vitaminD, 'mcg');
    addIfNonZero('Vitamin E', food.vitaminE, 'mg');
    addIfNonZero('Vitamin K', food.vitaminK, 'mcg');
    addIfNonZero('Zinc', food.zinc, 'mg');
    addIfNonZero('Magnesium', food.magnesium, 'mg');
    addIfNonZero('Folate', food.folate, 'mcg');
    addIfNonZero('Phosphorus', food.phosphorus, 'mg');
    addIfNonZero('Selenium', food.selenium, 'mcg');
    addIfNonZero('Manganese', food.manganese, 'mg');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        food.servingSize,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${food.calories.round()} kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Macros row
            Row(
              children: [
                _MacroChip('P', '${food.protein.round()}g', Colors.blue),
                const SizedBox(width: 8),
                _MacroChip('C', '${food.carbs.round()}g', Colors.orange),
                const SizedBox(width: 8),
                _MacroChip('F', '${food.fat.round()}g', Colors.red),
              ],
            ),
            // Expandable micronutrients
            if (micros.isNotEmpty) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.science,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Micronutrients',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      RotationTransition(
                        turns: _rotationAnimation,
                        child: Icon(
                          Icons.expand_more,
                          size: 18,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  children: micros.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            entry.value,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
