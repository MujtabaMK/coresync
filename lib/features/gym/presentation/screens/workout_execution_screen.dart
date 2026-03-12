import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../domain/workout_program_model.dart';
import '../providers/workout_provider.dart';

class WorkoutExecutionScreen extends StatelessWidget {
  final WorkoutProgram program;

  const WorkoutExecutionScreen({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorkoutCubit(program)..start(),
      child: const _WorkoutExecutionBody(),
    );
  }
}

class _WorkoutExecutionBody extends StatelessWidget {
  const _WorkoutExecutionBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutCubit, WorkoutState>(
      listener: (context, state) {
        if (state.status == WorkoutStatus.completed) {
          _showCompletionDialog(context);
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _showQuitDialog(context);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(state.program.name),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _showQuitDialog(context),
              ),
            ),
            body: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(WorkoutState state) {
    switch (state.status) {
      case WorkoutStatus.idle:
        return const Center(child: CircularProgressIndicator());
      case WorkoutStatus.exercising:
        return _ExerciseView(state: state);
      case WorkoutStatus.paused:
        if (state.statusBeforePause == WorkoutStatus.exercising) {
          return _ExerciseView(state: state);
        }
        return _RestView(state: state);
      case WorkoutStatus.resting:
        return _RestView(state: state);
      case WorkoutStatus.completed:
        return const SizedBox.shrink();
    }
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Workout?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.emoji_events,
          size: 48,
          color: Colors.amber,
        ),
        title: const Text('Workout Complete!'),
        content: const Text('Great job! You finished the entire workout.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseView extends StatelessWidget {
  final WorkoutState state;
  const _ExerciseView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = state.currentExercise;
    if (exercise == null) return const SizedBox.shrink();
    final cubit = context.read<WorkoutCubit>();
    final isPaused = state.status == WorkoutStatus.paused;
    final progress =
        (state.currentIndex + 1) / state.totalExercises;

    return SafeArea(
      child: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Exercise ${state.currentIndex + 1} of ${state.totalExercises}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Lottie.asset(
              exercise.lottieAsset,
              fit: BoxFit.contain,
              repeat: true,
              animate: !isPaused,
            ),
          ),
          Text(
            exercise.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (state.isTimeBased) ...[
            Text(
              _formatTime(state.timeRemaining),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ] else ...[
            Text(
              'x${state.displayReps}',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: cubit.markRepsDone,
              child: const Text('Done'),
            ),
          ],
          const SizedBox(height: 24),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton.filled(
                onPressed:
                    state.currentIndex > 0 ? cubit.goToPrevious : null,
                icon: const Icon(Icons.skip_previous),
                iconSize: 32,
              ),
              IconButton.filled(
                onPressed: cubit.togglePause,
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                iconSize: 48,
                style: IconButton.styleFrom(
                  minimumSize: const Size(72, 72),
                ),
              ),
              IconButton.filled(
                onPressed: cubit.skipToNext,
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _RestView extends StatelessWidget {
  final WorkoutState state;
  const _RestView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<WorkoutCubit>();
    final nextExercise = state.nextExercise;
    final isPaused = state.status == WorkoutStatus.paused;

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'REST',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatTime(state.timeRemaining),
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: cubit.togglePause,
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                  iconSize: 32,
                ),
                const SizedBox(width: 16),
                FilledButton.tonal(
                  onPressed: cubit.skipRest,
                  child: const Text('Skip Rest'),
                ),
              ],
            ),
            if (nextExercise != null) ...[
              const SizedBox(height: 32),
              Text(
                'Next up',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nextExercise.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
