import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../domain/exercise_model.dart';

/// Displays the best available animation for an exercise.
///
/// Priority: Lottie asset → category icon.
class ExerciseAnimation extends StatelessWidget {
  const ExerciseAnimation({
    super.key,
    required this.exercise,
    this.fit = BoxFit.contain,
    this.animate = true,
    this.showPlaceholder = true,
  });

  final ExerciseModel exercise;
  final BoxFit fit;
  final bool animate;
  final bool showPlaceholder;

  @override
  Widget build(BuildContext context) {
    if (exercise.lottieAsset != null) {
      return Lottie.asset(
        exercise.lottieAsset!,
        fit: fit,
        repeat: true,
        animate: animate,
      );
    }
    if (exercise.networkImageUrl != null) {
      return Image.network(
        exercise.networkImageUrl!,
        fit: fit,
        errorBuilder: (_, __, ___) => Icon(
          _categoryIcon(exercise.category),
          size: 40,
          color: Colors.grey,
        ),
      );
    }
    return Icon(
      _categoryIcon(exercise.category),
      size: 40,
      color: Colors.grey,
    );
  }

  static IconData _categoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'abs' || 'core' => Icons.fitness_center,
      'arm' || 'arms' => Icons.sports_martial_arts,
      'chest' => Icons.expand,
      'leg' || 'legs' => Icons.directions_walk,
      'shoulder' || 'shoulders' => Icons.accessibility_new,
      'back' => Icons.airline_seat_flat,
      _ => Icons.fitness_center,
    };
  }
}
