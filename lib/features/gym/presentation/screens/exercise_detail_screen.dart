import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../domain/exercise_model.dart';

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
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Lottie.asset(
                    exercise.lottieAsset,
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
              ),
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
