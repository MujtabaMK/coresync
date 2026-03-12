import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../data/exercise_data.dart';
import '../../domain/exercise_model.dart';
import '../../domain/workout_program_model.dart';
import '../widgets/exercise_info_sheet.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutProgram program;

  const WorkoutDetailScreen({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info cards row
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: '${program.estimatedDurationMins} min',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.fitness_center,
                        label: 'Exercises',
                        value: '${program.exercises.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Exercises',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...program.exercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final we = entry.value;
                  final exercise = ExerciseData.getById(we.exerciseId);
                  if (exercise == null) return const SizedBox.shrink();
                  return _ExerciseListTile(
                    index: index,
                    workoutExercise: we,
                    exercise: exercise,
                    onTap: () => showExerciseInfoSheet(context, exercise),
                  );
                }),
              ],
            ),
          ),
          // Start button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => context.push(
                    '/gym/exercises/workout/${program.id}/execute',
                  ),
                  child: const Text(
                    'START',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  final int index;
  final WorkoutExercise workoutExercise;
  final ExerciseModel exercise;
  final VoidCallback onTap;

  const _ExerciseListTile({
    required this.index,
    required this.workoutExercise,
    required this.exercise,
    required this.onTap,
  });

  String get _subtitle {
    if (exercise.isTimeBased || workoutExercise.durationSecs != null) {
      final secs =
          workoutExercise.durationSecs ?? exercise.defaultDurationSecs;
      final mins = secs ~/ 60;
      final remSecs = secs % 60;
      if (mins > 0) {
        return '${mins.toString().padLeft(2, '0')}:${remSecs.toString().padLeft(2, '0')}';
      }
      return '00:${remSecs.toString().padLeft(2, '0')}';
    }
    final reps = workoutExercise.reps ?? exercise.defaultReps;
    return 'x$reps';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Lottie.asset(
                  exercise.lottieAsset,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                _subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
