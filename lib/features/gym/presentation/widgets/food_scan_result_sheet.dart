import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/food_scan_model.dart';

class FoodScanResultSheet extends StatefulWidget {
  const FoodScanResultSheet({
    super.key,
    required this.foodItems,
    required this.onSave,
    required this.onRetake,
  });

  final List<FoodItem> foodItems;
  final void Function(FoodScanModel scan) onSave;
  final VoidCallback onRetake;

  @override
  State<FoodScanResultSheet> createState() => _FoodScanResultSheetState();
}

class _FoodScanResultSheetState extends State<FoodScanResultSheet> {
  late List<FoodItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.foodItems);
  }

  double get _totalCalories =>
      _items.fold(0, (sum, item) => sum + item.calories * item.quantity);

  double get _totalProtein =>
      _items.fold(0, (sum, item) => sum + item.protein * item.quantity);

  double get _totalCarbs =>
      _items.fold(0, (sum, item) => sum + item.carbs * item.quantity);

  double get _totalFat =>
      _items.fold(0, (sum, item) => sum + item.fat * item.quantity);

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;
    setState(() {
      _items[index] = _items[index].copyWith(quantity: newQuantity);
    });
  }

  void _save() {
    final scan = FoodScanModel(
      id: const Uuid().v4(),
      foodItems: _items,
      totalCalories: _totalCalories,
    );
    widget.onSave(scan);
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
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Scan Results',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Text(
                          'No food items detected',
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Text(
                                        '${(item.calories * item.quantity).round()} kcal',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _removeItem(index),
                                        child: Icon(Icons.close,
                                            size: 20,
                                            color: theme.colorScheme.error),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _MacroChip(
                                          label: 'P',
                                          value:
                                              '${(item.protein * item.quantity).toStringAsFixed(1)}g',
                                          color: Colors.blue),
                                      const SizedBox(width: 8),
                                      _MacroChip(
                                          label: 'C',
                                          value:
                                              '${(item.carbs * item.quantity).toStringAsFixed(1)}g',
                                          color: Colors.orange),
                                      const SizedBox(width: 8),
                                      _MacroChip(
                                          label: 'F',
                                          value:
                                              '${(item.fat * item.quantity).toStringAsFixed(1)}g',
                                          color: Colors.red),
                                      const Spacer(),
                                      // Quantity controls
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline,
                                            size: 20),
                                        onPressed: () => _updateQuantity(
                                            index, item.quantity - 1),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      Text('${item.quantity}',
                                          style: theme.textTheme.bodyMedium),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline,
                                            size: 20),
                                        onPressed: () => _updateQuantity(
                                            index, item.quantity + 1),
                                        visualDensity: VisualDensity.compact,
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
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2)),
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
                            onPressed: widget.onRetake,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Retake'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _items.isEmpty ? null : _save,
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
