import '../domain/exercise_model.dart';
import '../domain/workout_program_model.dart';

class WorkoutProgramData {
  WorkoutProgramData._();

  static const List<WorkoutProgram> _programs = [
    // ── Chest ──
    WorkoutProgram(
      id: 'chest_beginner',
      name: 'Chest Starter',
      bodyFocus: 'Chest',
      difficulty: ExerciseDifficulty.beginner,
      estimatedDurationMins: 15,
      exercises: [
        WorkoutExercise(exerciseId: 'push_ups', reps: 12),
        WorkoutExercise(exerciseId: 'push_ups', reps: 12),
        WorkoutExercise(exerciseId: 'dumbbell_fly', reps: 10),
      ],
    ),
    WorkoutProgram(
      id: 'chest_intermediate',
      name: 'Chest Builder',
      bodyFocus: 'Chest',
      difficulty: ExerciseDifficulty.intermediate,
      estimatedDurationMins: 25,
      exercises: [
        WorkoutExercise(exerciseId: 'bench_press', reps: 12),
        WorkoutExercise(exerciseId: 'incline_dumbbell_press', reps: 12),
        WorkoutExercise(exerciseId: 'dumbbell_fly', reps: 12),
        WorkoutExercise(exerciseId: 'push_ups', reps: 15),
      ],
    ),
    WorkoutProgram(
      id: 'chest_advanced',
      name: 'Chest Destroyer',
      bodyFocus: 'Chest',
      difficulty: ExerciseDifficulty.advanced,
      estimatedDurationMins: 35,
      exercises: [
        WorkoutExercise(exerciseId: 'bench_press', reps: 10),
        WorkoutExercise(exerciseId: 'incline_dumbbell_press', reps: 10),
        WorkoutExercise(exerciseId: 'cable_crossover', reps: 12),
        WorkoutExercise(exerciseId: 'dumbbell_fly', reps: 12),
        WorkoutExercise(exerciseId: 'push_ups', reps: 20),
      ],
    ),

    // ── Back ──
    WorkoutProgram(
      id: 'back_beginner',
      name: 'Back Basics',
      bodyFocus: 'Back',
      difficulty: ExerciseDifficulty.beginner,
      estimatedDurationMins: 15,
      exercises: [
        WorkoutExercise(exerciseId: 'lat_pulldown', reps: 12),
        WorkoutExercise(exerciseId: 'seated_cable_row', reps: 12),
        WorkoutExercise(exerciseId: 'lat_pulldown', reps: 10),
      ],
    ),
    WorkoutProgram(
      id: 'back_intermediate',
      name: 'Back Builder',
      bodyFocus: 'Back',
      difficulty: ExerciseDifficulty.intermediate,
      estimatedDurationMins: 25,
      exercises: [
        WorkoutExercise(exerciseId: 'pull_ups', reps: 8),
        WorkoutExercise(exerciseId: 'barbell_row', reps: 12),
        WorkoutExercise(exerciseId: 'seated_cable_row', reps: 12),
        WorkoutExercise(exerciseId: 'lat_pulldown', reps: 12),
      ],
    ),
    WorkoutProgram(
      id: 'back_advanced',
      name: 'Back Annihilator',
      bodyFocus: 'Back',
      difficulty: ExerciseDifficulty.advanced,
      estimatedDurationMins: 35,
      exercises: [
        WorkoutExercise(exerciseId: 'deadlift', reps: 8),
        WorkoutExercise(exerciseId: 'pull_ups', reps: 10),
        WorkoutExercise(exerciseId: 'barbell_row', reps: 10),
        WorkoutExercise(exerciseId: 'seated_cable_row', reps: 12),
        WorkoutExercise(exerciseId: 'lat_pulldown', reps: 12),
      ],
    ),

    // ── Shoulders ──
    WorkoutProgram(
      id: 'shoulders_beginner',
      name: 'Shoulder Starter',
      bodyFocus: 'Shoulders',
      difficulty: ExerciseDifficulty.beginner,
      estimatedDurationMins: 12,
      exercises: [
        WorkoutExercise(exerciseId: 'lateral_raise', reps: 15),
        WorkoutExercise(exerciseId: 'face_pull', reps: 15),
        WorkoutExercise(exerciseId: 'lateral_raise', reps: 12),
      ],
    ),
    WorkoutProgram(
      id: 'shoulders_advanced',
      name: 'Boulder Shoulders',
      bodyFocus: 'Shoulders',
      difficulty: ExerciseDifficulty.advanced,
      estimatedDurationMins: 25,
      exercises: [
        WorkoutExercise(exerciseId: 'overhead_press', reps: 10),
        WorkoutExercise(exerciseId: 'arnold_press', reps: 10),
        WorkoutExercise(exerciseId: 'lateral_raise', reps: 15),
        WorkoutExercise(exerciseId: 'face_pull', reps: 15),
      ],
    ),

    // ── Arms ──
    WorkoutProgram(
      id: 'arms_beginner',
      name: 'Arm Toner',
      bodyFocus: 'Arms',
      difficulty: ExerciseDifficulty.beginner,
      estimatedDurationMins: 12,
      exercises: [
        WorkoutExercise(exerciseId: 'bicep_curl', reps: 12),
        WorkoutExercise(exerciseId: 'hammer_curl', reps: 12),
        WorkoutExercise(exerciseId: 'bicep_curl', reps: 10),
      ],
    ),
    WorkoutProgram(
      id: 'arms_advanced',
      name: 'Arm Blaster',
      bodyFocus: 'Arms',
      difficulty: ExerciseDifficulty.advanced,
      estimatedDurationMins: 25,
      exercises: [
        WorkoutExercise(exerciseId: 'bicep_curl', reps: 12),
        WorkoutExercise(exerciseId: 'skull_crusher', reps: 10),
        WorkoutExercise(exerciseId: 'hammer_curl', reps: 12),
        WorkoutExercise(exerciseId: 'tricep_dip', reps: 12),
      ],
    ),

    // ── Legs ──
    WorkoutProgram(
      id: 'legs_beginner',
      name: 'Leg Day Lite',
      bodyFocus: 'Legs',
      difficulty: ExerciseDifficulty.beginner,
      estimatedDurationMins: 15,
      exercises: [
        WorkoutExercise(exerciseId: 'lunges', reps: 12),
        WorkoutExercise(exerciseId: 'leg_press', reps: 12),
        WorkoutExercise(exerciseId: 'calf_raise', reps: 20),
      ],
    ),
    WorkoutProgram(
      id: 'legs_intermediate',
      name: 'Leg Builder',
      bodyFocus: 'Legs',
      difficulty: ExerciseDifficulty.intermediate,
      estimatedDurationMins: 25,
      exercises: [
        WorkoutExercise(exerciseId: 'squat', reps: 12),
        WorkoutExercise(exerciseId: 'lunges', reps: 12),
        WorkoutExercise(exerciseId: 'leg_press', reps: 12),
        WorkoutExercise(exerciseId: 'calf_raise', reps: 20),
      ],
    ),
    WorkoutProgram(
      id: 'legs_advanced',
      name: 'Leg Crusher',
      bodyFocus: 'Legs',
      difficulty: ExerciseDifficulty.advanced,
      estimatedDurationMins: 35,
      exercises: [
        WorkoutExercise(exerciseId: 'squat', reps: 10),
        WorkoutExercise(exerciseId: 'romanian_deadlift', reps: 10),
        WorkoutExercise(exerciseId: 'lunges', reps: 12),
        WorkoutExercise(exerciseId: 'leg_press', reps: 12),
        WorkoutExercise(exerciseId: 'calf_raise', reps: 20),
      ],
    ),

    // ── Core ──
    WorkoutProgram(
      id: 'core_beginner',
      name: 'Core Foundations',
      bodyFocus: 'Core',
      difficulty: ExerciseDifficulty.beginner,
      estimatedDurationMins: 10,
      exercises: [
        WorkoutExercise(exerciseId: 'plank', durationSecs: 20),
        WorkoutExercise(exerciseId: 'crunches', reps: 15),
        WorkoutExercise(exerciseId: 'plank', durationSecs: 20),
      ],
    ),
    WorkoutProgram(
      id: 'core_advanced',
      name: 'Core Inferno',
      bodyFocus: 'Core',
      difficulty: ExerciseDifficulty.advanced,
      estimatedDurationMins: 20,
      exercises: [
        WorkoutExercise(exerciseId: 'plank', durationSecs: 45),
        WorkoutExercise(exerciseId: 'russian_twist', reps: 20),
        WorkoutExercise(exerciseId: 'leg_raise', reps: 15),
        WorkoutExercise(exerciseId: 'crunches', reps: 25),
      ],
    ),

    // ── Cardio ──
    WorkoutProgram(
      id: 'cardio_beginner',
      name: 'Cardio Kickstart',
      bodyFocus: 'Cardio',
      difficulty: ExerciseDifficulty.beginner,
      estimatedDurationMins: 12,
      exercises: [
        WorkoutExercise(exerciseId: 'jump_rope', durationSecs: 45),
        WorkoutExercise(exerciseId: 'running', durationSecs: 45),
        WorkoutExercise(exerciseId: 'mountain_climbers', durationSecs: 20),
      ],
    ),
    WorkoutProgram(
      id: 'cardio_advanced',
      name: 'Cardio Blitz',
      bodyFocus: 'Cardio',
      difficulty: ExerciseDifficulty.advanced,
      estimatedDurationMins: 25,
      exercises: [
        WorkoutExercise(exerciseId: 'burpees', reps: 10),
        WorkoutExercise(exerciseId: 'mountain_climbers', durationSecs: 30),
        WorkoutExercise(exerciseId: 'jump_rope', durationSecs: 60),
        WorkoutExercise(exerciseId: 'running', durationSecs: 60),
        WorkoutExercise(exerciseId: 'burpees', reps: 10),
      ],
    ),
  ];

  static List<WorkoutProgram> get all => _programs;

  static List<WorkoutProgram> getByBodyFocus(String bodyFocus) {
    return _programs.where((p) => p.bodyFocus == bodyFocus).toList();
  }

  static WorkoutProgram? getById(String id) {
    for (final program in _programs) {
      if (program.id == id) return program;
    }
    return null;
  }
}
