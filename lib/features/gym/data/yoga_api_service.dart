import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/exercise_model.dart';
import '../domain/workout_program_model.dart';
import '../domain/yoga_pose_model.dart';
import 'exercise_data.dart';

class YogaApiService {
  YogaApiService._();
  static final instance = YogaApiService._();

  static const _baseUrl = 'https://yoga-api-nzy4.onrender.com/v1';

  List<YogaPose>? _cache;
  List<WorkoutProgram>? _programs;

  Future<List<YogaPose>> fetchPoses({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;

    try {
      final responses = await Future.wait([
        http
            .get(Uri.parse('$_baseUrl/poses?level=beginner'))
            .timeout(const Duration(seconds: 30)),
        http
            .get(Uri.parse('$_baseUrl/poses?level=intermediate'))
            .timeout(const Duration(seconds: 30)),
        http
            .get(Uri.parse('$_baseUrl/poses?level=expert'))
            .timeout(const Duration(seconds: 30)),
      ]);

      final poses = <YogaPose>[];
      for (final response in responses) {
        if (response.statusCode != 200) continue;
        final decoded = json.decode(response.body);
        // Level endpoints return {difficulty_level, poses: [...]}
        if (decoded is Map<String, dynamic>) {
          final difficulty = decoded['difficulty_level'] as String? ?? '';
          final list = decoded['poses'] as List? ?? [];
          poses.addAll(list.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            map['difficulty_level'] = difficulty;
            return YogaPose.fromJson(map);
          }));
        }
        // Flat /poses endpoint returns [...]
        else if (decoded is List) {
          poses.addAll(decoded.map(
            (item) => YogaPose.fromJson(item as Map<String, dynamic>),
          ));
        }
      }

      _cache = poses;

      // Convert to ExerciseModels and register them
      final exerciseModels = _convertToExerciseModels(poses);
      ExerciseData.registerDynamicExercises(exerciseModels);

      // Build workout programs grouped by difficulty
      _programs = _buildWorkoutPrograms(poses);

      return poses;
    } catch (_) {
      return [];
    }
  }

  List<WorkoutProgram> get programs => _programs ?? [];

  static ExerciseDifficulty _mapDifficulty(String difficulty) {
    return switch (difficulty) {
      'Beginner' => ExerciseDifficulty.beginner,
      'Intermediate' => ExerciseDifficulty.intermediate,
      'Expert' => ExerciseDifficulty.advanced,
      _ => ExerciseDifficulty.beginner,
    };
  }

  static int _durationForDifficulty(String difficulty) {
    return switch (difficulty) {
      'Beginner' => 30,
      'Intermediate' => 45,
      'Expert' => 60,
      _ => 30,
    };
  }

  static String _poseId(YogaPose pose) =>
      'yoga_${pose.id}';

  List<ExerciseModel> _convertToExerciseModels(List<YogaPose> poses) {
    return poses.map((pose) {
      final instructions = <String>[];
      if (pose.description.isNotEmpty) {
        instructions.addAll(
          pose.description
              .split(RegExp(r'(?<=[.!?])\s+'))
              .where((s) => s.trim().isNotEmpty),
        );
      }

      return ExerciseModel(
        id: _poseId(pose),
        name: pose.englishName,
        networkImageUrl: pose.pngUrl.isNotEmpty ? pose.pngUrl : null,
        category: 'Yoga',
        difficulty: _mapDifficulty(pose.difficulty),
        isTimeBased: true,
        defaultDurationSecs: _durationForDifficulty(pose.difficulty),
        description: pose.benefits,
        instructions: instructions,
        muscleGroups: const ['Flexibility', 'Balance'],
        breathingTips: const [
          'Breathe slowly and deeply through your nose.',
          'Hold each pose with steady, calm breathing.',
        ],
      );
    }).toList();
  }

  List<WorkoutProgram> _buildWorkoutPrograms(List<YogaPose> poses) {
    final beginner =
        poses.where((p) => p.difficulty == 'Beginner').toList();
    final intermediate =
        poses.where((p) => p.difficulty == 'Intermediate').toList();
    final expert =
        poses.where((p) => p.difficulty == 'Expert').toList();

    final programs = <WorkoutProgram>[];

    if (beginner.isNotEmpty) {
      programs.add(WorkoutProgram(
        id: 'yoga_beginner',
        name: 'Yoga Beginner',
        bodyFocus: 'Yoga',
        difficulty: ExerciseDifficulty.beginner,
        estimatedDurationMins: (beginner.length * 30 / 60).ceil(),
        exercises: beginner
            .map((p) => WorkoutExercise(
                  exerciseId: _poseId(p),
                  durationSecs: 30,
                ))
            .toList(),
      ));
    }

    if (intermediate.isNotEmpty) {
      programs.add(WorkoutProgram(
        id: 'yoga_intermediate',
        name: 'Yoga Intermediate',
        bodyFocus: 'Yoga',
        difficulty: ExerciseDifficulty.intermediate,
        estimatedDurationMins: (intermediate.length * 45 / 60).ceil(),
        exercises: intermediate
            .map((p) => WorkoutExercise(
                  exerciseId: _poseId(p),
                  durationSecs: 45,
                ))
            .toList(),
      ));
    }

    if (expert.isNotEmpty) {
      programs.add(WorkoutProgram(
        id: 'yoga_expert',
        name: 'Yoga Expert',
        bodyFocus: 'Yoga',
        difficulty: ExerciseDifficulty.advanced,
        estimatedDurationMins: (expert.length * 60 / 60).ceil(),
        exercises: expert
            .map((p) => WorkoutExercise(
                  exerciseId: _poseId(p),
                  durationSecs: 60,
                ))
            .toList(),
      ));
    }

    return programs;
  }
}
