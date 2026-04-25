import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/services/smart_reminder_service.dart';
import '../../data/gym_repository.dart';
import '../../data/water_boost_foods_data.dart';
import '../../domain/food_scan_model.dart';
import '../../domain/membership_model.dart';
import '../../domain/sleep_log_model.dart';
import '../../domain/tracked_food_model.dart';
import '../../domain/weight_loss_profile_model.dart';
import '../../domain/workout_log_model.dart';

class GymState {
  const GymState({
    this.activeMembership,
    this.attendanceMap = const {},
    this.presentCount = 0,
    this.absentCount = 0,
    this.presentDates = const [],
    this.absentDates = const [],
    this.waterMl = 0,
    this.dailyWaterGoalMl = 0,
    this.waterHistory = const {},
    this.waterGoalHistory = const {},
    this.stepsHistory = const {},
    this.stepsGoalHistory = const {},
    this.foodScans = const [],
    this.dailyCalories = 0,
    this.calorieHistory = const {},
    this.trackedFoods = const [],
    this.trackedFoodCalorieHistory = const {},
    this.calorieGoalHistory = const {},
    this.userHeight,
    this.userWeight,
    this.weightLossProfile,
    this.todayWorkouts = const [],
    this.todaySleep = const [],
    this.sleepHistory = const {},
    this.isLoading = false,
    this.error,
  });

  final MembershipModel? activeMembership;
  final Map<DateTime, bool> attendanceMap;
  final int presentCount;
  final int absentCount;
  final List<DateTime> presentDates;
  final List<DateTime> absentDates;
  final int waterMl;
  final int dailyWaterGoalMl;
  final Map<DateTime, int> waterHistory;
  final Map<DateTime, int> waterGoalHistory;
  final Map<DateTime, int> stepsHistory;
  final Map<DateTime, int> stepsGoalHistory;
  final List<FoodScanModel> foodScans;
  final double dailyCalories;
  final Map<DateTime, double> calorieHistory;
  final List<TrackedFoodModel> trackedFoods;
  final Map<DateTime, double> trackedFoodCalorieHistory;
  final Map<DateTime, double> calorieGoalHistory;
  final double? userHeight;
  final double? userWeight;
  final WeightLossProfileModel? weightLossProfile;
  final List<WorkoutLogModel> todayWorkouts;
  final List<SleepLogModel> todaySleep;
  final Map<DateTime, int> sleepHistory;
  final bool isLoading;
  final String? error;

  // ── Tracked food helpers ──
  double get trackedCalories =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalCalories);
  double get trackedProtein =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalProtein);
  double get trackedCarbs =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalCarbs);
  double get trackedFat =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalFat);
  double get trackedFiber =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalFiber);
  double get trackedSodium =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalSodium);
  double get trackedSugar =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalSugar);
  double get trackedCholesterol =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalCholesterol);
  double get trackedIron =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalIron);
  double get trackedCalcium =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalCalcium);
  double get trackedPotassium =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalPotassium);
  double get trackedVitaminA =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalVitaminA);
  double get trackedVitaminB12 =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalVitaminB12);
  double get trackedVitaminC =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalVitaminC);
  double get trackedVitaminD =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalVitaminD);
  double get trackedZinc =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalZinc);
  double get trackedMagnesium =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalMagnesium);
  double get trackedVitaminE =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalVitaminE);
  double get trackedVitaminK =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalVitaminK);
  double get trackedVitaminB6 =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalVitaminB6);
  double get trackedFolate =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalFolate);
  double get trackedPhosphorus =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalPhosphorus);
  double get trackedSelenium =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalSelenium);
  double get trackedManganese =>
      trackedFoods.fold<double>(0, (s, f) => s + f.totalManganese);

  // ── Water boost from tracked foods ──
  int get waterBoostMl =>
      trackedFoods.fold<int>(0, (sum, f) => sum + waterBoostForFood(f.name));

  /// Extra water needed based on activity level (active people sweat more).
  int get activityWaterBoostMl {
    final profile = weightLossProfile;
    if (profile == null) return 0;
    switch (profile.activityLevel) {
      case ActivityLevel.sedentary:
        return 0;
      case ActivityLevel.light:
        return 200;
      case ActivityLevel.moderate:
        return 400;
      case ActivityLevel.active:
        return 600;
      case ActivityLevel.extreme:
        return 800;
    }
  }

  int get effectiveWaterGoalMl =>
      dailyWaterGoalMl + waterBoostMl + activityWaterBoostMl;

  List<TrackedFoodModel> trackedFoodsForMeal(MealType meal) =>
      trackedFoods.where((f) => f.mealType == meal).toList();

  double trackedCaloriesForMeal(MealType meal) =>
      trackedFoodsForMeal(meal).fold<double>(0, (s, f) => s + f.totalCalories);

  // ── Workout helpers ──
  double get todayWorkoutCalories =>
      todayWorkouts.fold<double>(0, (s, w) => s + w.effectiveCalories);
  int get todayWorkoutMinutes =>
      todayWorkouts.fold<int>(0, (s, w) => s + w.durationMinutes);

  // ── Sleep helpers ──
  Duration get todaySleepDuration => todaySleep.isNotEmpty
      ? todaySleep.fold<Duration>(Duration.zero, (s, e) => s + e.duration)
      : Duration.zero;
  String get todaySleepFormatted {
    final d = todaySleepDuration;
    if (d == Duration.zero) return '0h';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  GymState copyWith({
    MembershipModel? activeMembership,
    bool clearMembership = false,
    Map<DateTime, bool>? attendanceMap,
    int? presentCount,
    int? absentCount,
    List<DateTime>? presentDates,
    List<DateTime>? absentDates,
    int? waterMl,
    int? dailyWaterGoalMl,
    Map<DateTime, int>? waterHistory,
    Map<DateTime, int>? waterGoalHistory,
    Map<DateTime, int>? stepsHistory,
    Map<DateTime, int>? stepsGoalHistory,
    List<FoodScanModel>? foodScans,
    double? dailyCalories,
    Map<DateTime, double>? calorieHistory,
    List<TrackedFoodModel>? trackedFoods,
    Map<DateTime, double>? trackedFoodCalorieHistory,
    Map<DateTime, double>? calorieGoalHistory,
    double? userHeight,
    bool clearHeight = false,
    double? userWeight,
    bool clearWeight = false,
    WeightLossProfileModel? weightLossProfile,
    bool clearWeightLossProfile = false,
    List<WorkoutLogModel>? todayWorkouts,
    List<SleepLogModel>? todaySleep,
    Map<DateTime, int>? sleepHistory,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GymState(
      activeMembership:
          clearMembership ? null : (activeMembership ?? this.activeMembership),
      attendanceMap: attendanceMap ?? this.attendanceMap,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      presentDates: presentDates ?? this.presentDates,
      absentDates: absentDates ?? this.absentDates,
      waterMl: waterMl ?? this.waterMl,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      waterHistory: waterHistory ?? this.waterHistory,
      waterGoalHistory: waterGoalHistory ?? this.waterGoalHistory,
      stepsHistory: stepsHistory ?? this.stepsHistory,
      stepsGoalHistory: stepsGoalHistory ?? this.stepsGoalHistory,
      foodScans: foodScans ?? this.foodScans,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      calorieHistory: calorieHistory ?? this.calorieHistory,
      trackedFoods: trackedFoods ?? this.trackedFoods,
      trackedFoodCalorieHistory:
          trackedFoodCalorieHistory ?? this.trackedFoodCalorieHistory,
      calorieGoalHistory: calorieGoalHistory ?? this.calorieGoalHistory,
      userHeight: clearHeight ? null : (userHeight ?? this.userHeight),
      userWeight: clearWeight ? null : (userWeight ?? this.userWeight),
      weightLossProfile: clearWeightLossProfile
          ? null
          : (weightLossProfile ?? this.weightLossProfile),
      todayWorkouts: todayWorkouts ?? this.todayWorkouts,
      todaySleep: todaySleep ?? this.todaySleep,
      sleepHistory: sleepHistory ?? this.sleepHistory,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GymCubit extends Cubit<GymState> {
  GymCubit({required GymRepository repository})
      : _repository = repository,
        super(const GymState());

  final GymRepository _repository;

  // Debounce Firestore writes for steps to avoid excessive writes.
  Timer? _stepsSaveDebounce;
  DateTime? _pendingStepsDate;
  int? _pendingSteps;
  int? _pendingGoal;

  GymRepository get repository => _repository;

  /// Saves today's water, steps, and calorie goals to Firestore AND updates
  /// the in-memory goal history maps so the report sees them immediately.
  void _saveTodaysGoals() {
    final today = DateTime.now();
    final norm = DateTime(today.year, today.month, today.day);

    final newWaterGoalHistory = Map<DateTime, int>.from(state.waterGoalHistory);
    final newStepsGoalHistory = Map<DateTime, int>.from(state.stepsGoalHistory);
    final newCalorieGoalHistory = Map<DateTime, double>.from(state.calorieGoalHistory);

    // Water goal (includes protein/food water boost)
    final waterGoal = state.effectiveWaterGoalMl;
    if (waterGoal > 0) {
      _repository.saveWaterGoal(today, waterGoal).ignore();
      newWaterGoalHistory[norm] = waterGoal;
    }

    // Steps goal (BMI-based) — save for today
    final h = state.userHeight;
    final w = state.userWeight;
    if (h != null && w != null) {
      final bmi = w / ((h / 100) * (h / 100));
      int stepsGoal;
      if (bmi < 18.5) {
        stepsGoal = 8000;
      } else if (bmi < 25) {
        stepsGoal = 10000;
      } else if (bmi < 30) {
        stepsGoal = 12000;
      } else {
        stepsGoal = 15000;
      }
      final todaySteps = state.stepsHistory[norm] ?? 0;
      _repository
          .saveStepsForDate(norm, todaySteps, goalSteps: stepsGoal)
          .ignore();
      newStepsGoalHistory[norm] = stepsGoal;
    }

    // Calorie goal from weight loss profile
    final calGoal = state.weightLossProfile?.dailyCalorieTarget;
    if (calGoal != null) {
      _repository.saveCalorieGoalForDate(today, calGoal).ignore();
      newCalorieGoalHistory[norm] = calGoal;
    }

    emit(state.copyWith(
      waterGoalHistory: newWaterGoalHistory,
      stepsGoalHistory: newStepsGoalHistory,
      calorieGoalHistory: newCalorieGoalHistory,
    ));
  }

  /// Backfill goalMl / goalSteps / goalCalories for old days that were
  /// recorded before the per-day goal feature was added. Uses the current
  /// goal as the best approximation and saves it to Firestore so it
  /// becomes permanent and won't change if the user later updates metrics.
  void _backfillMissingGoals() {
    final today = DateTime.now();
    final norm = DateTime(today.year, today.month, today.day);

    final newWaterGoalHistory =
        Map<DateTime, int>.from(state.waterGoalHistory);
    final newStepsGoalHistory =
        Map<DateTime, int>.from(state.stepsGoalHistory);
    final newCalorieGoalHistory =
        Map<DateTime, double>.from(state.calorieGoalHistory);
    bool changed = false;

    // Water: backfill days with intake but no stored goal
    final waterGoal = state.dailyWaterGoalMl; // base goal (weight*33)
    if (waterGoal > 0) {
      for (final date in state.waterHistory.keys) {
        if (date == norm) continue; // today is handled by _saveTodaysGoals
        if (!newWaterGoalHistory.containsKey(date)) {
          newWaterGoalHistory[date] = waterGoal;
          _repository.saveWaterGoal(date, waterGoal).ignore();
          changed = true;
        }
      }
    }

    // Steps: do NOT backfill — the user's BMI (and therefore goal) may have
    // been different on each historical day.  Only today's goal is set by
    // _saveTodaysGoals(); past goals are preserved as originally saved.

    // Calories: backfill days with tracked food but no stored goal
    final calGoal = state.weightLossProfile?.dailyCalorieTarget;
    if (calGoal != null) {
      for (final date in state.trackedFoodCalorieHistory.keys) {
        if (date == norm) continue;
        if (!newCalorieGoalHistory.containsKey(date)) {
          _repository.saveCalorieGoalForDate(date, calGoal).ignore();
          newCalorieGoalHistory[date] = calGoal;
          changed = true;
        }
      }
    }

    if (changed) {
      emit(state.copyWith(
        waterGoalHistory: newWaterGoalHistory,
        stepsGoalHistory: newStepsGoalHistory,
        calorieGoalHistory: newCalorieGoalHistory,
      ));
    }
  }

  Future<void> loadAll() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await Future.wait([
        loadMembership(),
        loadAttendance(),
        loadWaterIntake(),
        loadUserMetrics(),
        loadStepsHistory(),
        loadFoodScans(),
        loadWeightLossProfile(),
        loadTrackedFood(),
        loadTrackedFoodCalorieHistory(),
        loadTodayWorkouts(),
        loadTodaySleep(),
        loadSleepHistory(),
      ]);
      // One-time fix: remove incorrectly backfilled step goals for dates
      // before the BMI-based goal feature was introduced (April 6, 2026).
      // Those days should fall back to the default 10000.
      final settingsBox = Hive.box('app_settings');
      if (settingsBox.get('step_goals_pre_apr6_cleaned') != true) {
        await _repository.clearStepGoalsBefore(DateTime(2026, 4, 6));
        await settingsBox.put('step_goals_pre_apr6_cleaned', true);
        await loadStepsHistory();
      }

      emit(state.copyWith(isLoading: false));
      // Persist today's goals so they're locked for this day
      _saveTodaysGoals();
      // Backfill goals for old days that don't have them stored yet
      _backfillMissingGoals();
      // Schedule smart reminders after all data is loaded
      await SmartReminderService.scheduleAll(state, uid: _repository.uid);
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadMembership() async {
    try {
      final membership = await _repository.getActiveMembership();
      if (membership == null) {
        emit(state.copyWith(
          clearMembership: true,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          activeMembership: membership,
          clearError: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadAttendance() async {
    try {
      final map = await _repository.getAttendanceMap();
      final present = await _repository.getPresentCount();
      final absent = await _repository.getAbsentCount();
      final presentDates = await _repository.getPresentDates();
      final absentDates = await _repository.getAbsentDates();
      emit(state.copyWith(
        attendanceMap: map,
        presentCount: present,
        absentCount: absent,
        presentDates: presentDates,
        absentDates: absentDates,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveMembership(MembershipModel membership) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.saveMembership(membership);
      await loadMembership();
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> markAttendance(DateTime date, bool isPresent) async {
    try {
      await _repository.markAttendance(date, isPresent);
      await loadAttendance();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteAttendance(DateTime date) async {
    try {
      await _repository.deleteAttendance(date);
      await loadAttendance();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteAllAttendance() async {
    try {
      await _repository.deleteAllAttendance();
      await loadAttendance();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadWaterIntake() async {
    try {
      final ml = await _repository.getWaterIntakeForDate(DateTime.now());
      final (history, goalHistory) = await _repository.getWaterIntakeAndGoalHistory();
      emit(state.copyWith(
        waterMl: ml,
        waterHistory: history,
        waterGoalHistory: goalHistory,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> addWater(int ml) async {
    try {
      await _repository.addWaterMl(DateTime.now(), ml,
          goalMl: state.effectiveWaterGoalMl);
      await loadWaterIntake();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> removeWater(int ml) async {
    try {
      await _repository.removeWaterMl(DateTime.now(), ml,
          goalMl: state.effectiveWaterGoalMl);
      await loadWaterIntake();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> resetWaterIntake() async {
    try {
      await _repository.resetWaterIntake(DateTime.now(),
          goalMl: state.effectiveWaterGoalMl);
      await loadWaterIntake();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadUserMetrics() async {
    try {
      final metrics = await _repository.getUserMetrics();
      final height = metrics['height'];
      final weight = metrics['weight'];
      final goalMl = weight != null ? (weight * 33).round() : 0;
      emit(state.copyWith(
        userHeight: height,
        userWeight: weight,
        dailyWaterGoalMl: goalMl,
        clearHeight: height == null,
        clearWeight: weight == null,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveUserMetrics({
    required double height,
    required double weight,
  }) async {
    try {
      await _repository.saveUserMetrics(height: height, weight: weight);
      await loadUserMetrics();
      // Re-save today's goals with the new weight/BMI
      _saveTodaysGoals();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadStepsHistory() async {
    try {
      final (history, goalHistory) = await _repository.getStepsAndGoalHistory();
      emit(state.copyWith(
        stepsHistory: history,
        stepsGoalHistory: goalHistory,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveSteps(DateTime date, int steps, {int? goalSteps}) async {
    try {
      final normalized = DateTime(date.year, date.month, date.day);

      // Skip if the value hasn't increased (avoid duplicate writes)
      final current = state.stepsHistory[normalized] ?? 0;
      if (steps <= current && goalSteps == null) return;

      // Update in-memory state immediately so the UI stays responsive
      final newHistory = Map<DateTime, int>.from(state.stepsHistory);
      newHistory[normalized] = steps;
      final newGoalHistory = Map<DateTime, int>.from(state.stepsGoalHistory);
      if (goalSteps != null) newGoalHistory[normalized] = goalSteps;
      emit(state.copyWith(stepsHistory: newHistory, stepsGoalHistory: newGoalHistory));

      // Debounce Firestore write — at most once every 15 seconds
      _pendingStepsDate = normalized;
      _pendingSteps = steps;
      if (goalSteps != null) _pendingGoal = goalSteps;
      _stepsSaveDebounce?.cancel();
      _stepsSaveDebounce = Timer(const Duration(seconds: 15), () {
        _flushPendingSteps();
      });
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Flush any pending step data to Firestore immediately.
  Future<void> _flushPendingSteps() async {
    final date = _pendingStepsDate;
    final steps = _pendingSteps;
    if (date == null || steps == null) return;
    final goal = _pendingGoal;
    _pendingStepsDate = null;
    _pendingSteps = null;
    _pendingGoal = null;
    try {
      await _repository.saveStepsForDate(date, steps, goalSteps: goal);
    } catch (e) {
      // Silently fail — next write will include the latest value
    }
  }

  // ── Food Scans ──

  Future<void> loadFoodScans() async {
    try {
      final scans = await _repository.getFoodScansForDate(DateTime.now());
      final calories = await _repository.getDailyCalories(DateTime.now());
      emit(state.copyWith(foodScans: scans, dailyCalories: calories));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveFoodScan(FoodScanModel scan) async {
    try {
      await _repository.saveFoodScan(scan);
      await loadFoodScans();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteFoodScan(String id) async {
    try {
      await _repository.deleteFoodScan(id);
      await loadFoodScans();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // ── Weight Loss Profile ──

  Future<void> loadWeightLossProfile() async {
    try {
      final profile = await _repository.getWeightLossProfile();
      if (profile == null) {
        emit(state.copyWith(clearWeightLossProfile: true));
      } else {
        emit(state.copyWith(weightLossProfile: profile));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveWeightLossProfile(WeightLossProfileModel profile) async {
    try {
      await _repository.saveWeightLossProfile(profile);
      // Sync height/weight from the profile to user metrics so BMI-based
      // step goals and water goals update immediately.
      await _repository.saveUserMetrics(
        height: profile.heightCm,
        weight: profile.currentWeight,
      );
      emit(state.copyWith(
        weightLossProfile: profile,
        userHeight: profile.heightCm,
        userWeight: profile.currentWeight,
        dailyWaterGoalMl: (profile.currentWeight * 33).round(),
      ));
      // Re-save today's goals with the new profile + metrics
      _saveTodaysGoals();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteWeightLossProfile() async {
    try {
      await _repository.deleteWeightLossProfile();
      emit(state.copyWith(clearWeightLossProfile: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // ── Tracked Food ──

  Future<void> loadTrackedFood() async {
    try {
      final foods = await _repository.getTrackedFoodForDate(DateTime.now());
      emit(state.copyWith(trackedFoods: foods));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveTrackedFood(TrackedFoodModel food) async {
    try {
      await _repository.saveTrackedFood(food);
      await Future.wait([loadTrackedFood(), loadTrackedFoodCalorieHistory()]);
      // Update today's goals in Firestore + state (food changes affect water boost)
      _saveTodaysGoals();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteTrackedFood(String id) async {
    try {
      await _repository.deleteTrackedFood(id);
      await Future.wait([loadTrackedFood(), loadTrackedFoodCalorieHistory()]);
      // Update today's goals in Firestore + state (food changes affect water boost)
      _saveTodaysGoals();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadTrackedFoodCalorieHistory() async {
    try {
      final history = await _repository.getTrackedFoodCalorieHistory();
      // Load calorie goal history separately so a failure doesn't break food data
      Map<DateTime, double> goalHistory = {};
      try {
        goalHistory = await _repository.getCalorieGoalHistory();
      } catch (_) {}
      emit(state.copyWith(
        trackedFoodCalorieHistory: history,
        calorieGoalHistory: goalHistory,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadCalorieHistory() async {
    try {
      final history = await _repository.getCalorieHistory();
      emit(state.copyWith(calorieHistory: history));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // ── Workout Logs ──

  Future<void> loadTodayWorkouts() async {
    try {
      final workouts = await _repository.getWorkoutsForDate(DateTime.now());
      emit(state.copyWith(todayWorkouts: workouts));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveWorkoutLog(WorkoutLogModel workout) async {
    await _repository.saveWorkoutLog(workout);
    await loadTodayWorkouts();
  }

  Future<void> deleteWorkoutLog(String id) async {
    try {
      await _repository.deleteWorkoutLog(id);
      await loadTodayWorkouts();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // ── Sleep Logs ──

  Future<void> loadTodaySleep() async {
    try {
      final sleep = await _repository.getSleepForDate(DateTime.now());
      emit(state.copyWith(todaySleep: sleep));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveSleepLog(SleepLogModel sleep) async {
    await _repository.saveSleepLog(sleep);
    await Future.wait([loadTodaySleep(), loadSleepHistory()]);
  }

  Future<void> deleteSleepLog(String id) async {
    try {
      await _repository.deleteSleepLog(id);
      await Future.wait([loadTodaySleep(), loadSleepHistory()]);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadSleepHistory() async {
    try {
      final history = await _repository.getSleepHistory();
      emit(state.copyWith(sleepHistory: history));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _stepsSaveDebounce?.cancel();
    _flushPendingSteps();
    return super.close();
  }
}
