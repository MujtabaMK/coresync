import 'dart:math';

import '../domain/tracked_food_model.dart';
import '../domain/weight_loss_profile_model.dart';
import 'common_foods_data.dart';
import 'food_database_service.dart';
import 'water_boost_foods_data.dart';

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
    required this.waterGoalMl,
  });

  final String dayLabel; // "Monday", "Tuesday", etc.
  final List<DietMealPlan> meals;
  final int waterGoalMl; // dynamic per-day water goal

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
        n.contains('on gold') ||
        n.contains('mass gainer') ||
        n.contains('creatine') ||
        n.contains('pre-workout') ||
        n.contains('bcaa') ||
        n.contains('eaa') ||
        n.contains('casein');
  }

  /// Names that indicate unhealthy / junk food — excluded from diet plans.
  /// Junk food stays blocked even in Air Fryer / Grilled form (samosa, pakora…).
  static bool _isUnhealthy(String name) {
    final n = name.toLowerCase();
    return n.contains('chocolate') ||
        n.contains('candy') ||
        n.contains('chips') ||
        n.contains('wafer') ||
        n.contains('cookie') ||
        n.contains('biscuit') ||
        n.contains('cake') ||
        n.contains('pastry') ||
        n.contains('brownie') ||
        n.contains('donut') ||
        n.contains('doughnut') ||
        n.contains('ice cream') ||
        n.contains('chocobar') ||
        n.contains('kulfi') ||
        n.contains('jalebi') ||
        n.contains('gulab jamun') ||
        n.contains('rasgulla') ||
        n.contains('rasmalai') ||
        n.contains('ladoo') ||
        n.contains('barfi') ||
        n.contains('halwa') ||
        n.contains('falooda') ||
        n.contains('pizza') ||
        n.contains('burger') ||
        n.contains('fries') ||
        n.contains('nugget') ||
        n.contains('fried chicken') ||
        n.contains('hot dog') ||
        n.contains('nachos') ||
        n.contains('coca cola') ||
        n.contains('pepsi') ||
        n.contains('sprite') ||
        n.contains('fanta') ||
        n.contains('mountain dew') ||
        n.contains('7up') ||
        n.contains('thums up') ||
        n.contains('limca') ||
        n.contains('energy drink') ||
        n.contains('red bull') ||
        n.contains('monster') ||
        n.contains('sting') ||
        n.contains('frooti') ||
        n.contains('maaza') ||
        n.contains('tang') ||
        n.contains('mcflurry') ||
        n.contains('mcdonald') ||
        n.contains('kfc') ||
        n.contains('domino') ||
        n.contains('burger king') ||
        n.contains('subway') ||
        n.contains('starbucks') ||
        n.contains('frappuccino') ||
        n.contains('maggi') ||
        n.contains('noodles') ||
        n.contains('cup noodle') ||
        n.contains('instant') ||
        n.contains('bhujia') ||
        n.contains('namkeen') ||
        n.contains('kurkure') ||
        n.contains('lay\'s') ||
        n.contains('pringles') ||
        n.contains('doritos') ||
        n.contains('snickers') ||
        n.contains('kitkat') ||
        n.contains('dairy milk') ||
        n.contains('5 star') ||
        n.contains('perk') ||
        n.contains('gems') ||
        n.contains('oreo') ||
        n.contains('bourbon') ||
        n.contains('cream roll') ||
        n.contains('swiss roll') ||
        n.contains('nutella') ||
        n.contains('jam') ||
        n.contains('mayonnaise') ||
        n.contains('ketchup') ||
        n.contains('samosa') ||
        n.contains('pakora') ||
        n.contains('bhajiya') ||
        n.contains('vada pav') ||
        n.contains('pav bhaji') ||
        n.contains('chole bhature') ||
        n.contains('popcorn') ||
        n.contains('cornetto') ||
        n.contains('magnum') ||
        n.contains('muffin') ||
        n.contains('croissant') ||
        n.contains('puff pastry') ||
        n.contains('puff') ||
        n.contains('bhatura') ||
        n.contains('manchurian') ||
        n.contains('chilli chicken') ||
        n.contains('schezwan') ||
        n.contains('fried rice') ||
        n.contains('fried momos') ||
        n.contains('cream biscuit') ||
        (n.contains('sugar') && n.contains('drink')) ||
        // Exclude beverages with milk & sugar — prefer black coffee / green tea
        (n.contains('with milk') && n.contains('sugar')) ||
        n.contains('milkshake') ||
        n.contains('frappe') ||
        n.contains('smoothie') && n.contains('ice cream');
  }

  /// Identifies oily / deep-fried originals of foods that were already part of
  /// the diet plan. These get replaced by their Air Fryer / Grilled versions.
  /// Does NOT touch foods already blocked by [_isUnhealthy] (samosa, pakora…).
  static bool _isOilyOriginal(String name) {
    final n = name.toLowerCase();
    // Air fryer / grilled versions are the healthy replacements — keep them
    if (n.contains('(air fryer)') || n.contains('(grilled)')) return false;
    // Skip dal fry / stir fry / egg pepper fry — these are cooking styles, not
    // deep-fried dishes
    if (n.contains('dal fry') ||
        n.contains('daal fry') ||
        n.contains('stir fry') ||
        n.contains('pepper fry')) {
      return false;
    }
    // Oily originals that were previously allowed in the diet pools:
    // Parathas, puris, fish/meat fry, veggie fry, vada, cutlet
    return n.contains('paratha') ||
        n.contains('puri') ||
        (n.contains('fry') && !n.contains('dal')) ||
        (n.contains('fried') && !n.contains('dal')) ||
        n.contains('vada') ||
        n.contains('cutlet');
  }

  /// Non-veg keywords for filtering when vegetarian mode is on.
  static final _nonVegKeywords = [
    'chicken', 'fish', 'mutton', 'keema', 'prawn', 'meat',
    'shrimp', 'lamb', 'pork', 'beef', 'crab', 'lobster', 'turkey',
    'salmon', 'tuna', 'sardine', 'mackerel', 'surimi', 'bacon',
    'sausage', 'pepperoni', 'ham',
  ];

  /// Regex for "egg" as a whole word — avoids false positives on "eggplant"
  static final _eggWordRegex = RegExp(r'\beggs?\b');

  static bool _isNonVeg(String name) {
    final n = name.toLowerCase();
    // Skip egg check for eggplant / baingan / brinjal
    if (!n.contains('eggplant') &&
        !n.contains('baingan') &&
        !n.contains('brinjal')) {
      if (_eggWordRegex.hasMatch(n)) return true;
    }
    return _nonVegKeywords.any((kw) => n.contains(kw));
  }

  /// Build the fixed daily supplement entries based on profile settings.
  /// Uses generic names (no brand names).
  static List<DietFoodSuggestion> _buildDailySupplements(
      WeightLossProfileModel profile) {
    final supplements = <DietFoodSuggestion>[];
    final scoops = profile.proteinScoops;

    // Whey Protein — use "with water" for weight loss, "with milk" for gain
    final withMilk = profile.goalType == GoalType.gain;
    if (scoops == 1) {
      supplements.add(DietFoodSuggestion(
        name: withMilk
            ? 'Whey Protein (1 scoop with milk)'
            : 'Whey Protein (1 scoop with water)',
        servingSize: withMilk ? '1 scoop + 200ml milk' : '1 scoop (30g)',
        servings: 1,
        calories: withMilk ? 250 : 120,
        protein: withMilk ? 31 : 24,
        carbs: withMilk ? 13 : 3,
        fat: withMilk ? 5.5 : 1.5,
      ));
    } else if (scoops == 2) {
      supplements.add(DietFoodSuggestion(
        name: withMilk
            ? 'Whey Protein (2 scoops with milk)'
            : 'Whey Protein (2 scoops with water)',
        servingSize: withMilk ? '2 scoops + 300ml milk' : '2 scoops (60g)',
        servings: 1,
        calories: withMilk ? 430 : 240,
        protein: withMilk ? 58 : 48,
        carbs: withMilk ? 21 : 6,
        fat: withMilk ? 8 : 3,
      ));
    } else if (scoops >= 3) {
      supplements.add(DietFoodSuggestion(
        name: withMilk
            ? 'Whey Protein (3 scoops with milk)'
            : 'Whey Protein (3 scoops with water)',
        servingSize: withMilk ? '3 scoops + 400ml milk' : '3 scoops (90g)',
        servings: 1,
        calories: withMilk ? 610 : 360,
        protein: withMilk ? 85 : 72,
        carbs: withMilk ? 29 : 9,
        fat: withMilk ? 10.5 : 4.5,
      ));
    }

    // Creatine — only if user opted in
    if (profile.takesCreatine) {
      supplements.add(const DietFoodSuggestion(
        name: 'Creatine Monohydrate (1 scoop)',
        servingSize: '1 scoop (5g)',
        servings: 1,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      ));
    }

    // Mass Gainer — only if user opted in AND goal is weight gain
    if (profile.takesMassGainer && profile.goalType == GoalType.gain) {
      supplements.add(DietFoodSuggestion(
        name: withMilk
            ? 'Mass Gainer (1 scoop with milk)'
            : 'Mass Gainer (1 scoop with water)',
        servingSize: withMilk ? '1 scoop + 300ml milk' : '1 scoop (75g)',
        servings: 1,
        calories: withMilk ? 430 : 280,
        protein: withMilk ? 25 : 15,
        carbs: withMilk ? 65 : 50,
        fat: withMilk ? 7 : 2.5,
      ));
    }

    return supplements;
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
    // Veg mode includes 'Eggs & Dairy' category — egg items are filtered
    // out later via _isNonVeg so dairy items (paneer, curd) remain available
    final bfCats = isVegetarian
        ? const ['Breakfast', 'South Indian', 'Eggs & Dairy']
        : _breakfastCategories;
    final lnCats = isVegetarian
        ? const [
            'Dal & Lentils', 'Vegetables', 'Rice & Grains',
            'Roti & Bread',
          ]
        : _lunchCategories;
    final dnCats = isVegetarian
        ? const [
            'Vegetables', 'Dal & Lentils', 'Roti & Bread', 'South Indian',
          ]
        : _dinnerCategories;
    final skCats = isVegetarian
        ? const [
            'Fruits', 'Nuts & Seeds', 'Dry Fruits & Nuts',
            'Eggs & Dairy', 'Beverages',
          ]
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

    // Filter: remove supplements + unhealthy foods, keep only real healthy foods
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

    // Build daily supplement list (whey, creatine, mass gainer)
    final dailySupplements = _buildDailySupplements(profile);
    final supplementCalories =
        dailySupplements.fold<int>(0, (s, f) => s + f.calories.round());

    // The meal slot where supplements go
    final suppMealSlot = profile.wheyProteinMealSlot;

    // Healthy beverages — alternate green tea / black coffee per day
    const healthyBeverages = [
      DietFoodSuggestion(
        name: 'Green Tea',
        servingSize: '1 cup (240ml)',
        servings: 1,
        calories: 2,
        protein: 0,
        carbs: 0.5,
        fat: 0,
      ),
      DietFoodSuggestion(
        name: 'Black Coffee',
        servingSize: '1 cup (240ml)',
        servings: 1,
        calories: 5,
        protein: 0.3,
        carbs: 0,
        fat: 0,
      ),
    ];

    final rng = Random();
    final usedNames = <String>{}; // track across days to add variety

    final days = <DailyDietPlan>[];
    for (var d = 0; d < 7; d++) {
      final dayMeals = <DietMealPlan>[];
      int dayCaloriesSoFar = 0;

      // Count supplement calories toward daily total
      dayCaloriesSoFar += supplementCalories;

      // Pick healthy beverage for this day (alternate)
      final dailyBeverage = healthyBeverages[d % 2];

      for (final meal in MealType.values) {
        var mealBudget = (dailyCal * meal.calorieShare).round();

        // If this is the supplement slot, reduce budget by supplement calories
        final isSupplementSlot = meal == suppMealSlot;
        if (isSupplementSlot) {
          mealBudget -= supplementCalories;
          if (mealBudget < 0) mealBudget = 0;
        }

        // Add healthy beverage to morning snack slot
        final isBeverageSlot = meal == MealType.morningSnack;

        // Ensure we don't overshoot the daily calorie target
        final remainingDailyCal = dailyCal - dayCaloriesSoFar;
        if (mealBudget > remainingDailyCal) {
          mealBudget = remainingDailyCal.clamp(0, mealBudget);
        }

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
        }

        final mealFoods = _pickFoodsForMeal(
          pool: pool,
          calorieBudget: mealBudget,
          goal: goal,
          bmiCat: bmiCat,
          rng: rng,
          usedNames: usedNames,
          maxSupplements: 0,
          prioritizeProtein: true,
          prioritizeFiber: true,
        );

        // Build final food list for this meal
        final allFoods = <DietFoodSuggestion>[];
        if (isSupplementSlot) allFoods.addAll(dailySupplements);
        if (isBeverageSlot) allFoods.add(dailyBeverage);
        allFoods.addAll(mealFoods);

        // Track running calorie total
        for (final f in mealFoods) {
          dayCaloriesSoFar += f.calories.round();
        }

        dayMeals.add(DietMealPlan(
          mealType: meal,
          calorieBudget: (dailyCal * meal.calorieShare).round(),
          foods: allFoods,
        ));
      }

      // Calculate dynamic water goal for this day
      final dayWaterGoal = _calculateDailyWater(
        profile: profile,
        meals: dayMeals,
        supplements: dailySupplements,
      );

      days.add(DailyDietPlan(
        dayLabel: _dayNames[d],
        meals: dayMeals,
        waterGoalMl: dayWaterGoal,
      ));
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
            !_isSupplement(f.name) &&
            !_isUnhealthy(f.name) &&
            !_isOilyOriginal(f.name))
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
    bool prioritizeProtein = false,
    bool prioritizeFiber = false,
  }) {
    if (pool.isEmpty || calorieBudget <= 0) return [];

    // Separate supplements from real foods
    final realFoods = <CommonFoodItem>[];
    for (final f in pool) {
      if (!_isSupplement(f.name)) {
        realFoods.add(f);
      }
    }

    // Prefer foods not already used
    final fresh =
        realFoods.where((f) => !usedNames.contains(f.name)).toList();
    final candidates = fresh.isNotEmpty ? fresh : realFoods;

    // Score and sort candidates — prioritize protein & fiber when needed
    final scored = List.of(candidates);
    if (prioritizeProtein || prioritizeFiber) {
      scored.sort((a, b) {
        final calA = max(a.calories, 1.0);
        final calB = max(b.calories, 1.0);
        double scoreA = 0, scoreB = 0;
        if (prioritizeProtein) {
          scoreA += (a.protein / calA) * 3;
          scoreB += (b.protein / calB) * 3;
        }
        if (prioritizeFiber) {
          scoreA += (a.fiber / calA) * 2;
          scoreB += (b.fiber / calB) * 2;
        }
        return scoreB.compareTo(scoreA);
      });
      // Take top ~60% high-protein/fiber, shuffle for variety
      final splitAt = (scored.length * 0.6).ceil();
      final topItems = scored.sublist(0, min(splitAt, scored.length));
      topItems.shuffle(rng);
      final rest = scored.sublist(min(splitAt, scored.length));
      rest.shuffle(rng);
      scored
        ..clear()
        ..addAll(topItems)
        ..addAll(rest);
    } else {
      scored.shuffle(rng);
    }

    final picks = <DietFoodSuggestion>[];
    int remaining = calorieBudget;
    final targetItems = 3 + rng.nextInt(2); // 3-4 real foods

    // Fill with real foods — stay strictly within budget
    for (final food in scored) {
      if (picks.length >= targetItems) break;
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

  /// Calculate dynamic water goal for a single day based on profile + foods.
  /// Matches the app's formula: weight x 33 + activity boost + food boost.
  static int _calculateDailyWater({
    required WeightLossProfileModel profile,
    required List<DietMealPlan> meals,
    required List<DietFoodSuggestion> supplements,
  }) {
    // Base water: weight * 33
    int water = (profile.currentWeight * 33).round();

    // Activity level boost (same as GymState.activityWaterBoostMl)
    switch (profile.activityLevel) {
      case ActivityLevel.sedentary:
        break;
      case ActivityLevel.light:
        water += 200;
      case ActivityLevel.moderate:
        water += 400;
      case ActivityLevel.active:
        water += 600;
      case ActivityLevel.extreme:
        water += 800;
    }

    // Water boost from supplements (whey, creatine, mass gainer)
    for (final supp in supplements) {
      water += waterBoostForFood(supp.name);
    }

    // Water boost from food items in all meals
    for (final meal in meals) {
      for (final food in meal.foods) {
        // Skip supplements (already counted above)
        if (food.name.toLowerCase().contains('whey') ||
            food.name.toLowerCase().contains('creatine') ||
            food.name.toLowerCase().contains('mass gainer')) {
          continue;
        }
        water += waterBoostForFood(food.name);
      }
    }

    return water;
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
