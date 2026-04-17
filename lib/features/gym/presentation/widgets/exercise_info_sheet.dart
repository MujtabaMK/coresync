import 'package:flutter/material.dart';

import '../../domain/exercise_model.dart';
import '../../domain/workout_program_model.dart';
import 'body_muscle_diagram.dart';
import 'exercise_animation.dart';
import 'exercise_video_player.dart';

/// Shows the redesigned exercise info sheet with navigation.
///
/// [exercises] is the full list of resolved exercises in the workout.
/// [workoutExercises] is the corresponding WorkoutExercise list (for reps/duration overrides).
/// [initialIndex] is the tapped exercise's index.
void showExerciseInfoSheet(
  BuildContext context,
  ExerciseModel exercise, {
  List<ExerciseModel>? exercises,
  List<WorkoutExercise>? workoutExercises,
  int initialIndex = 0,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ExerciseInfoSheet(
      exercises: exercises ?? [exercise],
      workoutExercises: workoutExercises,
      initialIndex: exercises != null ? initialIndex : 0,
    ),
  );
}

class _ExerciseInfoSheet extends StatefulWidget {
  final List<ExerciseModel> exercises;
  final List<WorkoutExercise>? workoutExercises;
  final int initialIndex;

  const _ExerciseInfoSheet({
    required this.exercises,
    required this.workoutExercises,
    required this.initialIndex,
  });

  @override
  State<_ExerciseInfoSheet> createState() => _ExerciseInfoSheetState();
}

class _ExerciseInfoSheetState extends State<_ExerciseInfoSheet> {
  late int _currentIndex;
  late Map<int, int> _repsOverrides;

  ExerciseModel get _exercise => widget.exercises[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _repsOverrides = {};
  }

  int _getReps() {
    if (_repsOverrides.containsKey(_currentIndex)) {
      return _repsOverrides[_currentIndex]!;
    }
    final we = widget.workoutExercises;
    if (we != null && _currentIndex < we.length) {
      return we[_currentIndex].reps ?? _exercise.defaultReps;
    }
    return _exercise.defaultReps;
  }

  int _getDurationSecs() {
    final we = widget.workoutExercises;
    if (we != null && _currentIndex < we.length) {
      return we[_currentIndex].durationSecs ?? _exercise.defaultDurationSecs;
    }
    return _exercise.defaultDurationSecs;
  }

  String _formatDuration(int secs) {
    final mins = secs ~/ 60;
    final rem = secs % 60;
    return '${mins.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  void _changeReps(int delta) {
    final current = _getReps();
    final next = (current + delta).clamp(1, 999);
    setState(() => _repsOverrides[_currentIndex] = next);
  }

  void _goTo(int index) {
    if (index >= 0 && index < widget.exercises.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = _exercise;
    final hasNav = widget.exercises.length > 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  exercise.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              // Tabs
              const TabBar(
                tabs: [
                  Tab(text: 'Animation'),
                  Tab(text: 'Muscle'),
                  Tab(text: 'How to do'),
                ],
              ),
              // Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAnimationTab(theme, exercise, scrollController),
                    _buildMuscleTab(theme, exercise, scrollController),
                    _buildHowToTab(theme, exercise, scrollController),
                  ],
                ),
              ),
              // Bottom bar
              if (hasNav) _buildBottomBar(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimationTab(
    ThemeData theme,
    ExerciseModel exercise,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Animation
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: _buildLottieOrIcon(theme, exercise),
          ),
        ),
        const SizedBox(height: 16),
        // Reps / Duration section
        _buildRepsSection(theme, exercise),
        const SizedBox(height: 16),
        // Instructions
        if (exercise.description.isNotEmpty) ...[
          _sectionHeader(theme, 'INSTRUCTIONS'),
          const SizedBox(height: 8),
          Text(
            exercise.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        // Focus Area
        _sectionHeader(theme, 'FOCUS AREA'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text(exercise.category),
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMuscleTab(
    ThemeData theme,
    ExerciseModel exercise,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (exercise.muscleGroups.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No muscle data available.'),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          BodyMuscleDiagram(
            muscleGroups: exercise.muscleGroups,
            highlightColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 20),
          _sectionHeader(theme, 'TARGET MUSCLES'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: exercise.muscleGroups.map((muscle) {
              return Chip(
                avatar: Icon(
                  Icons.circle,
                  size: 10,
                  color: theme.colorScheme.primary,
                ),
                label: Text(muscle),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _sectionHeader(theme, 'DIFFICULTY'),
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
      ],
    );
  }

  Widget _buildHowToTab(
    ThemeData theme,
    ExerciseModel exercise,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Step-by-step instructions
        if (exercise.instructions.isNotEmpty) ...[
          _sectionHeader(theme, 'STEPS'),
          const SizedBox(height: 8),
          ...exercise.instructions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onPrimary,
                      ),
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
        // Common Mistakes
        if (exercise.commonMistakes.isNotEmpty) ...[
          _sectionHeader(theme, 'COMMON MISTAKES', color: Colors.red),
          const SizedBox(height: 8),
          ...exercise.commonMistakes.asMap().entries.map((entry) {
            final mistake = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red.withAlpha(30),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mistake.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mistake.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        // Breathing Tips
        if (exercise.breathingTips.isNotEmpty) ...[
          _sectionHeader(theme, 'BREATHING TIPS', color: Colors.blue),
          const SizedBox(height: 8),
          ...exercise.breathingTips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.air, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildRepsSection(ThemeData theme, ExerciseModel exercise) {
    final isTime = exercise.isTimeBased;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            isTime ? 'DURATION' : 'REPS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (isTime)
            Text(
              _formatDuration(_getDurationSecs()),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: () => _changeReps(-1),
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  '${_getReps()}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 24),
                IconButton.filled(
                  onPressed: () => _changeReps(1),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _currentIndex > 0
                  ? () => _goTo(_currentIndex - 1)
                  : null,
              icon: const Icon(Icons.skip_previous_rounded),
              tooltip: 'Previous',
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${widget.exercises.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _currentIndex < widget.exercises.length - 1
                  ? () => _goTo(_currentIndex + 1)
                  : null,
              icon: const Icon(Icons.skip_next_rounded),
              tooltip: 'Next',
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String text, {Color? color}) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: color ?? theme.colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  static Widget _buildLottieOrIcon(ThemeData theme, ExerciseModel exercise) {
    if (exercise.videoAsset != null) {
      return ExerciseVideoPlayer(
        assetPath: exercise.videoAsset!,
        height: 200,
        fit: BoxFit.contain,
      );
    }
    return ExerciseAnimation(
      exercise: exercise,
      fit: BoxFit.contain,
    );
  }

}
