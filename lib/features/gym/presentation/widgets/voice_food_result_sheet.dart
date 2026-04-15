import 'package:flutter/material.dart';

import '../../data/common_foods_data.dart';
import '../../data/food_database_service.dart';

/// A matched food with a user-adjustable quantity.
class VoiceFoodEntry {
  VoiceFoodEntry({required this.food, this.quantity = 1});
  CommonFoodItem food;
  int quantity;
}

class VoiceFoodResultSheet extends StatefulWidget {
  const VoiceFoodResultSheet({
    super.key,
    required this.entries,
    required this.onSave,
    required this.onTryAgain,
  });

  final List<VoiceFoodEntry> entries;
  final void Function(List<VoiceFoodEntry> entries) onSave;
  final VoidCallback onTryAgain;

  @override
  State<VoiceFoodResultSheet> createState() => _VoiceFoodResultSheetState();
}

class _VoiceFoodResultSheetState extends State<VoiceFoodResultSheet> {
  late List<VoiceFoodEntry> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.entries);
  }

  double get _totalCalories =>
      _items.fold(0, (sum, e) => sum + e.food.calories * e.quantity);

  double get _totalProtein =>
      _items.fold(0, (sum, e) => sum + e.food.protein * e.quantity);

  double get _totalCarbs =>
      _items.fold(0, (sum, e) => sum + e.food.carbs * e.quantity);

  double get _totalFat =>
      _items.fold(0, (sum, e) => sum + e.food.fat * e.quantity);

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;
    setState(() => _items[index].quantity = newQuantity);
  }

  void _editItem(int index) async {
    final current = _items[index];
    final result = await showModalBottomSheet<CommonFoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _FoodSearchSheet(
        initialQuery: current.food.name,
        title: 'Swap Food',
      ),
    );
    if (result != null && mounted) {
      setState(() => _items[index].food = result);
    }
  }

  void _addMoreFood() async {
    final result = await showModalBottomSheet<CommonFoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const _FoodSearchSheet(
        initialQuery: '',
        title: 'Add Food',
      ),
    );
    if (result != null && mounted) {
      setState(() => _items.add(VoiceFoodEntry(food: result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.mic, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Voice Results',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _addMoreFood,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No food items matched',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              onPressed: _addMoreFood,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Food Manually'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final entry = _items[index];
                          final food = entry.food;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              food.name,
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              food.servingSize,
                                              style: theme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${(food.calories * entry.quantity).round()} kcal',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _MacroChip(
                                        label: 'P',
                                        value:
                                            '${(food.protein * entry.quantity).toStringAsFixed(1)}g',
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 6),
                                      _MacroChip(
                                        label: 'C',
                                        value:
                                            '${(food.carbs * entry.quantity).toStringAsFixed(1)}g',
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      _MacroChip(
                                        label: 'F',
                                        value:
                                            '${(food.fat * entry.quantity).toStringAsFixed(1)}g',
                                        color: Colors.red,
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20),
                                        onPressed: () => _updateQuantity(
                                            index, entry.quantity - 1),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text('${entry.quantity}',
                                            style:
                                                theme.textTheme.titleMedium),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 20),
                                        onPressed: () => _updateQuantity(
                                            index, entry.quantity + 1),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _editItem(index),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.swap_horiz,
                                                  size: 16,
                                                  color: theme
                                                      .colorScheme.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Swap',
                                                style: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () => _removeItem(index),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.delete_outline,
                                                  size: 16,
                                                  color: theme
                                                      .colorScheme.error),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Remove',
                                                style: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Total summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${_totalCalories.round()} kcal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                            'Protein: ${_totalProtein.toStringAsFixed(1)}g',
                            style: theme.textTheme.bodySmall),
                        Text('Carbs: ${_totalCarbs.toStringAsFixed(1)}g',
                            style: theme.textTheme.bodySmall),
                        Text('Fat: ${_totalFat.toStringAsFixed(1)}g',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onTryAgain,
                            icon: const Icon(Icons.mic),
                            label: const Text('Try Again'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _items.isEmpty
                                ? null
                                : () => widget.onSave(_items),
                            icon: const Icon(Icons.check),
                            label: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Reusable search sheet for swapping or adding food from local DB.
class _FoodSearchSheet extends StatefulWidget {
  const _FoodSearchSheet({
    required this.initialQuery,
    required this.title,
  });
  final String initialQuery;
  final String title;

  @override
  State<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<_FoodSearchSheet> {
  final _ctrl = TextEditingController();
  List<CommonFoodItem> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _search(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results =
        await FoodDatabaseService.instance.searchByName(query, limit: 20);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(widget.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search foods...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _ctrl.clear();
                                _search('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    onChanged: _search,
                  ),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                else
                  Expanded(
                    child: _results.isEmpty
                        ? Center(
                            child: Text(
                              _ctrl.text.isEmpty
                                  ? 'Type to search foods'
                                  : 'No results found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            itemCount: _results.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final food = _results[index];
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        vertical: 4),
                                title: Text(
                                  food.name,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(
                                          fontWeight: FontWeight.w500),
                                ),
                                subtitle: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${food.calories.round()} kcal',
                                        style: theme
                                            .textTheme.bodySmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme
                                              .colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'P: ${food.protein.toStringAsFixed(1)}g',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue
                                                .withValues(
                                                    alpha: 0.8)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'C: ${food.carbs.toStringAsFixed(1)}g',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange
                                                .withValues(
                                                    alpha: 0.8)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'F: ${food.fat.toStringAsFixed(1)}g',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red
                                                .withValues(
                                                    alpha: 0.8)),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Text(
                                  food.servingSize,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                onTap: () =>
                                    Navigator.pop(context, food),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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
