import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../domain/exercise_model.dart';

void showExerciseInfoSheet(BuildContext context, ExerciseModel exercise) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ExerciseInfoSheet(exercise: exercise),
  );
}

class _ExerciseInfoSheet extends StatelessWidget {
  final ExerciseModel exercise;

  const _ExerciseInfoSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Animation'),
                  Tab(text: 'Muscles'),
                  Tab(text: 'How To'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _AnimationTab(exercise: exercise),
                    _MuscleTab(exercise: exercise),
                    _HowToTab(
                      exercise: exercise,
                      scrollController: scrollController,
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

class _AnimationTab extends StatelessWidget {
  final ExerciseModel exercise;
  const _AnimationTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        exercise.lottieAsset,
        width: double.infinity,
        height: 300,
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}

class _MuscleTab extends StatelessWidget {
  final ExerciseModel exercise;
  const _MuscleTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (exercise.muscleGroups.isEmpty) {
      return const Center(child: Text('No muscle data available.'));
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Muscles',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: exercise.muscleGroups.map((muscle) {
              return Chip(
                avatar: const Icon(Icons.circle, size: 12),
                label: Text(muscle),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Difficulty',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(exercise.difficulty.label),
            backgroundColor: switch (exercise.difficulty) {
              ExerciseDifficulty.beginner => Colors.green.withAlpha(30),
              ExerciseDifficulty.intermediate => Colors.orange.withAlpha(30),
              ExerciseDifficulty.advanced => Colors.red.withAlpha(30),
            },
          ),
        ],
      ),
    );
  }
}

class _HowToTab extends StatelessWidget {
  final ExerciseModel exercise;
  final ScrollController scrollController;
  const _HowToTab({required this.exercise, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        if (exercise.instructions.isNotEmpty) ...[
          Text(
            'Instructions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...exercise.instructions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(entry.value),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (exercise.commonMistakes.isNotEmpty) ...[
          Text(
            'Common Mistakes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          ...exercise.commonMistakes.map((mistake) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.close, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(mistake)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (exercise.breathingTip.isNotEmpty) ...[
          Text(
            'Breathing',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.air, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text(exercise.breathingTip)),
            ],
          ),
        ],
      ],
    );
  }
}
