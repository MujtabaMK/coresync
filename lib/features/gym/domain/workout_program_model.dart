import 'exercise_model.dart';

class WorkoutExercise {
  final String exerciseId;
  final int? reps;
  final int? durationSecs;

  const WorkoutExercise({
    required this.exerciseId,
    this.reps,
    this.durationSecs,
  });
}

class WorkoutProgram {
  final String id;
  final String name;
  final String bodyFocus;
  final ExerciseDifficulty difficulty;
  final int estimatedDurationMins;
  final List<WorkoutExercise> exercises;

  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.bodyFocus,
    required this.difficulty,
    required this.estimatedDurationMins,
    required this.exercises,
  });
}
