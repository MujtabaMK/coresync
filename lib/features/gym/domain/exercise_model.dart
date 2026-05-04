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

class CommonMistake {
  final String title;
  final String description;
  const CommonMistake({required this.title, required this.description});
}

class ExerciseModel {
  final String id;
  final String name;
  final String? lottieAsset;
  final String? videoAsset;
  final String? networkImageUrl;
  final String category;
  final ExerciseDifficulty difficulty;
  final List<String> muscleGroups;
  final List<String> instructions;
  final String description;
  final List<CommonMistake> commonMistakes;
  final List<String> breathingTips;
  final int defaultReps;
  final int defaultDurationSecs;
  final bool isTimeBased;

  const ExerciseModel({
    required this.id,
    required this.name,
    this.lottieAsset,
    this.videoAsset,
    this.networkImageUrl,
    required this.category,
    required this.difficulty,
    this.muscleGroups = const [],
    this.instructions = const [],
    this.description = '',
    this.commonMistakes = const [],
    this.breathingTips = const [],
    this.defaultReps = 12,
    this.defaultDurationSecs = 30,
    this.isTimeBased = false,
  });
}
