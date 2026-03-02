import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/exercise_data.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  static const Map<String, IconData> _categoryIcons = {
    'Chest': Icons.expand,
    'Back': Icons.airline_seat_flat,
    'Shoulders': Icons.accessibility_new,
    'Arms': Icons.sports_martial_arts,
    'Legs': Icons.directions_walk,
    'Core': Icons.circle_outlined,
    'Cardio': Icons.directions_run,
  };

  static const Map<String, Color> _categoryColors = {
    'Chest': Colors.red,
    'Back': Colors.blue,
    'Shoulders': Colors.purple,
    'Arms': Colors.orange,
    'Legs': Colors.green,
    'Core': Colors.teal,
    'Cardio': Colors.pink,
  };

  @override
  Widget build(BuildContext context) {
    final categories = ExerciseData.categories;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final icon = _categoryIcons[category] ?? Icons.fitness_center;
            final color = _categoryColors[category] ?? theme.colorScheme.primary;

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.go('/gym/exercises/$category'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 40, color: color),
                      const SizedBox(height: 12),
                      Text(
                        category,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ExerciseData.getByCategory(category).length} exercises',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
