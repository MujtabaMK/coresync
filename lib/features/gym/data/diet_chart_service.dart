import 'dart:math';

import '../domain/tracked_food_model.dart';
import '../domain/weight_loss_profile_model.dart';
import 'common_foods_data.dart';
import 'food_database_service.dart';

// ── Data Models ──────────────────────────────────────────────────────────────

class DietFoodSuggestion {
  const DietFoodSuggestion({
    required this.name,
    required this.servingSize,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String name;
  final String servingSize;
  final double servings;
  final double calories; // total after scaling
  final double protein;
  final double carbs;
  final double fat;
}

class DietMealPlan {
  const DietMealPlan({
    required this.mealType,
    required this.calorieBudget,
    required this.foods,
  });

  final MealType mealType;
  final int calorieBudget;
  final List<DietFoodSuggestion> foods;

  int get totalCalories => foods.fold(0, (s, f) => s + f.calories.round());
  double get totalProtein => foods.fold(0.0, (s, f) => s + f.protein);
  double get totalCarbs => foods.fold(0.0, (s, f) => s + f.carbs);
  double get totalFat => foods.fold(0.0, (s, f) => s + f.fat);
}

class DailyDietPlan {
  const DailyDietPlan({
    required this.dayLabel,
    required this.meals,
  });

  final String dayLabel; // "Monday", "Tuesday", etc.
  final List<DietMealPlan> meals;

  int get totalCalories => meals.fold(0, (s, m) => s + m.totalCalories);
}

class WeeklyDietChart {
  const WeeklyDietChart({
    required this.profile,
    required this.days,
    required this.waterGoalMl,
    required this.stepsGoal,
    required this.tips,
  });

  final WeightLossProfileModel profile;
  final List<DailyDietPlan> days; // 7 days
  final int waterGoalMl; // from app's actual daily goal
  final int stepsGoal; // from app's actual daily goal
  final List<String> tips;
}

// ── Service ──────────────────────────────────────────────────────────────────

class DietChartService {
  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Per-meal category pools — real foods only
  static const _breakfastCategories = [
    'Breakfast',
    'South Indian',
    'Eggs & Dairy',
  ];
  static const _lunchCategories = [
    'Dal & Lentils',
    'Vegetables',
    'Rice & Grains',
    'Roti & Bread',
    'Non-Veg',
  ];
  static const _dinnerCategories = [
    'Non-Veg',
    'Vegetables',
    'Dal & Lentils',
    'Roti & Bread',
    'South Indian',
  ];
  static const _snackCategories = [
    'Fruits',
    'Nuts & Seeds',
    'Dry Fruits & Nuts',
    'Eggs & Dairy',
    'Beverages',
  ];

  /// Names (lowercase substrings) that indicate a protein supplement.
  static bool _isSupplement(String name) {
    final n = name.toLowerCase();
    return n.contains('whey') ||
        n.contains('isolate') ||
        n.contains('protein bar') ||
        n.contains('protein shake') ||
        n.contains('muscleblaze') ||
        n.contains('optimum nutrition') ||
        n.contains('myprotein') ||
        n.contains('isopure') ||
        n.contains('dymatize') ||
        n.contains('allmax') ||
        n.contains('nitrotech') ||
        n.contains('on gold');
  }

  /// Non-veg keywords for filtering when vegetarian mode is on.
  static final _nonVegKeywords = [
    'chicken', 'fish', 'egg', 'mutton', 'keema', 'prawn', 'meat',
    'shrimp', 'lamb', 'pork', 'beef', 'crab', 'lobster', 'turkey',
  ];

  static bool _isNonVeg(String name) {
    final n = name.toLowerCase();
    return _nonVegKeywords.any((kw) => n.contains(kw));
  }

  static Future<WeeklyDietChart> generate(
    WeightLossProfileModel profile, {
    required int waterGoalMl,
    required int stepsGoal,
    bool isVegetarian = false,
  }) async {
    final db = FoodDatabaseService.instance;
    final goal = profile.goalType;
    final bmiCat = profile.bmiCategory;
    final dailyCal = profile.dailyCalorieTarget.round();

    // Build category lists based on diet preference
    final bfCats = isVegetarian
        ? const ['Breakfast', 'South Indian']
        : _breakfastCategories;
    final lnCats = isVegetarian
        ? const ['Dal & Lentils', 'Vegetables', 'Rice & Grains', 'Roti & Bread']
        : _lunchCategories;
    final dnCats = isVegetarian
        ? const ['Vegetables', 'Dal & Lentils', 'Roti & Bread', 'South Indian']
        : _dinnerCategories;
    final skCats = isVegetarian
        ? const ['Fruits', 'Nuts & Seeds', 'Dry Fruits & Nuts', 'Beverages']
        : _snackCategories;

    // Load food pools per meal type
    final breakfastPool = await _loadPool(db, bfCats);
    final lunchPool = await _loadPool(db, lnCats);
    final dinnerPool = await _loadPool(db, dnCats);
    final snackPool = await _loadPool(db, skCats);

    // For veg mode, also load paneer items to enrich protein options
    if (isVegetarian) {
      final paneerPool = await db.getFoodsByCategory('Paneer', limit: 50);
      lunchPool.addAll(paneerPool);
      dinnerPool.addAll(paneerPool);
    }

    // Filter: remove supplements from all pools, keep only real foods
    var bfPool = _filterRealFoods(breakfastPool);
    var lnPool = _filterRealFoods(lunchPool);
    var dnPool = _filterRealFoods(dinnerPool);
    var skPool = _filterRealFoods(snackPool);

    // When vegetarian, also filter out any stray non-veg items by name
    if (isVegetarian) {
      bfPool = bfPool.where((f) => !_isNonVeg(f.name)).toList();
      lnPool = lnPool.where((f) => !_isNonVeg(f.name)).toList();
      dnPool = dnPool.where((f) => !_isNonVeg(f.name)).toList();
      skPool = skPool.where((f) => !_isNonVeg(f.name)).toList();
    }

    // Optionally load 1 supplement for the whole day (snack only)
    final supplementPool = await db.getFoodsByCategory('Protein', limit: 50);
    final supplements =
        supplementPool.where((f) => _isSupplement(f.name)).toList();

    final rng = Random();
    final usedNames = <String>{}; // track across days to add variety

    final days = <DailyDietPlan>[];
    for (var d = 0; d < 7; d++) {
      bool usedSupplementToday = false;
      final dayMeals = <DietMealPlan>[];

      for (final meal in MealType.values) {
        final mealBudget = (dailyCal * meal.calorieShare).round();

        List<CommonFoodItem> pool;
        switch (meal) {
          case MealType.breakfast:
            pool = bfPool;
          case MealType.lunch:
            pool = lnPool;
          case MealType.dinner:
            pool = dnPool;
          case MealType.morningSnack:
          case MealType.eveningSnack:
            pool = List.of(skPool);
            // Allow max 1 protein supplement per day, only in a snack slot
            if (!usedSupplementToday && supplements.isNotEmpty) {
              // Add ONE random supplement to the pool
              final s = supplements[rng.nextInt(supplements.length)];
              pool.add(s);
            }
        }

        final mealFoods = _pickFoodsForMeal(
          pool: pool,
          calorieBudget: mealBudget,
          goal: goal,
          bmiCat: bmiCat,
          rng: rng,
          usedNames: usedNames,
          maxSupplements: usedSupplementToday ? 0 : 1,
        );

        // Track if supplement was used
        for (final f in mealFoods) {
          if (_isSupplement(f.name)) usedSupplementToday = true;
        }

        dayMeals.add(DietMealPlan(
          mealType: meal,
          calorieBudget: mealBudget,
          foods: mealFoods,
        ));
      }

      days.add(DailyDietPlan(dayLabel: _dayNames[d], meals: dayMeals));
      // Reset used names each day but keep some to avoid same food every day
      if (usedNames.length > 40) {
        final keep = usedNames.toList()..shuffle(rng);
        usedNames
          ..clear()
          ..addAll(keep.take(15));
      }
    }

    final tips = _tipsForProfile(goal, bmiCat);

    return WeeklyDietChart(
      profile: profile,
      days: days,
      waterGoalMl: waterGoalMl,
      stepsGoal: stepsGoal,
      tips: tips,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Future<List<CommonFoodItem>> _loadPool(
      FoodDatabaseService db, List<String> categories) async {
    final items = <CommonFoodItem>[];
    for (final cat in categories) {
      items.addAll(await db.getFoodsByCategory(cat, limit: 150));
    }
    return items;
  }

  static List<CommonFoodItem> _filterRealFoods(List<CommonFoodItem> pool) {
    return pool
        .where((f) =>
            f.calories > 10 &&
            f.calories < 800 &&
            !_isSupplement(f.name))
        .toList();
  }

  static List<DietFoodSuggestion> _pickFoodsForMeal({
    required List<CommonFoodItem> pool,
    required int calorieBudget,
    required GoalType goal,
    required String bmiCat,
    required Random rng,
    required Set<String> usedNames,
    int maxSupplements = 0,
  }) {
    if (pool.isEmpty || calorieBudget <= 0) return [];

    // Separate supplements from real foods
    final realFoods = <CommonFoodItem>[];
    final supps = <CommonFoodItem>[];
    for (final f in pool) {
      if (_isSupplement(f.name)) {
        supps.add(f);
      } else {
        realFoods.add(f);
      }
    }

    // Prefer foods not already used
    final fresh =
        realFoods.where((f) => !usedNames.contains(f.name)).toList();
    final candidates = fresh.isNotEmpty ? fresh : realFoods;

    // Shuffle for variety
    final shuffled = List.of(candidates)..shuffle(rng);

    final picks = <DietFoodSuggestion>[];
    int remaining = calorieBudget;
    int supplementsUsed = 0;
    final targetItems = 3 + rng.nextInt(2); // 3-4 real foods

    // Optionally add 1 supplement first (1 scoop only)
    if (maxSupplements > 0 && supps.isNotEmpty && rng.nextDouble() < 0.4) {
      final s = supps[rng.nextInt(supps.length)];
      if (s.calories <= remaining && s.calories > 0) {
        picks.add(DietFoodSuggestion(
          name: s.name,
          servingSize: s.servingSize,
          servings: 1, // always 1 scoop
          calories: s.calories,
          protein: s.protein,
          carbs: s.carbs,
          fat: s.fat,
        ));
        remaining -= s.calories.round();
        supplementsUsed++;
        usedNames.add(s.name);
      }
    }

    // Fill remaining with real foods
    for (final food in shuffled) {
      if (picks.length >= targetItems + supplementsUsed) break;
      if (remaining <= 30) break;
      if (food.calories <= 0) continue;

      // Calculate servings: keep at 1x for most items
      double servings = 1.0;
      if (food.calories > remaining) {
        // Try half serving
        servings = 0.5;
        if (food.calories * 0.5 > remaining) continue;
      } else if (food.calories < remaining * 0.2 && food.calories < 150) {
        // Small item — can do 1.5x if it fits
        servings = min(1.5, remaining / food.calories);
        servings = (servings * 2).floor() / 2; // round to 0.5
        if (servings < 0.5) servings = 0.5;
      }

      final actualCal = food.calories * servings;
      if (actualCal > remaining) continue;

      picks.add(DietFoodSuggestion(
        name: food.name,
        servingSize: food.servingSize,
        servings: servings,
        calories: actualCal,
        protein: food.protein * servings,
        carbs: food.carbs * servings,
        fat: food.fat * servings,
      ));
      remaining -= actualCal.round();
      usedNames.add(food.name);
    }

    return picks;
  }

  static List<String> _tipsForProfile(GoalType goal, String bmiCat) {
    if (goal == GoalType.lose ||
        bmiCat == 'Overweight' ||
        bmiCat == 'Obese') {
      return [
        'Eat slowly and mindfully - it takes 20 minutes to feel full.',
        'Include protein in every meal to reduce hunger and preserve muscle.',
        'Fill half your plate with vegetables to increase fiber intake.',
        'Avoid sugary drinks; switch to water, green tea, or black coffee.',
        'Get 7-8 hours of sleep - poor sleep increases cravings.',
      ];
    } else if (goal == GoalType.gain || bmiCat == 'Underweight') {
      return [
        'Eat calorie-dense foods like nuts, dried fruits, and whole grains.',
        'Add healthy fats (ghee, olive oil, avocado) to meals.',
        'Include a protein shake or milk-based drink as a snack.',
        'Eat more frequently - aim for 5-6 meals/snacks per day.',
        'Strength training helps convert extra calories into muscle, not fat.',
      ];
    }
    return [
      'Focus on balanced meals with protein, carbs, and healthy fats.',
      'Stay consistent with meal timing to regulate metabolism.',
      'Keep hydrated - aim for at least 8 glasses of water daily.',
      'Include a variety of colorful fruits and vegetables.',
      'Regular physical activity helps maintain weight and overall health.',
    ];
  }
}
