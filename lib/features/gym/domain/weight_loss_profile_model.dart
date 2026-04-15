import 'tracked_food_model.dart';

enum Gender { male, female }

enum GoalType {
  lose('Weight Loss', 'Eat fewer calories than you burn'),
  gain('Weight Gain', 'Eat more calories than you burn'),
  maintain('Maintain Weight', 'Eat the same calories you burn');

  const GoalType(this.label, this.description);
  final String label;
  final String description;
}

enum ActivityLevel {
  sedentary('Sedentary', 'Little or no exercise', 1.2),
  light('Lightly Active', 'Exercise 1-3 days/week', 1.375),
  moderate('Moderately Active', 'Exercise 3-5 days/week', 1.55),
  active('Very Active', 'Exercise 6-7 days/week', 1.725),
  extreme('Extra Active', 'Very hard exercise daily', 1.9);

  const ActivityLevel(this.label, this.description, this.multiplier);
  final String label;
  final String description;
  final double multiplier;
}

class WeightLossProfileModel {
  const WeightLossProfileModel({
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.currentWeight,
    required this.targetWeight,
    required this.heightCm,
    this.weeklyGoalKg = 0.5,
    this.goalType = GoalType.lose,
    this.isVegetarian = false,
    this.gymTimeHour,
    this.proteinScoops = 1,
    this.takesCreatine = false,
    this.takesMassGainer = false,
  });

  final int age;
  final Gender gender;
  final ActivityLevel activityLevel;
  final double currentWeight; // kg
  final double targetWeight; // kg
  final double heightCm;
  final double weeklyGoalKg;
  final GoalType goalType;
  final bool isVegetarian;
  final int? gymTimeHour; // null = no gym time set (0-23)
  final int proteinScoops; // number of whey protein scoops per day
  final bool takesCreatine;
  final bool takesMassGainer; // only relevant for weight gain goal

  // Mifflin-St Jeor BMR
  double get bmr {
    if (gender == Gender.male) {
      return 10 * currentWeight + 6.25 * heightCm - 5 * age + 5;
    } else {
      return 10 * currentWeight + 6.25 * heightCm - 5 * age - 161;
    }
  }

  double get tdee => bmr * activityLevel.multiplier;

  double get dailyCalorieTarget {
    final adjustment = weeklyGoalKg * 7700 / 7; // 7700 kcal per kg
    switch (goalType) {
      case GoalType.lose:
        final target = tdee - adjustment;
        return target.clamp(1200, tdee);
      case GoalType.gain:
        return tdee + adjustment;
      case GoalType.maintain:
        return tdee;
    }
  }

  // Macros vary by goal
  double get proteinGrams {
    switch (goalType) {
      case GoalType.gain:
        // Higher protein for muscle gain: 35% protein, 40% carbs, 25% fat
        return (dailyCalorieTarget * 0.35) / 4;
      default:
        return (dailyCalorieTarget * 0.30) / 4;
    }
  }

  double get carbsGrams {
    switch (goalType) {
      case GoalType.gain:
        return (dailyCalorieTarget * 0.40) / 4;
      default:
        return (dailyCalorieTarget * 0.40) / 4;
    }
  }

  double get fatGrams {
    switch (goalType) {
      case GoalType.gain:
        return (dailyCalorieTarget * 0.25) / 9;
      default:
        return (dailyCalorieTarget * 0.30) / 9;
    }
  }

  // ── Micronutrient RDA (Recommended Daily Allowance) ──
  // Based on age, gender per ICMR/WHO/USDA guidelines

  /// Dietary fiber (grams)
  double get fiberRDA {
    if (gender == Gender.male) return age <= 50 ? 38 : 30;
    return age <= 50 ? 25 : 21;
  }

  /// Sugar limit (grams) - WHO recommends <25g added sugar
  double get sugarLimit => 25;

  /// Sodium limit (mg) - WHO recommends <2000mg
  double get sodiumLimit => 2000;

  /// Cholesterol limit (mg) - dietary guideline <300mg
  double get cholesterolLimit => 300;

  /// Iron (mg) - varies significantly by gender
  double get ironRDA {
    if (gender == Gender.female) {
      if (age <= 50) return 18; // menstruating women
      return 8;
    }
    return 8; // adult males
  }

  /// Calcium (mg)
  double get calciumRDA {
    if (age <= 18) return 1300;
    if (age <= 50) return 1000;
    if (gender == Gender.female && age > 50) return 1200;
    if (age > 70) return 1200;
    return 1000;
  }

  /// Potassium (mg)
  double get potassiumRDA {
    if (gender == Gender.male) return 3400;
    return 2600;
  }

  /// Vitamin A (mcg RAE)
  double get vitaminARDA {
    if (gender == Gender.male) return 900;
    return 700;
  }

  /// Vitamin B12 (mcg)
  double get vitaminB12RDA => 2.4;

  /// Vitamin C (mg)
  double get vitaminCRDA {
    if (gender == Gender.male) return 90;
    return 75;
  }

  /// Vitamin D (mcg)
  double get vitaminDRDA {
    if (age > 70) return 20;
    return 15;
  }

  /// Zinc (mg)
  double get zincRDA {
    if (gender == Gender.male) return 11;
    return 8;
  }

  /// Magnesium (mg)
  double get magnesiumRDA {
    if (gender == Gender.male) return age > 30 ? 420 : 400;
    return age > 30 ? 320 : 310;
  }

  /// Vitamin E (mg)
  double get vitaminERDA => 15;

  /// Vitamin K (mcg)
  double get vitaminKRDA {
    if (gender == Gender.male) return 120;
    return 90;
  }

  /// Vitamin B6 (mg)
  double get vitaminB6RDA {
    if (age > 50) return 1.7;
    return 1.3;
  }

  /// Folate / Vitamin B9 (mcg DFE)
  double get folateRDA => 400;

  /// Phosphorus (mg)
  double get phosphorusRDA => 700;

  /// Selenium (mcg)
  double get seleniumRDA => 55;

  /// Manganese (mg)
  double get manganeseRDA {
    if (gender == Gender.male) return 2.3;
    return 1.8;
  }

  double get bmi => currentWeight / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Weight needed to reach normal BMI (18.5–25)
  String get bmiWeightAdvice {
    final heightM = heightCm / 100;
    final heightM2 = heightM * heightM;
    if (bmi >= 25) {
      final normalMaxWeight = 25 * heightM2;
      final toLose = currentWeight - normalMaxWeight;
      return 'Lose ${toLose.toStringAsFixed(1)} kg to reach normal BMI';
    } else if (bmi < 18.5) {
      final normalMinWeight = 18.5 * heightM2;
      final toGain = normalMinWeight - currentWeight;
      return 'Gain ${toGain.toStringAsFixed(1)} kg to reach normal BMI';
    }
    return 'Your weight is in the normal range';
  }

  double get weightDifference => (currentWeight - targetWeight).abs();

  double get weightToLose => goalType == GoalType.lose
      ? (currentWeight - targetWeight).clamp(0, double.infinity)
      : 0;

  double get weightToGain => goalType == GoalType.gain
      ? (targetWeight - currentWeight).clamp(0, double.infinity)
      : 0;

  int get estimatedWeeks {
    if (weeklyGoalKg <= 0) return 0;
    return (weightDifference / weeklyGoalKg).ceil();
  }

  String get goalLabel {
    switch (goalType) {
      case GoalType.lose:
        return '${weightToLose.toStringAsFixed(1)} kg to lose';
      case GoalType.gain:
        return '${weightToGain.toStringAsFixed(1)} kg to gain';
      case GoalType.maintain:
        return 'Maintaining weight';
    }
  }

  /// Whether the user goes to gym
  bool get hasGymTime => gymTimeHour != null;

  /// Meal slot for whey protein based on gym time
  /// If gym is morning (before 12), put protein in morning snack
  /// If gym is afternoon/evening (12+), put protein in evening snack
  /// If no gym time, default to morning snack
  MealType get wheyProteinMealSlot {
    if (gymTimeHour == null) return MealType.morningSnack;
    if (gymTimeHour! < 12) return MealType.morningSnack;
    return MealType.eveningSnack;
  }

  Map<String, dynamic> toFirestore() => {
        'wl_age': age,
        'wl_gender': gender.name,
        'wl_activityLevel': activityLevel.name,
        'wl_currentWeight': currentWeight,
        'wl_targetWeight': targetWeight,
        'wl_heightCm': heightCm,
        'wl_weeklyGoalKg': weeklyGoalKg,
        'wl_goalType': goalType.name,
        'wl_isVegetarian': isVegetarian,
        'wl_gymTimeHour': gymTimeHour,
        'wl_proteinScoops': proteinScoops,
        'wl_takesCreatine': takesCreatine,
        'wl_takesMassGainer': takesMassGainer,
      };

  factory WeightLossProfileModel.fromFirestore(Map<String, dynamic> data) {
    return WeightLossProfileModel(
      age: (data['wl_age'] as num?)?.toInt() ?? 25,
      gender: Gender.values.firstWhere(
        (e) => e.name == data['wl_gender'],
        orElse: () => Gender.male,
      ),
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.name == data['wl_activityLevel'],
        orElse: () => ActivityLevel.moderate,
      ),
      currentWeight: (data['wl_currentWeight'] as num?)?.toDouble() ?? 70,
      targetWeight: (data['wl_targetWeight'] as num?)?.toDouble() ?? 65,
      heightCm: (data['wl_heightCm'] as num?)?.toDouble() ?? 170,
      weeklyGoalKg: (data['wl_weeklyGoalKg'] as num?)?.toDouble() ?? 0.5,
      goalType: GoalType.values.firstWhere(
        (e) => e.name == data['wl_goalType'],
        orElse: () => GoalType.lose,
      ),
      isVegetarian: data['wl_isVegetarian'] as bool? ?? false,
      gymTimeHour: (data['wl_gymTimeHour'] as num?)?.toInt(),
      proteinScoops: (data['wl_proteinScoops'] as num?)?.toInt() ?? 1,
      takesCreatine: data['wl_takesCreatine'] as bool? ?? false,
      takesMassGainer: data['wl_takesMassGainer'] as bool? ?? false,
    );
  }

  WeightLossProfileModel copyWith({
    int? age,
    Gender? gender,
    ActivityLevel? activityLevel,
    double? currentWeight,
    double? targetWeight,
    double? heightCm,
    double? weeklyGoalKg,
    GoalType? goalType,
    bool? isVegetarian,
    int? gymTimeHour,
    bool clearGymTime = false,
    int? proteinScoops,
    bool? takesCreatine,
    bool? takesMassGainer,
  }) {
    return WeightLossProfileModel(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      heightCm: heightCm ?? this.heightCm,
      weeklyGoalKg: weeklyGoalKg ?? this.weeklyGoalKg,
      goalType: goalType ?? this.goalType,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      gymTimeHour: clearGymTime ? null : (gymTimeHour ?? this.gymTimeHour),
      proteinScoops: proteinScoops ?? this.proteinScoops,
      takesCreatine: takesCreatine ?? this.takesCreatine,
      takesMassGainer: takesMassGainer ?? this.takesMassGainer,
    );
  }
}
