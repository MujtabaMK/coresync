import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../domain/exercise_model.dart';
import '../widgets/exercise_video_player.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final ExerciseModel exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  static IconData _categoryIcon(String category) {
    return switch (category) {
      'Abs' => Icons.sports_martial_arts,
      'Arm' => Icons.fitness_center,
      'Chest' => Icons.expand,
      'Leg' => Icons.directions_run,
      'Shoulder' => Icons.accessibility_new,
      'Back' => Icons.straighten,
      _ => Icons.fitness_center,
    };
  }

  Widget _buildLottieOrIcon(ThemeData theme, ExerciseModel exercise) {
    if (exercise.videoAsset != null) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          ExerciseVideoPlayer(
            assetPath: exercise.videoAsset!,
            height: 300,
            fit: BoxFit.contain,
            isPlaying: _isPlaying,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FloatingActionButton.small(
              onPressed: _togglePlayPause,
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
        ],
      );
    }
    if (exercise.lottieAsset != null) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Lottie.asset(
            exercise.lottieAsset!,
            controller: _controller,
            width: double.infinity,
            height: 300,
            fit: BoxFit.contain,
            onLoaded: (composition) {
              _controller
                ..duration = composition.duration
                ..repeat();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FloatingActionButton.small(
              onPressed: _togglePlayPause,
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      height: 300,
      child: Center(
        child: CircleAvatar(
          radius: 64,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _categoryIcon(exercise.category),
            size: 64,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

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
    final exercise = widget.exercise;

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: _buildLottieOrIcon(theme, exercise),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(
                        avatar: const Icon(Icons.fitness_center, size: 18),
                        label: Text(exercise.category),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        backgroundColor: _difficultyColor(exercise.difficulty)
                            .withAlpha(30),
                        side: BorderSide(
                          color: _difficultyColor(exercise.difficulty),
                        ),
                        label: Text(
                          exercise.difficulty.label,
                          style: TextStyle(
                            color: _difficultyColor(exercise.difficulty),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
