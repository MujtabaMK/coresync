import 'package:flutter/material.dart';

import '../../domain/tracked_food_model.dart';

class MealSelectionSheet extends StatelessWidget {
  const MealSelectionSheet({
    super.key,
    required this.dailyTarget,
    required this.caloriesForMeal,
    required this.onMealSelected,
  });

  final double dailyTarget;
  final double Function(MealType) caloriesForMeal;
  final ValueChanged<MealType> onMealSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add Food To',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...MealType.values.map((meal) {
              final target = (dailyTarget * meal.calorieShare).round();
              final consumed = caloriesForMeal(meal).round();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primaryContainer,
                  child: Icon(_iconForMeal(meal),
                      color: theme.colorScheme.onPrimaryContainer),
                ),
                title: Text(meal.label),
                subtitle: Text('$consumed / $target kcal'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  onMealSelected(meal);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _iconForMeal(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.morningSnack:
        return Icons.apple;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.eveningSnack:
        return Icons.cookie;
      case MealType.dinner:
        return Icons.dinner_dining;
    }
  }
}
