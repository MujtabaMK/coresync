import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';

import '../../data/common_foods_data.dart';
import '../../data/firebase_food_service.dart';
import '../../data/food_database_service.dart';
import '../../data/gemini_food_service.dart';
import '../../data/usda_food_service.dart';
import '../../domain/tracked_food_model.dart';
import '../providers/gym_provider.dart';
import 'create_food_screen.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key, required this.mealType});

  final MealType mealType;

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _foodDb = FoodDatabaseService.instance;

  String _query = '';

  // ── Browse mode (empty query) ──
  Map<String, int> _categoryCounts = {};
  String? _expandedCategory;
  List<CommonFoodItem> _expandedFoods = [];
  bool _loadingCategory = false;

  // ── Search mode (non-empty query) ──
  List<CommonFoodItem> _localResults = [];
  List<CommonFoodItem> _firebaseResults = [];
  List<CommonFoodItem> _usdaResults = [];
  bool _localSearching = false;
  bool _firebaseSearching = false;
  bool _usdaSearching = false;
  bool _usdaSearched = false; // true once user triggered online search

  List<CommonFoodItem> _geminiResults = [];
  bool _geminiSearching = false;
  bool _geminiSearched = false;

  Timer? _localDebounce;
  Timer? _firebaseDebounce;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _localDebounce?.cancel();
    _firebaseDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final counts = await _foodDb.getCategoryCounts();
    if (mounted) setState(() => _categoryCounts = counts);
  }

  // ── Search logic ──────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      _usdaResults = [];
      _usdaSearched = false;
      _geminiResults = [];
      _geminiSearched = false;
      if (value.isEmpty) {
        _localResults = [];
        _firebaseResults = [];
        _localSearching = false;
        _firebaseSearching = false;
      }
    });

    _localDebounce?.cancel();
    _firebaseDebounce?.cancel();

    if (value.trim().length >= 2) {
      // Local DB search – fast
      _localDebounce = Timer(const Duration(milliseconds: 150), () {
        _searchLocal(value.trim());
      });
      // Firebase – slower
      _firebaseDebounce = Timer(const Duration(milliseconds: 600), () {
        _searchFirebase(value.trim());
      });
    } else {
      setState(() {
        _firebaseResults = [];
        _firebaseSearching = false;
      });
    }
  }

  Future<void> _searchLocal(String query) async {
    setState(() => _localSearching = true);
    final results = await _foodDb.searchByName(query);
    if (!mounted) return;
    setState(() {
      _localResults = results;
      _localSearching = false;
    });
  }

  Future<void> _searchFirebase(String query) async {
    setState(() => _firebaseSearching = true);
    try {
      final results = await FirebaseFoodService.instance.search(query);
      if (!mounted) return;
      setState(() {
        _firebaseResults = results;
        _firebaseSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _firebaseSearching = false);
    }
  }

  /// Called when user taps "Search online" – only then do we hit USDA.
  Future<void> _searchUsda() async {
    final q = _query.trim();
    if (q.isEmpty) return;
    setState(() {
      _usdaSearching = true;
      _usdaSearched = true;
    });
    try {
      final results = await UsdaFoodService.instance.search(q, limit: 10);
      if (!mounted) return;
      setState(() {
        _usdaResults = results;
        _usdaSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _usdaSearching = false);
    }
  }

  /// Called when user taps "Search with AI" – Gemini text search fallback.
  Future<void> _searchGemini() async {
    final q = _query.trim();
    if (q.isEmpty) return;
    setState(() {
      _geminiSearching = true;
      _geminiSearched = true;
    });
    try {
      final results = await GeminiFoodService.instance.searchFoodByName(q);
      if (!mounted) return;
      setState(() {
        _geminiResults = results;
        _geminiSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _geminiSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI search failed: $e')),
      );
    }
  }

  /// Voice search: listen via mic and fill the search bar with result.
  Future<void> _voiceSearch() async {
    final speech = stt.SpeechToText();
    final available = await speech.initialize();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }
    if (!mounted) return;

    String transcript = '';
    bool dialogPopped = false;
    bool started = false;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            if (!started) {
              started = true;
              speech.listen(
                onResult: (result) {
                  if (dialogPopped) return;
                  setDialogState(
                      () => transcript = result.recognizedWords);
                  if (result.finalResult) {
                    speech.stop();
                    dialogPopped = true;
                    Navigator.of(ctx).pop(transcript);
                  }
                },
                listenFor: const Duration(seconds: 10),
                pauseFor: const Duration(seconds: 3),
              );
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Listening...',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    transcript.isEmpty ? 'Say a food name' : transcript,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: transcript.isEmpty ? Colors.grey : null,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    dialogPopped = true;
                    speech.stop();
                    Navigator.of(ctx).pop(null);
                  },
                  child: const Text('Cancel'),
                ),
                if (transcript.isNotEmpty)
                  FilledButton(
                    onPressed: () {
                      dialogPopped = true;
                      speech.stop();
                      Navigator.of(ctx).pop(transcript);
                    },
                    child: const Text('Done'),
                  ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result.trim().isNotEmpty && mounted) {
      _searchCtrl.text = result.trim();
      _onSearchChanged(result.trim());
    }
  }

  /// Opens the manual create food form. If the user saves, the food is
  /// returned and can be immediately tracked.
  Future<void> _openCreateFoodScreen() async {
    final food = await Navigator.push<CommonFoodItem>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateFoodScreen(initialName: _query.trim()),
      ),
    );
    if (food != null && mounted) {
      _addFood(food);
    }
  }

  /// Auto-save an online-sourced food to local SQLite DB (fire-and-forget).
  void _autoSaveToLocalDb(CommonFoodItem food) {
    _foodDb.insertFood(food).catchError((_) {});
  }

  // ── Category expand/collapse ──────────────────────────────────────────────

  Future<void> _toggleCategory(String category) async {
    if (_expandedCategory == category) {
      setState(() {
        _expandedCategory = null;
        _expandedFoods = [];
      });
      return;
    }
    setState(() {
      _expandedCategory = category;
      _expandedFoods = [];
      _loadingCategory = true;
    });
    final foods = await _foodDb.getFoodsByCategory(category);
    if (!mounted) return;
    setState(() {
      _expandedFoods = foods;
      _loadingCategory = false;
    });
  }

  // ── Add food ──────────────────────────────────────────────────────────────

  void _addFood(CommonFoodItem food) {
    _showQuantityMeasurePicker(food);
  }

  static const _quantityValues = [
    0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0,
    2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
  ];

  static const _measures = [
    _FoodMeasure('Serving', null),
    _FoodMeasure('Katori', 150),
    _FoodMeasure('Bowl', 300),
    _FoodMeasure('Small Bowl', 150),
    _FoodMeasure('Cup', 240),
    _FoodMeasure('Glass', 250),
    _FoodMeasure('Plate', 200),
    _FoodMeasure('Tablespoon', 15),
    _FoodMeasure('Teaspoon', 5),
    _FoodMeasure('Piece', null),
    _FoodMeasure('Grams', 1),
  ];

  double? _parseServingGrams(String servingSize) {
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*(?:g|ml)\b')
        .firstMatch(servingSize.toLowerCase());
    if (match != null) return double.tryParse(match.group(1)!);
    return null;
  }

  void _showQuantityMeasurePicker(CommonFoodItem food) {
    double quantity = 1.0;
    _FoodMeasure selectedMeasure = _measures.first;
    final servingGrams = _parseServingGrams(food.servingSize);

    final availableMeasures = servingGrams != null
        ? _measures
        : _measures.where((m) => m.name == 'Serving').toList();

    double calcMultiplier() {
      if (selectedMeasure.name == 'Serving' ||
          selectedMeasure.name == 'Piece' ||
          servingGrams == null ||
          selectedMeasure.grams == null) {
        return quantity;
      }
      return quantity * selectedMeasure.grams! / servingGrams;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final multiplier = calcMultiplier();
          final totalCal = (food.calories * multiplier).round();
          final totalP = (food.protein * multiplier);
          final totalC = (food.carbs * multiplier);
          final totalF = (food.fat * multiplier);
          final theme = Theme.of(context);

          return AlertDialog(
            title: Text(food.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  food.servingSize,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _PickerButton(
                        label: 'Quantity',
                        value: quantity % 1 == 0
                            ? '${quantity.toInt()}'
                            : '$quantity',
                        onTap: () {
                          showDialog(
                            context: ctx,
                            builder: (_) => _SearchableListDialog<double>(
                              title: 'Quantity',
                              items: _quantityValues,
                              selectedItem: quantity,
                              labelBuilder: (v) => v % 1 == 0
                                  ? '${v.toInt()}'
                                  : v.toStringAsFixed(2),
                              onSelected: (v) {
                                setDialogState(() => quantity = v);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerButton(
                        label: 'Measure',
                        value: selectedMeasure.name,
                        onTap: () {
                          showDialog(
                            context: ctx,
                            builder: (_) =>
                                _SearchableListDialog<_FoodMeasure>(
                              title: 'Measure',
                              items: availableMeasures,
                              selectedItem: selectedMeasure,
                              labelBuilder: (m) => m.name,
                              subtitleBuilder: (m) =>
                                  m.grams != null ? '${m.grams}g' : '',
                              onSelected: (m) {
                                setDialogState(() => selectedMeasure = m);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MiniMacroChip(
                        label: 'P',
                        value: '${totalP.round()}g',
                        color: Colors.blue),
                    _MiniMacroChip(
                        label: 'C',
                        value: '${totalC.round()}g',
                        color: Colors.orange),
                    _MiniMacroChip(
                        label: 'F',
                        value: '${totalF.round()}g',
                        color: Colors.red),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$totalCal kcal',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final perUnitMultiplier =
                      (selectedMeasure.name == 'Serving' ||
                              selectedMeasure.name == 'Piece' ||
                              servingGrams == null ||
                              selectedMeasure.grams == null)
                          ? 1.0
                          : selectedMeasure.grams! / servingGrams;

                  final tracked = TrackedFoodModel(
                    id: const Uuid().v4(),
                    name: food.name,
                    servingSize: food.servingSize,
                    calories: food.calories * perUnitMultiplier,
                    protein: food.protein * perUnitMultiplier,
                    carbs: food.carbs * perUnitMultiplier,
                    fat: food.fat * perUnitMultiplier,
                    fiber: food.fiber * perUnitMultiplier,
                    sodium: food.sodium * perUnitMultiplier,
                    sugar: food.sugar * perUnitMultiplier,
                    cholesterol: food.cholesterol * perUnitMultiplier,
                    iron: food.iron * perUnitMultiplier,
                    calcium: food.calcium * perUnitMultiplier,
                    potassium: food.potassium * perUnitMultiplier,
                    vitaminA: food.vitaminA * perUnitMultiplier,
                    vitaminB12: food.vitaminB12 * perUnitMultiplier,
                    vitaminC: food.vitaminC * perUnitMultiplier,
                    vitaminD: food.vitaminD * perUnitMultiplier,
                    zinc: food.zinc * perUnitMultiplier,
                    magnesium: food.magnesium * perUnitMultiplier,
                    vitaminE: food.vitaminE * perUnitMultiplier,
                    vitaminK: food.vitaminK * perUnitMultiplier,
                    vitaminB6: food.vitaminB6 * perUnitMultiplier,
                    folate: food.folate * perUnitMultiplier,
                    phosphorus: food.phosphorus * perUnitMultiplier,
                    selenium: food.selenium * perUnitMultiplier,
                    manganese: food.manganese * perUnitMultiplier,
                    mealType: widget.mealType,
                    quantity: quantity,
                    measure: selectedMeasure.name,
                  );
                  final cubit = context.read<GymCubit>();
                  final messenger = ScaffoldMessenger.of(context);
                  final mealLabel = widget.mealType.label;
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  await cubit.saveTrackedFood(tracked);
                  _autoSaveToLocalDb(food);
                  messenger.showSnackBar(
                    SnackBar(
                        content:
                            Text('${food.name} added to $mealLabel')),
                  );
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSearching = _query.trim().length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add to ${widget.mealType.label}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search food (e.g. "rice", "paneer tikka")...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.mic),
                      tooltip: 'Voice search',
                      onPressed: _voiceSearch,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_localSearching || _firebaseSearching)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(),
            ),
          Expanded(
            child: isSearching
                ? _buildSearchResults(theme)
                : _buildCategoryBrowser(theme),
          ),
        ],
      ),
    );
  }

  // ── Browse mode ───────────────────────────────────────────────────────────

  Widget _buildCategoryBrowser(ThemeData theme) {
    if (_categoryCounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final categories = _categoryCounts.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final count = _categoryCounts[cat] ?? 0;
        final isExpanded = _expandedCategory == cat;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                cat,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count items',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              onTap: () => _toggleCategory(cat),
            ),
            if (isExpanded)
              _loadingCategory
                  ? const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  : Column(
                      children: _expandedFoods
                          .map((food) => _buildFoodTile(food, theme))
                          .toList(),
                    ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  // ── Search mode ───────────────────────────────────────────────────────────

  Widget _buildSearchResults(ThemeData theme) {
    // Build groups: local results grouped by category, then firebase, then USDA
    final groups = <MapEntry<String, List<CommonFoodItem>>>[];

    if (_localResults.isNotEmpty) {
      final map = <String, List<CommonFoodItem>>{};
      for (final f in _localResults) {
        final cat = f.category.isEmpty ? 'Other' : f.category;
        map.putIfAbsent(cat, () => []).add(f);
      }
      groups.addAll(map.entries);
    }
    if (_firebaseResults.isNotEmpty) {
      groups.add(MapEntry('Cloud Results', _firebaseResults));
    }
    if (_usdaResults.isNotEmpty) {
      groups.add(MapEntry('USDA Database', _usdaResults));
    }
    if (_geminiResults.isNotEmpty) {
      groups.add(MapEntry('AI Results', _geminiResults));
    }

    final bool localDone = !_localSearching && !_firebaseSearching;
    final bool hasLocalResults =
        _localResults.isNotEmpty || _firebaseResults.isNotEmpty;

    // Count total items for ListView
    final totalItems =
        groups.fold<int>(0, (sum, g) => sum + 1 + g.value.length);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      // +1 for the "search online" / "no results" widget at the end
      itemCount: totalItems + (localDone ? 1 : 0),
      itemBuilder: (context, index) {
        // Food list items
        if (index < totalItems) {
          int i = 0;
          for (final group in groups) {
            if (index == i) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  group.key,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }
            i++;
            if (index < i + group.value.length) {
              final food = group.value[index - i];
              return _buildFoodTile(food, theme);
            }
            i += group.value.length;
          }
          return const SizedBox.shrink();
        }

        // Bottom widget: "search online" button or "not found"
        return _buildSearchOnlineSection(theme, hasLocalResults);
      },
    );
  }

  Widget _buildSearchOnlineSection(ThemeData theme, bool hasLocalResults) {
    // USDA search in progress
    if (_usdaSearching) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Gemini search in progress
    if (_geminiSearching) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Searching with AI...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    // USDA has been searched — show fallback options (Gemini + Manual)
    if (_usdaSearched) {
      // If Gemini already searched and returned results, just show manual add
      if (_geminiSearched && _geminiResults.isNotEmpty) {
        return _buildManualAddButton(theme);
      }

      // If Gemini searched but got nothing, show "not found" + manual add
      if (_geminiSearched && _geminiResults.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              if (_usdaResults.isEmpty && !hasLocalResults) ...[
                Icon(Icons.search_off,
                    size: 48,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'No foods found for "$_query"',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildManualAddButtonInner(theme),
            ],
          ),
        );
      }

      // USDA searched, Gemini not yet — show both buttons
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            if (_usdaResults.isEmpty && !hasLocalResults) ...[
              const SizedBox(height: 8),
              Text(
                'No USDA results found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _searchGemini,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Search with AI'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
            const SizedBox(height: 8),
            _buildManualAddButtonInner(theme),
          ],
        ),
      );
    }

    // Not yet searched USDA – show the button
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          if (!hasLocalResults) ...[
            const SizedBox(height: 16),
            Icon(Icons.search_off,
                size: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              'Not found in local database',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _searchUsda,
            icon: const Icon(Icons.language),
            label: Text(hasLocalResults
                ? "Can't find it? Search online (USDA)"
                : 'Search online (USDA Database)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualAddButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: _buildManualAddButtonInner(theme),
    );
  }

  Widget _buildManualAddButtonInner(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _openCreateFoodScreen,
      icon: const Icon(Icons.add),
      label: const Text('Add Food Manually'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
      ),
    );
  }

  Widget _buildFoodTile(CommonFoodItem food, ThemeData theme) {
    return ListTile(
      dense: true,
      title: Text(food.name),
      subtitle: Text(
        '${food.servingSize}  \u00b7  ${food.calories.round()} kcal  \u00b7  P: ${food.protein.round()}g  C: ${food.carbs.round()}g  F: ${food.fat.round()}g',
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
        onPressed: () => _addFood(food),
      ),
      onTap: () => _addFood(food),
    );
  }
}

// ─── Helper classes ──────────────────────────────────────────────────────────

class _FoodMeasure {
  const _FoodMeasure(this.name, this.grams);
  final String name;
  final double? grams;
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.arrow_drop_down,
                    size: 20, color: theme.colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMacroChip extends StatelessWidget {
  const _MiniMacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Searchable List Dialog (HealthifyMe-style picker) ───────────────────────

class _SearchableListDialog<T> extends StatefulWidget {
  const _SearchableListDialog({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.labelBuilder,
    required this.onSelected,
    this.subtitleBuilder,
  });

  final String title;
  final List<T> items;
  final T selectedItem;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final ValueChanged<T> onSelected;

  @override
  State<_SearchableListDialog<T>> createState() =>
      _SearchableListDialogState<T>();
}

class _SearchableListDialogState<T>
    extends State<_SearchableListDialog<T>> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) {
      final label = widget.labelBuilder(item).toLowerCase();
      final sub = widget.subtitleBuilder?.call(item).toLowerCase() ?? '';
      return label.contains(q) || sub.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420, maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Flexible(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No results found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final isSelected = item == widget.selectedItem;

                        return ListTile(
                          selected: isSelected,
                          title: Text(widget.labelBuilder(item)),
                          subtitle: widget.subtitleBuilder != null &&
                                  widget.subtitleBuilder!(item).isNotEmpty
                              ? Text(widget.subtitleBuilder!(item))
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check,
                                  color: theme.colorScheme.primary)
                              : null,
                          onTap: () {
                            widget.onSelected(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
