import 'package:flutter_bloc/flutter_bloc.dart';

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
    this.stepsHistory = const {},
    this.foodScans = const [],
    this.dailyCalories = 0,
    this.calorieHistory = const {},
    this.trackedFoods = const [],
    this.trackedFoodCalorieHistory = const {},
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
  final Map<DateTime, int> stepsHistory;
  final List<FoodScanModel> foodScans;
  final double dailyCalories;
  final Map<DateTime, double> calorieHistory;
  final List<TrackedFoodModel> trackedFoods;
  final Map<DateTime, double> trackedFoodCalorieHistory;
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
  int get effectiveWaterGoalMl => dailyWaterGoalMl + waterBoostMl;

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
      ? todaySleep.first.duration
      : Duration.zero;
  String get todaySleepFormatted => todaySleep.isNotEmpty
      ? todaySleep.first.durationFormatted
      : '0h';

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
    Map<DateTime, int>? stepsHistory,
    List<FoodScanModel>? foodScans,
    double? dailyCalories,
    Map<DateTime, double>? calorieHistory,
    List<TrackedFoodModel>? trackedFoods,
    Map<DateTime, double>? trackedFoodCalorieHistory,
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
      stepsHistory: stepsHistory ?? this.stepsHistory,
      foodScans: foodScans ?? this.foodScans,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      calorieHistory: calorieHistory ?? this.calorieHistory,
      trackedFoods: trackedFoods ?? this.trackedFoods,
      trackedFoodCalorieHistory:
          trackedFoodCalorieHistory ?? this.trackedFoodCalorieHistory,
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

  GymRepository get repository => _repository;

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
      emit(state.copyWith(isLoading: false));
      // Schedule smart reminders after all data is loaded
      await SmartReminderService.scheduleAll(state);
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
      final history = await _repository.getWaterIntakeHistory();
      emit(state.copyWith(waterMl: ml, waterHistory: history));
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
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadStepsHistory() async {
    try {
      final history = await _repository.getStepsHistory();
      emit(state.copyWith(stepsHistory: history));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveSteps(DateTime date, int steps) async {
    try {
      final normalized = DateTime(date.year, date.month, date.day);
      await _repository.saveStepsForDate(normalized, steps);
      final newHistory = Map<DateTime, int>.from(state.stepsHistory);
      newHistory[normalized] = steps;
      emit(state.copyWith(stepsHistory: newHistory));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
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
      emit(state.copyWith(weightLossProfile: profile));
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
      // Update water goal in Firestore (food changes affect water boost)
      _repository
          .saveWaterGoal(DateTime.now(), state.effectiveWaterGoalMl)
          .ignore();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteTrackedFood(String id) async {
    try {
      await _repository.deleteTrackedFood(id);
      await Future.wait([loadTrackedFood(), loadTrackedFoodCalorieHistory()]);
      // Update water goal in Firestore (food changes affect water boost)
      _repository
          .saveWaterGoal(DateTime.now(), state.effectiveWaterGoalMl)
          .ignore();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadTrackedFoodCalorieHistory() async {
    try {
      final history = await _repository.getTrackedFoodCalorieHistory();
      emit(state.copyWith(trackedFoodCalorieHistory: history));
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
}
