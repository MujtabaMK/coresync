import 'package:flutter/material.dart';

import '../../domain/exercise_model.dart';
import '../../domain/workout_program_model.dart';

class WorkoutProgramCard extends StatelessWidget {
  final WorkoutProgram program;
  final VoidCallback onTap;

  const WorkoutProgramCard({
    super.key,
    required this.program,
    required this.onTap,
  });

  int get _difficultyLevel => switch (program.difficulty) {
        ExerciseDifficulty.beginner => 1,
        ExerciseDifficulty.intermediate => 2,
        ExerciseDifficulty.advanced => 3,
      };

  Color get _difficultyColor => switch (program.difficulty) {
        ExerciseDifficulty.beginner => Colors.green,
        ExerciseDifficulty.intermediate => Colors.orange,
        ExerciseDifficulty.advanced => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${program.estimatedDurationMins} min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.fitness_center,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${program.exercises.length} exercises',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Icon(
                    Icons.bolt,
                    size: 20,
                    color: i < _difficultyLevel
                        ? _difficultyColor
                        : theme.colorScheme.outlineVariant,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
