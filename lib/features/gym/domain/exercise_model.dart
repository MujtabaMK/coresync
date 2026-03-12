enum ExerciseDifficulty {
  beginner,
  intermediate,
  advanced;

  String get label {
    return switch (this) {
      ExerciseDifficulty.beginner => 'Beginner',
      ExerciseDifficulty.intermediate => 'Intermediate',
      ExerciseDifficulty.advanced => 'Advanced',
    };
  }
}

class ExerciseModel {
  final String id;
  final String name;
  final String lottieAsset;
  final String category;
  final ExerciseDifficulty difficulty;
  final List<String> muscleGroups;
  final List<String> instructions;
  final List<String> commonMistakes;
  final String breathingTip;
  final int defaultReps;
  final int defaultDurationSecs;
  final bool isTimeBased;

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.lottieAsset,
    required this.category,
    required this.difficulty,
    this.muscleGroups = const [],
    this.instructions = const [],
    this.commonMistakes = const [],
    this.breathingTip = '',
    this.defaultReps = 12,
    this.defaultDurationSecs = 30,
    this.isTimeBased = false,
  });
}
