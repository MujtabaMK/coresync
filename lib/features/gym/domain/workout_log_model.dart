import 'package:flutter/material.dart';

enum WorkoutType {
  walking('Walking', Icons.directions_walk, 3.5),
  running('Running', Icons.directions_run, 9.8),
  bicycling('Bicycling', Icons.directions_bike, 7.5),
  swimming('Swimming', Icons.pool, 8.0),
  yoga('Yoga', Icons.self_improvement, 3.0),
  weightTraining('Weight Training', Icons.fitness_center, 6.0),
  hiit('HIIT', Icons.flash_on, 12.0),
  dancing('Dancing', Icons.music_note, 5.5),
  hiking('Hiking', Icons.terrain, 6.0),
  jumpRope('Jump Rope', Icons.sports, 12.3),
  rowing('Rowing', Icons.rowing, 7.0),
  stairClimbing('Stair Climbing', Icons.stairs, 9.0),
  stretching('Stretching', Icons.accessibility_new, 2.5),
  pilates('Pilates', Icons.sports_gymnastics, 3.8),
  martialArts('Martial Arts', Icons.sports_martial_arts, 10.3),
  other('Other', Icons.sports_score, 5.0);

  const WorkoutType(this.label, this.icon, this.defaultMET);
  final String label;
  final IconData icon;
  final double defaultMET;
}

enum WorkoutIntensity {
  slow('Slow', 0.75),
  moderate('Moderate', 1.0),
  fast('Fast', 1.3);

  const WorkoutIntensity(this.label, this.multiplier);
  final String label;
  final double multiplier;
}

class WorkoutLogModel {
  WorkoutLogModel({
    required this.id,
    required this.workoutType,
    required this.intensity,
    required this.durationMinutes,
    required this.userWeightKg,
    this.distanceKm,
    this.speedKmh,
    this.caloriesBurnt,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  final String id;
  final WorkoutType workoutType;
  final WorkoutIntensity intensity;
  final int durationMinutes;
  final double userWeightKg;
  final double? distanceKm;
  final double? speedKmh;
  final double? caloriesBurnt; // manual override
  final DateTime loggedAt;

  /// MET * intensity_multiplier * weight_kg * (duration_min / 60)
  double get calculatedCalories =>
      workoutType.defaultMET *
      intensity.multiplier *
      userWeightKg *
      (durationMinutes / 60);

  double get effectiveCalories => caloriesBurnt ?? calculatedCalories;

  Map<String, dynamic> toFirestore() => {
        'workoutType': workoutType.name,
        'intensity': intensity.name,
        'durationMinutes': durationMinutes,
        'userWeightKg': userWeightKg,
        'distanceKm': distanceKm,
        'speedKmh': speedKmh,
        'caloriesBurnt': caloriesBurnt,
        'loggedAt': loggedAt.millisecondsSinceEpoch,
      };

  factory WorkoutLogModel.fromFirestore(
      String id, Map<String, dynamic> data) {
    return WorkoutLogModel(
      id: id,
      workoutType: WorkoutType.values.firstWhere(
        (e) => e.name == data['workoutType'],
        orElse: () => WorkoutType.other,
      ),
      intensity: WorkoutIntensity.values.firstWhere(
        (e) => e.name == data['intensity'],
        orElse: () => WorkoutIntensity.moderate,
      ),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      userWeightKg: (data['userWeightKg'] as num?)?.toDouble() ?? 70,
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      speedKmh: (data['speedKmh'] as num?)?.toDouble(),
      caloriesBurnt: (data['caloriesBurnt'] as num?)?.toDouble(),
      loggedAt: data['loggedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['loggedAt'] as num).toInt())
          : DateTime.now(),
    );
  }
}
