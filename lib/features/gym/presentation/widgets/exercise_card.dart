import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/exercise_model.dart';

class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;

  const ExerciseCard({super.key, required this.exercise});

  Color _difficultyColor(ExerciseDifficulty difficulty) {
    return switch (difficulty) {
      ExerciseDifficulty.beginner => Colors.green,
      ExerciseDifficulty.intermediate => Colors.orange,
      ExerciseDifficulty.advanced => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _difficultyColor(exercise.difficulty);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.fitness_center,
          color: theme.colorScheme.primary,
        ),
        title: Text(exercise.name),
        subtitle: Text(exercise.category),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            exercise.difficulty.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => context.push(
          '/gym/exercises/${exercise.category}/detail',
          extra: exercise,
        ),
      ),
    );
  }
}
