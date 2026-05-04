import 'package:flutter/material.dart';

/// Central repository of all GlobalKeys used by coach marks.
/// Static keys survive widget rebuilds and can be referenced from
/// both the screen widgets and the coach-mark definition files.
class CoachMarkKeys {
  CoachMarkKeys._();

  // ── Home ──────────────────────────────────────────────────────────────
  static final homeMenu = GlobalKey(debugLabel: 'cm_home_menu');
  static final homeProfile = GlobalKey(debugLabel: 'cm_home_profile');
  static final homeGrid = GlobalKey(debugLabel: 'cm_home_grid');
  static final homeReplayTutorial = GlobalKey(debugLabel: 'cm_home_replay');

  // ── Home Grid Items (individual) ────────────────────────────────────
  static final homeTodo = GlobalKey(debugLabel: 'cm_home_todo');
  static final homePasswords = GlobalKey(debugLabel: 'cm_home_passwords');
  static final homeFitness = GlobalKey(debugLabel: 'cm_home_fitness');
  static final homeHabits = GlobalKey(debugLabel: 'cm_home_habits');
  static final homeScanner = GlobalKey(debugLabel: 'cm_home_scanner');
  static final homeQr = GlobalKey(debugLabel: 'cm_home_qr');
  static final homeCalculator = GlobalKey(debugLabel: 'cm_home_calculator');
  static final homeTranslator = GlobalKey(debugLabel: 'cm_home_translator');
  static final homePdf = GlobalKey(debugLabel: 'cm_home_pdf');

  // ── Todo ──────────────────────────────────────────────────────────────
  static final todoFilter = GlobalKey(debugLabel: 'cm_todo_filter');
  static final todoFab = GlobalKey(debugLabel: 'cm_todo_fab');
  static final todoShared = GlobalKey(debugLabel: 'cm_todo_shared');
  static final todoReports = GlobalKey(debugLabel: 'cm_todo_reports');

  // ── Passwords ─────────────────────────────────────────────────────────
  static final passwordFab = GlobalKey(debugLabel: 'cm_password_fab');
  static final passwordSearch = GlobalKey(debugLabel: 'cm_password_search');

  // ── Gym ───────────────────────────────────────────────────────────────
  static final gymTabBar = GlobalKey(debugLabel: 'cm_gym_tab_bar');

  // ── Steps ─────────────────────────────────────────────────────────────
  static final stepsRings = GlobalKey(debugLabel: 'cm_steps_rings');
  static final stepsStats = GlobalKey(debugLabel: 'cm_steps_stats');
  static final stepsBattery = GlobalKey(debugLabel: 'cm_steps_battery');

  // ── Food Tracking ─────────────────────────────────────────────────────
  static final foodSummary = GlobalKey(debugLabel: 'cm_food_summary');
  static final foodAddButton = GlobalKey(debugLabel: 'cm_food_add_button');
  static final foodGrid = GlobalKey(debugLabel: 'cm_food_grid');

  // ── Food Grid Items (individual) ────────────────────────────────────
  static final foodTrackFood = GlobalKey(debugLabel: 'cm_food_track_food');
  static final foodWorkout = GlobalKey(debugLabel: 'cm_food_workout');
  static final foodSleep = GlobalKey(debugLabel: 'cm_food_sleep');
  static final foodRecipes = GlobalKey(debugLabel: 'cm_food_recipes');
  static final foodWeightPlan = GlobalKey(debugLabel: 'cm_food_weight_plan');
  static final foodTips = GlobalKey(debugLabel: 'cm_food_tips');
  static final foodFoodInfo = GlobalKey(debugLabel: 'cm_food_food_info');

  // ── Habits ────────────────────────────────────────────────────────────
  static final habitFilter = GlobalKey(debugLabel: 'cm_habit_filter');
  static final habitArchive = GlobalKey(debugLabel: 'cm_habit_archive');
  static final habitDateNav = GlobalKey(debugLabel: 'cm_habit_date_nav');
  static final habitAddFab = GlobalKey(debugLabel: 'cm_habit_add_fab');
  static final habitCounter = GlobalKey(debugLabel: 'cm_habit_counter');

  // ── Scanner ───────────────────────────────────────────────────────────
  static final scannerFab = GlobalKey(debugLabel: 'cm_scanner_fab');
  static final scannerSearch = GlobalKey(debugLabel: 'cm_scanner_search');

  // ── QR Scanner ────────────────────────────────────────────────────────
  static final qrTabBar = GlobalKey(debugLabel: 'cm_qr_tab_bar');
  static final qrHistory = GlobalKey(debugLabel: 'cm_qr_history');

  // ── Calculator ────────────────────────────────────────────────────────
  static final calcSimple = GlobalKey(debugLabel: 'cm_calc_simple');
  static final calcScientific = GlobalKey(debugLabel: 'cm_calc_scientific');
  static final calcConverter = GlobalKey(debugLabel: 'cm_calc_converter');

  // ── Translator ────────────────────────────────────────────────────────
  static final transVoice = GlobalKey(debugLabel: 'cm_trans_voice');
  static final transConversation = GlobalKey(debugLabel: 'cm_trans_conversation');

  // ── PDF Reader ────────────────────────────────────────────────────────
  static final pdfImport = GlobalKey(debugLabel: 'cm_pdf_import');
  static final pdfSearch = GlobalKey(debugLabel: 'cm_pdf_search');

  // ── Gym Home ────────────────────────────────────────────────────────
  static final gymQuickAccess = GlobalKey(debugLabel: 'cm_gym_quick_access');

  // ── Gym Home Stats (individual) ─────────────────────────────────────
  static final gymStatPresent = GlobalKey(debugLabel: 'cm_gym_stat_present');
  static final gymStatAbsent = GlobalKey(debugLabel: 'cm_gym_stat_absent');
  static final gymStatWater = GlobalKey(debugLabel: 'cm_gym_stat_water');
  static final gymStatSteps = GlobalKey(debugLabel: 'cm_gym_stat_steps');
  static final gymStatFoodCal = GlobalKey(debugLabel: 'cm_gym_stat_food_cal');
  static final gymStatSleep = GlobalKey(debugLabel: 'cm_gym_stat_sleep');
  static final gymStatStepKcal = GlobalKey(debugLabel: 'cm_gym_stat_step_kcal');
  static final gymStatWorkoutKcal = GlobalKey(debugLabel: 'cm_gym_stat_workout_kcal');
  static final gymStatTotalBurnt = GlobalKey(debugLabel: 'cm_gym_stat_total_burnt');

  // ── Gym Home Quick Access (individual) ──────────────────────────────
  static final gymExercises = GlobalKey(debugLabel: 'cm_gym_exercises');
  static final gymReminders = GlobalKey(debugLabel: 'cm_gym_reminders');
  static final gymMedicine = GlobalKey(debugLabel: 'cm_gym_medicine');
  static final gymWeightPlan = GlobalKey(debugLabel: 'cm_gym_weight_plan');

  // ── Water Intake ────────────────────────────────────────────────────
  static final waterBottle = GlobalKey(debugLabel: 'cm_water_bottle');
  static final waterAddBtn = GlobalKey(debugLabel: 'cm_water_add_btn');

  // ── Exercises ───────────────────────────────────────────────────────
  static final exerciseCategories = GlobalKey(debugLabel: 'cm_exercise_categories');

  // ── Weight Plan ─────────────────────────────────────────────────────
  static final weightPlanSetup = GlobalKey(debugLabel: 'cm_weight_plan_setup');

  // ── Medicine ────────────────────────────────────────────────────────
  static final medicineFab = GlobalKey(debugLabel: 'cm_medicine_fab');

  // ── Reminders ───────────────────────────────────────────────────────
  static final remindersListView = GlobalKey(debugLabel: 'cm_reminders_list');

  // ── Add Task (inner screen) ───────────────────────────────────────
  static final addTaskTitle = GlobalKey(debugLabel: 'cm_add_task_title');
  static final addTaskDate = GlobalKey(debugLabel: 'cm_add_task_date');
  static final addTaskReminder = GlobalKey(debugLabel: 'cm_add_task_reminder');
  static final addTaskStatus = GlobalKey(debugLabel: 'cm_add_task_status');
  static final addTaskSave = GlobalKey(debugLabel: 'cm_add_task_save');

  // ── Attendance (inner screen) ─────────────────────────────────────
  static final attendanceCalendar = GlobalKey(debugLabel: 'cm_attendance_cal');
  static final attendanceMarkBtn = GlobalKey(debugLabel: 'cm_attendance_mark');

  // ── Gym Home Stats ────────────────────────────────────────────────
  static final gymHomeStats = GlobalKey(debugLabel: 'cm_gym_home_stats');

  // ── Log Workout (inner screen) ────────────────────────────────────
  static final workoutSearch = GlobalKey(debugLabel: 'cm_workout_search');

  // ── Log Sleep (inner screen) ──────────────────────────────────────
  static final sleepTimePickers = GlobalKey(debugLabel: 'cm_sleep_times');
  static final sleepQuality = GlobalKey(debugLabel: 'cm_sleep_quality');
  static final sleepSaveBtn = GlobalKey(debugLabel: 'cm_sleep_save');

  // ── Food Search (inner screen) ────────────────────────────────────
  static final foodSearchBar = GlobalKey(debugLabel: 'cm_food_search_bar');

  // ── Create Food (inner screen) ────────────────────────────────────
  static final createFoodForm = GlobalKey(debugLabel: 'cm_create_food_form');

  // ── Food Explorer (inner screen) ──────────────────────────────────
  static final foodExplorerSearch = GlobalKey(debugLabel: 'cm_food_explorer');

  // ── Meal Reminder (inner screen) ──────────────────────────────────
  static final mealReminderMaster = GlobalKey(debugLabel: 'cm_meal_rem_master');

  // ── Water Reminder (inner screen) ─────────────────────────────────
  static final waterReminderMaster = GlobalKey(debugLabel: 'cm_water_rem_master');

  // ── Weight Dashboard (inner screen) ───────────────────────────────
  static final weightDashboardBmi = GlobalKey(debugLabel: 'cm_weight_bmi');
  static final weightDashboardCalories = GlobalKey(debugLabel: 'cm_weight_cal');
  static final weightDashboardMacros = GlobalKey(debugLabel: 'cm_weight_macros');
  static final weightDashboardExport = GlobalKey(debugLabel: 'cm_weight_export');

  // ── Recipes (inner screen) ──────────────────────────────────────
  static final recipesSearch = GlobalKey(debugLabel: 'cm_recipes_search');
  static final recipesFilters = GlobalKey(debugLabel: 'cm_recipes_filters');

  // ── Track Food Inner (inner screen) ───────────────────────────
  static final trackFoodCalCard = GlobalKey(debugLabel: 'cm_track_food_cal');

  // ── Inner Recipes (Food tab recipes, inner screen) ────────────
  static final innerRecipesSearch = GlobalKey(debugLabel: 'cm_inner_recipes_search');
  static final innerRecipesFilters = GlobalKey(debugLabel: 'cm_inner_recipes_filters');
}
