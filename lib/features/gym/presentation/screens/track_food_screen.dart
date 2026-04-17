import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';

import '../../data/food_database_service.dart';
import '../../data/gemini_food_service.dart';
import '../../domain/food_scan_model.dart';
import '../../domain/recipe_model.dart';
import '../../domain/tracked_food_model.dart';
import '../../domain/weight_loss_profile_model.dart';
import '../providers/gym_provider.dart';
import '../widgets/food_scan_result_sheet.dart';
import '../widgets/recipe_detail_sheet.dart';
import '../widgets/voice_food_result_sheet.dart';
import 'food_explorer_screen.dart';
import 'food_search_screen.dart';
import 'log_sleep_screen.dart';
import 'log_workout_screen.dart';
import 'weight_loss_screen.dart';
import 'weight_loss_tips_screen.dart';

class TrackFoodScreen extends StatefulWidget {
  const TrackFoodScreen({super.key});

  @override
  State<TrackFoodScreen> createState() => _TrackFoodScreenState();
}

class _TrackFoodScreenState extends State<TrackFoodScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<GymCubit>();
    cubit.loadTrackedFood();
    cubit.loadTodayWorkouts();
    cubit.loadTodaySleep();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GymCubit, GymState>(
      builder: (context, state) {
        final profile = state.weightLossProfile;
        if (profile == null) {
          return _SetupForm(
            initialWeight: state.userWeight,
            initialHeight:
                state.userHeight != null ? state.userHeight! * 100 : null,
          );
        }
        return _TrackerView(profile: profile, state: state);
      },
    );
  }
}

// ─── Setup Form ─────────────────────────────────────────────────────────────

class _SetupForm extends StatefulWidget {
  const _SetupForm({this.initialWeight, this.initialHeight});
  final double? initialWeight;
  final double? initialHeight;

  @override
  State<_SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends State<_SetupForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _currentWeightCtrl;
  late final TextEditingController _targetWeightCtrl;
  Gender _gender = Gender.male;
  GoalType _goalType = GoalType.lose;
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  double _weeklyGoal = 0.5;

  @override
  void initState() {
    super.initState();
    _ageCtrl = TextEditingController();
    _heightCtrl = TextEditingController(
      text: widget.initialHeight?.toStringAsFixed(0) ?? '',
    );
    _currentWeightCtrl = TextEditingController(
      text: widget.initialWeight?.toStringAsFixed(1) ?? '',
    );
    _targetWeightCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  void _showActivityPicker() {
    showDialog(
      context: context,
      builder: (_) => _SearchablePickerDialog<ActivityLevel>(
        title: 'Activity Level',
        items: ActivityLevel.values,
        selectedItem: _activityLevel,
        labelBuilder: (a) => a.label,
        subtitleBuilder: (a) => a.description,
        onSelected: (a) => setState(() => _activityLevel = a),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final currentW = double.parse(_currentWeightCtrl.text.trim());
    final targetW = _goalType == GoalType.maintain
        ? currentW
        : double.parse(_targetWeightCtrl.text.trim());
    final profile = WeightLossProfileModel(
      age: int.parse(_ageCtrl.text.trim()),
      gender: _gender,
      goalType: _goalType,
      activityLevel: _activityLevel,
      currentWeight: currentW,
      targetWeight: targetW,
      heightCm: double.parse(_heightCtrl.text.trim()),
      weeklyGoalKg: _goalType == GoalType.maintain ? 0 : _weeklyGoal,
    );
    context.read<GymCubit>().saveWeightLossProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Up Your Plan',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your details to get personalized calorie and macro targets.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Goal Type
            Text('Your Goal', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<GoalType>(
              segments: GoalType.values
                  .map((g) => ButtonSegment(
                        value: g,
                        label: Text(g == GoalType.lose
                            ? 'Lose'
                            : g == GoalType.gain
                                ? 'Gain'
                                : 'Maintain'),
                      ))
                  .toList(),
              selected: {_goalType},
              onSelectionChanged: (s) =>
                  setState(() => _goalType = s.first),
            ),
            const SizedBox(height: 4),
            Text(
              _goalType.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                suffixText: 'years',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 10 || n > 100) return 'Enter valid age';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Gender', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Gender>(
              segments: const [
                ButtonSegment(value: Gender.male, label: Text('Male')),
                ButtonSegment(value: Gender.female, label: Text('Female')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showActivityPicker(),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Activity Level',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(_activityLevel.label),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Height',
                suffixText: 'cm',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n < 100 || n > 250) {
                  return 'Enter valid height';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentWeightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Current Weight',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n < 30 || n > 300) {
                  return 'Enter valid weight';
                }
                return null;
              },
            ),
            if (_goalType != GoalType.maintain) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetWeightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target Weight',
                  suffixText: 'kg',
                  border: const OutlineInputBorder(),
                  helperText: _goalType == GoalType.gain
                      ? 'Should be higher than current weight'
                      : 'Should be lower than current weight',
                ),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (n == null || n < 30 || n > 300) {
                    return 'Enter valid target weight';
                  }
                  final current =
                      double.tryParse(_currentWeightCtrl.text.trim());
                  if (current != null) {
                    if (_goalType == GoalType.lose && n >= current) {
                      return 'Target must be less than current weight ($current kg)';
                    }
                    if (_goalType == GoalType.gain && n <= current) {
                      return 'Target must be more than current weight ($current kg)';
                    }
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            if (_goalType != GoalType.maintain) ...[
              Text(
                _goalType == GoalType.gain
                    ? 'Weekly Gain Goal'
                    : 'Weekly Loss Goal',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [0.25, 0.5, 0.75, 1.0].map((goal) {
                  final selected = _weeklyGoal == goal;
                  return ChoiceChip(
                    label: Text('$goal kg/week'),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _weeklyGoal = goal),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate My Plan'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Tracker View (2x2 Grid Hub) ────────────────────────────────────────────

class _TrackerView extends StatelessWidget {
  const _TrackerView({required this.profile, required this.state});
  final WeightLossProfileModel profile;
  final GymState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consumed = state.trackedCalories;
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    final todaySteps = state.stepsHistory[todayKey] ?? 0;
    final weight = state.userWeight ?? 70.0;
    final stepCalories = (todaySteps * 0.04 * weight / 70).round();
    final workoutCalories = state.todayWorkoutCalories;
    final burnt = stepCalories + workoutCalories;
    final target = profile.dailyCalorieTarget;
    final net = consumed - burnt;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final remaining = target - consumed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: consumed > target
                            ? Colors.red
                            : theme.colorScheme.primary,
                      ),
                      Center(
                        child: Text(
                          '${consumed.round()}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Calories",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${consumed.round()} / ${target.round()} kcal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remaining >= 0
                            ? '${remaining.round()} kcal remaining'
                            : '${(-remaining).round()} kcal over',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: remaining >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (burnt > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Net: ${net.round()} kcal (${consumed.round()} eaten - ${burnt.round()} burnt)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Macronutrient + micronutrient summary
        if (state.trackedFoods.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MacroBar(
                          label: 'Protein',
                          consumed: state.trackedProtein,
                          target: profile.proteinGrams,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroBar(
                          label: 'Carbs',
                          consumed: state.trackedCarbs,
                          target: profile.carbsGrams,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroBar(
                          label: 'Fat',
                          consumed: state.trackedFat,
                          target: profile.fatGrams,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                  // ── Micronutrients (collapsible) ──
                  _CollapsibleSection(
                    icon: Icons.science_outlined,
                    title: 'Micronutrients',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MicroBar(
                              label: 'Fibre',
                              consumed: state.trackedFiber,
                              target: profile.fiberRDA,
                              unit: 'g',
                              color: Colors.brown,
                              icon: Icons.grass,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MicroBar(
                              label: 'Sugar',
                              consumed: state.trackedSugar,
                              target: profile.sugarLimit,
                              unit: 'g',
                              color: Colors.pink,
                              icon: Icons.cake_outlined,
                              isLimit: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MicroBar(
                              label: 'Iron',
                              consumed: state.trackedIron,
                              target: profile.ironRDA,
                              unit: 'mg',
                              color: Colors.red.shade700,
                              icon: Icons.bloodtype_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MicroBar(
                              label: 'Calcium',
                              consumed: state.trackedCalcium,
                              target: profile.calciumRDA,
                              unit: 'mg',
                              color: Colors.teal,
                              icon: Icons.accessibility_new,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MicroBar(
                              label: 'Potassium',
                              consumed: state.trackedPotassium,
                              target: profile.potassiumRDA,
                              unit: 'mg',
                              color: Colors.purple,
                              icon: Icons.bolt,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MicroBar(
                              label: 'Sodium',
                              consumed: state.trackedSodium,
                              target: profile.sodiumLimit,
                              unit: 'mg',
                              color: Colors.orange,
                              icon: Icons.water_drop_outlined,
                              isLimit: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MicroBar(
                              label: 'Zinc',
                              consumed: state.trackedZinc,
                              target: profile.zincRDA,
                              unit: 'mg',
                              color: Colors.blueGrey,
                              icon: Icons.shield_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MicroBar(
                              label: 'Magnesium',
                              consumed: state.trackedMagnesium,
                              target: profile.magnesiumRDA,
                              unit: 'mg',
                              color: Colors.indigo,
                              icon: Icons.electric_bolt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _MicroBar(
                        label: 'Cholesterol',
                        consumed: state.trackedCholesterol,
                        target: profile.cholesterolLimit,
                        unit: 'mg',
                        color: Colors.amber.shade800,
                        icon: Icons.favorite_outline,
                        isLimit: true,
                      ),
                    ],
                  ),
                  // ── Vitamins (collapsible) ──
                  _CollapsibleSection(
                    icon: Icons.medication_outlined,
                    title: 'Vitamins',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MicroBar(
                              label: 'Vitamin A',
                              consumed: state.trackedVitaminA,
                              target: profile.vitaminARDA,
                              unit: 'mcg',
                              color: Colors.deepOrange,
                              icon: Icons.visibility_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MicroBar(
                              label: 'Vitamin C',
                              consumed: state.trackedVitaminC,
                              target: profile.vitaminCRDA,
                              unit: 'mg',
                              color: Colors.amber,
                              icon: Icons.local_florist_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MicroBar(
                              label: 'Vitamin D',
                              consumed: state.trackedVitaminD,
                              target: profile.vitaminDRDA,
                              unit: 'mcg',
                              color: Colors.lightBlue,
                              icon: Icons.wb_sunny_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MicroBar(
                              label: 'Vitamin B12',
                              consumed: state.trackedVitaminB12,
                              target: profile.vitaminB12RDA,
                              unit: 'mcg',
                              color: Colors.red.shade400,
                              icon: Icons.psychology_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MicroBar(
                              label: 'Vitamin E',
                              consumed: state.trackedVitaminE,
                              target: profile.vitaminERDA,
                              unit: 'mg',
                              color: Colors.green.shade600,
                              icon: Icons.spa_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MicroBar(
                              label: 'Vitamin K',
                              consumed: state.trackedVitaminK,
                              target: profile.vitaminKRDA,
                              unit: 'mcg',
                              color: Colors.green.shade800,
                              icon: Icons.eco_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MicroBar(
                              label: 'Vitamin B6',
                              consumed: state.trackedVitaminB6,
                              target: profile.vitaminB6RDA,
                              unit: 'mg',
                              color: Colors.cyan,
                              icon: Icons.energy_savings_leaf_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MicroBar(
                              label: 'Folate',
                              consumed: state.trackedFolate,
                              target: profile.folateRDA,
                              unit: 'mcg',
                              color: Colors.lime.shade700,
                              icon: Icons.local_florist,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // ── More Minerals (collapsible) ──
                  _CollapsibleSection(
                    icon: Icons.diamond_outlined,
                    title: 'More Minerals',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MicroBar(
                              label: 'Phosphorus',
                              consumed: state.trackedPhosphorus,
                              target: profile.phosphorusRDA,
                              unit: 'mg',
                              color: Colors.brown.shade400,
                              icon: Icons.change_history,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MicroBar(
                              label: 'Selenium',
                              consumed: state.trackedSelenium,
                              target: profile.seleniumRDA,
                              unit: 'mcg',
                              color: Colors.teal.shade700,
                              icon: Icons.grain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _MicroBar(
                        label: 'Manganese',
                        consumed: state.trackedManganese,
                        target: profile.manganeseRDA,
                        unit: 'mg',
                        color: Colors.deepPurple.shade300,
                        icon: Icons.hexagon_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        // 2x3 Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            _FoodGridItem(
              icon: Icons.restaurant_menu,
              label: 'Track Food',
              subtitle: 'Log your daily meals',
              color: Colors.green,
              onTap: () => _openTrackFood(context),
            ),
            _FoodGridItem(
              icon: Icons.fitness_center,
              label: 'Workout',
              subtitle: 'Log exercises',
              color: Colors.deepOrange,
              onTap: () => _openWorkout(context),
            ),
            _FoodGridItem(
              icon: Icons.bedtime,
              label: 'Sleep',
              subtitle: 'Track your sleep',
              color: Colors.indigo,
              onTap: () => _openSleep(context),
            ),
            _FoodGridItem(
              icon: Icons.menu_book,
              label: 'Recipes',
              subtitle: 'Healthy recipes',
              color: Colors.orange,
              onTap: () => _openRecipes(context),
            ),
            _FoodGridItem(
              icon: Icons.monitor_weight,
              label: 'Weight Plan',
              subtitle: 'Goals & BMI',
              color: Colors.blue,
              onTap: () => _openWeightPlan(context),
            ),
            _FoodGridItem(
              icon: Icons.lightbulb_outline,
              label: 'Tips',
              subtitle: 'Health advice',
              color: Colors.amber,
              onTap: () => _openTips(context),
            ),
            _FoodGridItem(
              icon: Icons.search,
              label: 'Food Info',
              subtitle: 'Explore nutrition',
              color: Colors.cyan,
              onTap: () => _openFoodExplorer(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // ── Today's Logs ──
        _TodayInsightSection(state: state, profile: profile),
      ],
    );
  }

  void _openWorkout(BuildContext context) {
    final cubit = context.read<GymCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const LogWorkoutScreen(),
            ),
          ),
        )
        .then((_) => cubit.loadTodayWorkouts());
  }

  void _openSleep(BuildContext context) {
    final cubit = context.read<GymCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const LogSleepScreen(),
            ),
          ),
        )
        .then((_) => cubit.loadTodaySleep());
  }

  void _openTrackFood(BuildContext context) {
    final cubit = context.read<GymCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const _TrackFoodPage(),
            ),
          ),
        )
        .then((_) => cubit.loadTrackedFood());
  }

  void _openRecipes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _RecipesPage(),
      ),
    );
  }

  void _openWeightPlan(BuildContext context) {
    final cubit = context.read<GymCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const WeightLossScreen(),
        ),
      ),
    );
  }

  void _openTips(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeightLossTipsScreen(goalType: profile.goalType),
      ),
    );
  }

  void _openFoodExplorer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FoodExplorerScreen(),
      ),
    );
  }
}

// ─── Today's Insight Section ─────────────────────────────────────────────────

class _TodayInsightSection extends StatelessWidget {
  const _TodayInsightSection({required this.state, required this.profile});
  final GymState state;
  final WeightLossProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final todayKey =
        DateTime(now.year, now.month, now.day);
    final todaySteps = state.stepsHistory[todayKey] ?? 0;
    // BMI-based step goal (same logic as steps_screen & gym_home_screen)
    int stepGoal = 10000;
    final heightM = profile.heightCm / 100;
    final bmi = profile.currentWeight / (heightM * heightM);
    if (bmi < 18.5) {
      stepGoal = 8000;
    } else if (bmi < 25) {
      stepGoal = 10000;
    } else if (bmi < 30) {
      stepGoal = 12000;
    } else {
      stepGoal = 15000;
    }

    // Group tracked foods by meal, only include meals with food
    final mealEntries = <_MealInsightData>[];
    for (final meal in MealType.values) {
      final foods = state.trackedFoodsForMeal(meal);
      if (foods.isEmpty) continue;
      final cal = state.trackedCaloriesForMeal(meal);
      final mealTarget =
          (profile.dailyCalorieTarget * meal.calorieShare).round();
      final protein =
          foods.fold<double>(0, (s, f) => s + f.totalProtein);
      final carbs = foods.fold<double>(0, (s, f) => s + f.totalCarbs);
      final fat = foods.fold<double>(0, (s, f) => s + f.totalFat);
      final fiber = foods.fold<double>(0, (s, f) => s + f.totalFiber);
      final sodium = foods.fold<double>(0, (s, f) => s + f.totalSodium);
      final sugar = foods.fold<double>(0, (s, f) => s + f.totalSugar);
      final cholesterol =
          foods.fold<double>(0, (s, f) => s + f.totalCholesterol);
      final iron = foods.fold<double>(0, (s, f) => s + f.totalIron);
      final calcium = foods.fold<double>(0, (s, f) => s + f.totalCalcium);
      final potassium =
          foods.fold<double>(0, (s, f) => s + f.totalPotassium);
      final vitaminA =
          foods.fold<double>(0, (s, f) => s + f.totalVitaminA);
      final vitaminB12 =
          foods.fold<double>(0, (s, f) => s + f.totalVitaminB12);
      final vitaminC =
          foods.fold<double>(0, (s, f) => s + f.totalVitaminC);
      final vitaminD =
          foods.fold<double>(0, (s, f) => s + f.totalVitaminD);
      final zinc =
          foods.fold<double>(0, (s, f) => s + f.totalZinc);
      final magnesium =
          foods.fold<double>(0, (s, f) => s + f.totalMagnesium);
      final vitaminE =
          foods.fold<double>(0, (s, f) => s + f.totalVitaminE);
      final vitaminK =
          foods.fold<double>(0, (s, f) => s + f.totalVitaminK);
      final vitaminB6 =
          foods.fold<double>(0, (s, f) => s + f.totalVitaminB6);
      final folate =
          foods.fold<double>(0, (s, f) => s + f.totalFolate);
      final phosphorus =
          foods.fold<double>(0, (s, f) => s + f.totalPhosphorus);
      final selenium =
          foods.fold<double>(0, (s, f) => s + f.totalSelenium);
      final manganese =
          foods.fold<double>(0, (s, f) => s + f.totalManganese);
      final foodNames =
          foods.map((f) => f.name).take(3).join(' \u00b7 ');
      // Use latest food's trackedAt for time
      final latestTime = foods
          .map((f) => f.trackedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      mealEntries.add(_MealInsightData(
        meal: meal,
        calories: cal,
        target: mealTarget,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        sodium: sodium,
        sugar: sugar,
        cholesterol: cholesterol,
        iron: iron,
        calcium: calcium,
        potassium: potassium,
        vitaminA: vitaminA,
        vitaminB12: vitaminB12,
        vitaminC: vitaminC,
        vitaminD: vitaminD,
        zinc: zinc,
        magnesium: magnesium,
        vitaminE: vitaminE,
        vitaminK: vitaminK,
        vitaminB6: vitaminB6,
        folate: folate,
        phosphorus: phosphorus,
        selenium: selenium,
        manganese: manganese,
        foodNames: foodNames,
        time: latestTime,
      ));
    }

    final hasWorkouts = state.todayWorkouts.isNotEmpty;
    final hasSleep = state.todaySleep.isNotEmpty;

    if (mealEntries.isEmpty &&
        todaySteps == 0 &&
        state.waterMl == 0 &&
        !hasWorkouts &&
        !hasSleep) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Logs",
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Workout card
        if (hasWorkouts)
          _InsightTimelineCard(
            time: null,
            child: _WorkoutInsightCard(state: state),
          ),

        // Sleep card
        if (hasSleep)
          _InsightTimelineCard(
            time: null,
            child: _SleepInsightCard(state: state),
          ),

        // Steps card
        if (todaySteps > 0)
          _InsightTimelineCard(
            time: null,
            child: _StepInsightCard(
              steps: todaySteps,
              goal: stepGoal,
            ),
          ),

        // Water card
        if (state.waterMl > 0)
          _InsightTimelineCard(
            time: null,
            child: _WaterInsightCard(
              waterMl: state.waterMl,
              goalMl: state.effectiveWaterGoalMl,
            ),
          ),

        // Meal cards
        ...mealEntries.map((entry) => _InsightTimelineCard(
              time: entry.time,
              child: _MealInsightCard(data: entry),
            )),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _MealInsightData {
  const _MealInsightData({
    required this.meal,
    required this.calories,
    required this.target,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.sugar,
    required this.cholesterol,
    required this.iron,
    required this.calcium,
    required this.potassium,
    required this.vitaminA,
    required this.vitaminB12,
    required this.vitaminC,
    required this.vitaminD,
    required this.zinc,
    required this.magnesium,
    required this.vitaminE,
    required this.vitaminK,
    required this.vitaminB6,
    required this.folate,
    required this.phosphorus,
    required this.selenium,
    required this.manganese,
    required this.foodNames,
    required this.time,
  });

  final MealType meal;
  final double calories;
  final int target;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final double sugar;
  final double cholesterol;
  final double iron;
  final double calcium;
  final double potassium;
  final double vitaminA;
  final double vitaminB12;
  final double vitaminC;
  final double vitaminD;
  final double zinc;
  final double magnesium;
  final double vitaminE;
  final double vitaminK;
  final double vitaminB6;
  final double folate;
  final double phosphorus;
  final double selenium;
  final double manganese;
  final String foodNames;
  final DateTime time;
}

class _InsightTimelineCard extends StatelessWidget {
  const _InsightTimelineCard({required this.time, required this.child});
  final DateTime? time;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = time != null
        ? '${_pad(time!.hour > 12 ? time!.hour - 12 : (time!.hour == 0 ? 12 : time!.hour))}:${_pad(time!.minute)} ${time!.hour >= 12 ? 'PM' : 'AM'}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              timeStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

class _MealInsightCard extends StatelessWidget {
  const _MealInsightCard({required this.data});
  final _MealInsightData data;

  bool get _hasMicronutrients =>
      data.sodium > 0 ||
      data.sugar > 0 ||
      data.cholesterol > 0 ||
      data.iron > 0 ||
      data.calcium > 0 ||
      data.potassium > 0 ||
      data.vitaminA > 0 ||
      data.vitaminB12 > 0 ||
      data.vitaminC > 0 ||
      data.vitaminD > 0 ||
      data.zinc > 0 ||
      data.magnesium > 0 ||
      data.vitaminE > 0 ||
      data.vitaminK > 0 ||
      data.vitaminB6 > 0 ||
      data.folate > 0 ||
      data.phosphorus > 0 ||
      data.selenium > 0 ||
      data.manganese > 0;

  IconData _iconForMeal(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.morningSnack:
        return Icons.cookie;
      case MealType.lunch:
        return Icons.restaurant;
      case MealType.eveningSnack:
        return Icons.local_cafe;
      case MealType.dinner:
        return Icons.dinner_dining;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForMeal(data.meal),
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  data.meal.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${data.calories.round()}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${data.target} Cal Eaten',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              data.foodNames,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Macro row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InsightMacro(
                    icon: Icons.whatshot,
                    label: 'Protein',
                    value: '${data.protein.toStringAsFixed(1)} g',
                    color: Colors.blue),
                _InsightMacro(
                    icon: Icons.opacity,
                    label: 'Fats',
                    value: '${data.fat.toStringAsFixed(1)} g',
                    color: Colors.amber),
                _InsightMacro(
                    icon: Icons.grain,
                    label: 'Carbs',
                    value: '${data.carbs.toStringAsFixed(1)} g',
                    color: Colors.orange),
                _InsightMacro(
                    icon: Icons.eco,
                    label: 'Fibre',
                    value: '${data.fiber.toStringAsFixed(1)} g',
                    color: Colors.green),
              ],
            ),
            // Micronutrients
            if (_hasMicronutrients) ...[
              const SizedBox(height: 12),
              Divider(
                  height: 1,
                  color: theme.colorScheme.outline
                      .withValues(alpha: 0.2)),
              const SizedBox(height: 10),
              Text(
                'Micronutrients',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (data.sodium > 0)
                    _MicroChip(
                        label: 'Sodium',
                        value: '${data.sodium.round()} mg'),
                  if (data.sugar > 0)
                    _MicroChip(
                        label: 'Sugar',
                        value: '${data.sugar.toStringAsFixed(1)} g'),
                  if (data.cholesterol > 0)
                    _MicroChip(
                        label: 'Cholesterol',
                        value: '${data.cholesterol.round()} mg'),
                  if (data.iron > 0)
                    _MicroChip(
                        label: 'Iron',
                        value: '${data.iron.toStringAsFixed(1)} mg'),
                  if (data.calcium > 0)
                    _MicroChip(
                        label: 'Calcium',
                        value: '${data.calcium.round()} mg'),
                  if (data.potassium > 0)
                    _MicroChip(
                        label: 'Potassium',
                        value: '${data.potassium.round()} mg'),
                  if (data.zinc > 0)
                    _MicroChip(
                        label: 'Zinc',
                        value: '${data.zinc.toStringAsFixed(1)} mg'),
                  if (data.magnesium > 0)
                    _MicroChip(
                        label: 'Magnesium',
                        value: '${data.magnesium.round()} mg'),
                  if (data.vitaminA > 0)
                    _MicroChip(
                        label: 'Vit A',
                        value: '${data.vitaminA.round()} mcg'),
                  if (data.vitaminC > 0)
                    _MicroChip(
                        label: 'Vit C',
                        value: '${data.vitaminC.toStringAsFixed(1)} mg'),
                  if (data.vitaminD > 0)
                    _MicroChip(
                        label: 'Vit D',
                        value: '${data.vitaminD.toStringAsFixed(1)} mcg'),
                  if (data.vitaminB12 > 0)
                    _MicroChip(
                        label: 'Vit B12',
                        value: '${data.vitaminB12.toStringAsFixed(1)} mcg'),
                  if (data.vitaminE > 0)
                    _MicroChip(
                        label: 'Vit E',
                        value: '${data.vitaminE.toStringAsFixed(1)} mg'),
                  if (data.vitaminK > 0)
                    _MicroChip(
                        label: 'Vit K',
                        value: '${data.vitaminK.toStringAsFixed(1)} mcg'),
                  if (data.vitaminB6 > 0)
                    _MicroChip(
                        label: 'Vit B6',
                        value: '${data.vitaminB6.toStringAsFixed(1)} mg'),
                  if (data.folate > 0)
                    _MicroChip(
                        label: 'Folate',
                        value: '${data.folate.round()} mcg'),
                  if (data.phosphorus > 0)
                    _MicroChip(
                        label: 'Phosphorus',
                        value: '${data.phosphorus.round()} mg'),
                  if (data.selenium > 0)
                    _MicroChip(
                        label: 'Selenium',
                        value: '${data.selenium.toStringAsFixed(1)} mcg'),
                  if (data.manganese > 0)
                    _MicroChip(
                        label: 'Manganese',
                        value: '${data.manganese.toStringAsFixed(1)} mg'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightMacro extends StatelessWidget {
  const _InsightMacro({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color:
                theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MicroChip extends StatelessWidget {
  const _MicroChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StepInsightCard extends StatelessWidget {
  const _StepInsightCard({required this.steps, required this.goal});
  final int steps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (steps / goal).clamp(0.0, 1.0);
    final percentage = ((steps / goal) * 100).round();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk,
                    size: 20, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Walking',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatSteps(steps),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${_formatSteps(goal)} steps',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor:
                    Colors.deepPurple.withValues(alpha: 0.12),
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              steps >= goal
                  ? '$percentage% Goal Achieved!'
                  : '$percentage% of goal achieved, so far.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: steps >= goal
                    ? Colors.green
                    : theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                fontWeight:
                    steps >= goal ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSteps(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k'.replaceAll('.0k', 'k');
    }
    return '$n';
  }
}

class _WaterInsightCard extends StatelessWidget {
  const _WaterInsightCard({required this.waterMl, required this.goalMl});
  final int waterMl;
  final int goalMl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glasses = (waterMl / 250).toStringAsFixed(1);
    final progress =
        goalMl > 0 ? (waterMl / goalMl).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop,
                    size: 20, color: Colors.lightBlue),
                const SizedBox(width: 8),
                Text(
                  'Water Intake',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.lightBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$waterMl',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  goalMl > 0 ? '/ $goalMl ml' : 'ml ($glasses glasses)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            if (goalMl > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor:
                      Colors.lightBlue.withValues(alpha: 0.12),
                  color: Colors.lightBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkoutInsightCard extends StatelessWidget {
  const _WorkoutInsightCard({required this.state});
  final GymState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cal = state.todayWorkoutCalories;
    final min = state.todayWorkoutMinutes;
    const goalCal = 300.0;
    final progress = (cal / goalCal).clamp(0.0, 1.0);
    final workoutNames = state.todayWorkouts
        .map((w) => w.workoutType.label)
        .take(3)
        .join(' \u00b7 ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center,
                    size: 20, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text(
                  'Workout',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${cal.round()}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'cal burnt \u00b7 $min min',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              workoutNames,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor:
                    Colors.deepOrange.withValues(alpha: 0.12),
                color: Colors.deepOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepInsightCard extends StatelessWidget {
  const _SleepInsightCard({required this.state});
  final GymState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = state.todaySleep;
    const goalHours = 8.0;
    final totalDuration = state.todaySleepDuration;
    final actualHours = totalDuration.inMinutes / 60;
    final progress = (actualHours / goalHours).clamp(0.0, 1.0);

    // Show overall quality only when all segments agree
    final qualities = entries
        .map((e) => e.quality)
        .where((q) => q != null)
        .toSet();
    final overallQuality = qualities.length == 1 ? qualities.first : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime, size: 20, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Sleep',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  state.todaySleepFormatted,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${goalHours.round()}h goal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            if (overallQuality != null || entries.length > 1) ...[
              const SizedBox(height: 6),
              Text(
                '${overallQuality != null ? overallQuality.label : ''}'
                '${overallQuality != null && entries.length > 1 ? ' · ' : ''}'
                '${entries.length > 1 ? '${entries.length} segments' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            // Individual segment details with per-segment quality
            if (entries.length > 1) ...[
              const SizedBox(height: 8),
              ...entries.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${s.period}: ${_formatTime(s.sleepTime)} - ${_formatTime(s.wakeTime)} · ${s.durationFormatted}'
                      '${s.quality != null ? ' · ${s.quality!.label}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.indigo.withValues(alpha: 0.12),
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}

// ─── Food Grid Item ─────────────────────────────────────────────────────────

class _FoodGridItem extends StatelessWidget {
  const _FoodGridItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Track Food Page ────────────────────────────────────────────────────────

class _TrackFoodPage extends StatefulWidget {
  const _TrackFoodPage();

  @override
  State<_TrackFoodPage> createState() => _TrackFoodPageState();
}

class _TrackFoodPageState extends State<_TrackFoodPage> {
  final _picker = ImagePicker();
  bool _isAnalyzing = false;
  MealType? _scanMealType;
  String _analyzeLabel = 'Analyzing your food...';

  @override
  void initState() {
    super.initState();
    context.read<GymCubit>().loadTrackedFood();
  }

  MealType _guessMealType() {
    if (_scanMealType != null) return _scanMealType!;
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 12) return MealType.morningSnack;
    if (hour < 15) return MealType.lunch;
    if (hour < 18) return MealType.eveningSnack;
    return MealType.dinner;
  }

  void _scanForMeal(MealType meal, ImageSource source) {
    _scanMealType = meal;
    _scanFood(source);
  }

  Future<void> _scanFood(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final bytes = await picked.readAsBytes();
      final items = await GeminiFoodService.instance.analyzeFoodImage(bytes);

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No food items detected. Try again.')),
        );
        return;
      }

      _showScanResultSheet(items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showScanResultSheet(List<FoodItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodScanResultSheet(
        foodItems: items,
        onSave: (scan) {
          for (final item in scan.foodItems) {
            final tracked = TrackedFoodModel(
              id: const Uuid().v4(),
              name: item.name,
              servingSize: '1 serving',
              calories: item.calories,
              protein: item.protein,
              carbs: item.carbs,
              fat: item.fat,
              mealType: _guessMealType(),
              quantity: item.quantity.toDouble(),
            );
            context.read<GymCubit>().saveTrackedFood(tracked);
          }
          context.read<GymCubit>().saveFoodScan(scan);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scanned food added!')),
          );
        },
        onRetake: () {
          Navigator.pop(context);
          _scanFood(ImageSource.camera);
        },
      ),
    );
  }

  /// Parse free-form voice text locally into {name, quantity} maps.
  static final _wordNumbers = <String, int>{
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'a': 1, 'an': 1,
  };

  /// Matches a leading digit quantity OR a word-number quantity.
  static final _qtyRegex = RegExp(
    r'^(\d+|one|two|three|four|five|six|seven|eight|nine|ten|a|an)\s+',
    caseSensitive: false,
  );

  // All verb forms a user might say when logging food.
  // Past / present / future / -ing / -ed for each root.
  static const _verbs =
      // eat
      r'eat|eats|ate|eaten|eating|'
      // have
      r'had|have|has|having|'
      // take
      r'took|take|takes|taken|taking|'
      // drink
      r'drank|drink|drinks|drunk|drinking|'
      // consume
      r'consume|consumes|consumed|consuming|'
      // grab
      r'grab|grabs|grabbed|grabbing|'
      // finish
      r'finish|finishes|finished|finishing|'
      // munch
      r'munch|munched|munching|'
      // snack
      r'snack|snacked|snacking|'
      // sip
      r'sip|sips|sipped|sipping|'
      // devour
      r'devour|devours|devoured|devouring|'
      // gobble
      r'gobble|gobbled|gobbling|'
      // gulp
      r'gulp|gulps|gulped|gulping|'
      // chug
      r'chug|chugs|chugged|chugging|'
      // taste
      r'taste|tasted|tasting|'
      // try
      r'try|tries|tried|trying|'
      // order
      r'order|orders|ordered|ordering|'
      // get
      r'get|gets|got|gotten|getting|'
      // swallow
      r'swallow|swallowed|swallowing|'
      // chew
      r'chew|chews|chewed|chewing|'
      // chomp
      r'chomp|chomps|chomped|chomping|'
      // ingest
      r'ingest|ingests|ingested|ingesting|'
      // feast
      r'feast|feasted|feasting|'
      // nibble
      r'nibble|nibbles|nibbled|nibbling|'
      // cook
      r'cook|cooks|cooked|cooking|'
      // make
      r'make|makes|made|making|'
      // prepare
      r'prepare|prepares|prepared|preparing|'
      // pick
      r'pick|picks|picked|picking|'
      // choose
      r'choose|chooses|chose|chosen|choosing|'
      // select
      r'select|selects|selected|selecting|'
      // buy
      r'buy|buys|bought|buying|'
      // bite
      r'bite|bites|bit|bitten|biting|'
      // chow
      r'chow|chowed|chowing|'
      // scoff
      r'scoff|scoffs|scoffed|scoffing|'
      // wolf (wolf down)
      r'wolf|wolfed|wolfing|'
      // down (scarfed down / wolfed down)
      r'down|'
      // digest
      r'digest|digested|digesting|'
      // savour / savor
      r'savour|savoured|savouring|savor|savored|savoring|'
      // relish
      r'relish|relished|relishing|'
      // gorge
      r'gorge|gorged|gorging|'
      // inhale (slang)
      r'inhale|inhaled|inhaling|'
      // polish off
      r'polished|polish|'
      // scarf
      r'scarf|scarfed|scarfing|'
      // sup
      r'sup|supped|supping|'
      // nosh
      r'nosh|noshed|noshing|'
      // binge
      r'binge|binged|binging|bingeing';

  // Auxiliaries: past / present / future / continuous helpers.
  static const _aux =
      r'have\s+|had\s+|just\s+|also\s+|already\s+|only\s+|'
      r'will\s+|gonna\s+|going\s+to\s+|want\s+to\s+|wanna\s+|'
      r'planning\s+to\s+|about\s+to\s+|need\s+to\s+|'
      r'am\s+|was\s+|were\s+|been\s+';

  /// Filler phrases to strip (applied to full text AND each segment).
  static final _fillerRegex = RegExp(
    '^('
    // "I (aux)* <verb>"  — covers all tenses
    'i\\s+($_aux)*($_verbs)'
    '|'
    // "i'm / im <verb>"
    r"(i'm|im)\s+" '($_verbs)'
    '|'
    // "today/yesterday/morning/tonight/later I (aux) <verb>"
    '(today|yesterday|this\\s+morning|tonight|later|'
    'in\\s+the\\s+morning|in\\s+the\\s+evening)\\s+'
    'i\\s+($_aux)*($_verbs)'
    '|'
    // "for breakfast/lunch/dinner/snack I (aux) <verb>"
    'for\\s+(breakfast|lunch|dinner|snack|brunch|supper|'
    'morning\\s+snack|evening\\s+snack)\\s+'
    'i\\s+($_aux)*($_verbs)'
    '|'
    // "let me / please log/add/track"
    r'(let\s+me\s+|please\s+)?(log|add|track|record|note|put|save|enter)'
    r')\s+',
    caseSensitive: false,
  );

  // Strip container/measurement words like "glass of", "bowl of", etc.
  static final _containerRegex = RegExp(
    r'^(glass|glasses|cup|cups|bowl|bowls|plate|plates|piece|pieces|'
    r'slice|slices|serving|servings|bottle|bottles|can|cans|'
    r'spoon|spoons|tablespoon|tablespoons|teaspoon|teaspoons|'
    r'scoop|scoops|handful|handfuls|packet|packets|pack|packs|'
    r'box|boxes|bag|bags|bar|bars|stick|sticks|roll|rolls|'
    r'portion|portions|helping|helpings|mug|mugs|jug|jugs|'
    r'pint|pints|loaf|loaves|bunch|bunches)\s+of\s+',
    caseSensitive: false,
  );

  /// Trailing noise words to strip from each segment.
  static final _trailingNoise = RegExp(
    r'\s+(and|or|also|plus|with|then|but|so|like|um|uh|hmm|ok|okay|yeah|the|a|an)$',
    caseSensitive: false,
  );

  List<Map<String, dynamic>> _parseVoiceText(String text) {
    // Strip filler prefix from the whole text first
    var cleaned = text.trim();
    cleaned = cleaned.replaceFirst(_fillerRegex, '');

    // Split on commas, connectors, "&"
    final segments = cleaned
        .split(RegExp(
            r',|(?:\s+and\s+)|(?:\s+or\s+)|(?:\s+also\s+)|'
            r'(?:\s+plus\s+)|(?:\s+with\s+)|(?:\s+then\s+)|'
            r'(?:\s+but\s+)|&'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    final results = <Map<String, dynamic>>[];
    for (var seg in segments) {
      // Strip filler from each segment too (e.g. "and I had one X")
      seg = seg.replaceFirst(_fillerRegex, '').trim();
      // Strip trailing noise words ("or", "and", "um", etc.)
      while (_trailingNoise.hasMatch(seg)) {
        seg = seg.replaceFirst(_trailingNoise, '').trim();
      }
      if (seg.isEmpty) continue;

      final match = _qtyRegex.firstMatch(seg);
      int qty = 1;
      String name = seg;
      if (match != null) {
        final raw = match.group(1)!.toLowerCase();
        qty = _wordNumbers[raw] ?? int.tryParse(raw) ?? 1;
        name = seg.substring(match.end).trim();
      }
      // Strip "glass of", "bowl of", "cup of", etc.
      name = name.replaceFirst(_containerRegex, '').trim();
      // Strip trailing noise from name too
      while (_trailingNoise.hasMatch(name)) {
        name = name.replaceFirst(_trailingNoise, '').trim();
      }
      if (name.isNotEmpty) {
        results.add({'name': name, 'quantity': qty});
      }
    }
    return results;
  }

  void _voiceForMeal(MealType meal) {
    _scanMealType = meal;
    _startVoiceSearch();
  }

  Future<void> _startVoiceSearch() async {
    final speech = stt.SpeechToText();
    final available = await speech.initialize();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    if (!mounted) return;

    String transcript = '';
    bool done = false;
    bool dialogPopped = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            if (!done) {
              done = true;
              speech.listen(
                onResult: (result) {
                  if (dialogPopped) return;
                  setDialogState(() => transcript = result.recognizedWords);
                  if (result.finalResult) {
                    speech.stop();
                    dialogPopped = true;
                    Navigator.of(ctx).pop(transcript);
                  }
                },
                listenFor: const Duration(seconds: 15),
                pauseFor: const Duration(seconds: 3),
              );
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text(
                    'Listening...',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transcript.isEmpty
                        ? 'Say what you ate'
                        : transcript,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: transcript.isEmpty ? Colors.grey : null,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    dialogPopped = true;
                    speech.stop();
                    Navigator.of(ctx).pop(null);
                  },
                  child: const Text('Cancel'),
                ),
                if (transcript.isNotEmpty)
                  FilledButton(
                    onPressed: () {
                      dialogPopped = true;
                      speech.stop();
                      Navigator.of(ctx).pop(transcript);
                    },
                    child: const Text('Done'),
                  ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result == null || (result as String).trim().isEmpty) return;

      setState(() {
        _isAnalyzing = true;
        _analyzeLabel = 'Parsing your food...';
      });

      try {
        // Step 1: Parse voice text locally
        final parsed = _parseVoiceText(result);

        if (!mounted) return;
        if (parsed.isEmpty) {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not understand. Try again.')),
          );
          return;
        }

        setState(() => _analyzeLabel = 'Matching foods...');

        // Step 2: Match each parsed item from local DB
        final foodDb = FoodDatabaseService.instance;
        final entries = <VoiceFoodEntry>[];

        for (final item in parsed) {
          final name = item['name'] as String;
          final qty = item['quantity'] as int;

          // Try full name first
          final results = await foodDb.searchByName(name, limit: 1);
          if (results.isNotEmpty) {
            entries.add(VoiceFoodEntry(
                food: results.first, quantity: qty));
            continue;
          }

          // Full name didn't match — greedy split by words
          final words = name.split(RegExp(r'\s+'));
          var i = 0;
          while (i < words.length) {
            // Check if current word is a quantity
            final wLower = words[i].toLowerCase();
            int subQty = qty;
            if (_wordNumbers.containsKey(wLower) ||
                int.tryParse(wLower) != null) {
              subQty = _wordNumbers[wLower] ?? int.tryParse(wLower) ?? 1;
              i++;
              if (i >= words.length) break;
            }

            // Strip container word: "glass of", "cup of", etc.
            if (i + 1 < words.length &&
                _containerRegex.hasMatch(
                    '${words[i]} ${words[i + 1]} ')) {
              i += 2; // skip "glass of"
              if (i >= words.length) break;
            }

            // Try longest phrase first, then shorter
            bool matched = false;
            for (var len = words.length - i; len > 0; len--) {
              final phrase = words.sublist(i, i + len).join(' ');
              final sub =
                  await foodDb.searchByName(phrase, limit: 1);
              if (sub.isNotEmpty) {
                entries.add(VoiceFoodEntry(
                    food: sub.first, quantity: subQty));
                i += len;
                matched = true;
                break;
              }
            }
            if (!matched) i++; // skip unrecognized word
          }
        }

        if (!mounted) return;
        setState(() => _isAnalyzing = false);

        if (entries.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No matching foods found in database.')),
          );
          return;
        }

        _showVoiceResultSheet(entries);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    });
  }

  void _showVoiceResultSheet(List<VoiceFoodEntry> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceFoodResultSheet(
        entries: entries,
        onSave: (items) {
          final mealType = _guessMealType();
          for (final entry in items) {
            final food = entry.food;
            final tracked = TrackedFoodModel(
              id: const Uuid().v4(),
              name: food.name,
              servingSize: food.servingSize,
              calories: food.calories,
              protein: food.protein,
              carbs: food.carbs,
              fat: food.fat,
              fiber: food.fiber,
              sodium: food.sodium,
              sugar: food.sugar,
              cholesterol: food.cholesterol,
              iron: food.iron,
              calcium: food.calcium,
              potassium: food.potassium,
              mealType: mealType,
              quantity: entry.quantity.toDouble(),
            );
            context.read<GymCubit>().saveTrackedFood(tracked);
            // Also save to local DB for future searches
            FoodDatabaseService.instance.insertFood(food);
          }
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${items.length} food${items.length > 1 ? 's' : ''} added to ${mealType.label}'),
            ),
          );
        },
        onTryAgain: () {
          Navigator.pop(context);
          _startVoiceSearch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Food')),
      body: Stack(
        children: [
          BlocBuilder<GymCubit, GymState>(
            builder: (context, state) {
              final profile = state.weightLossProfile;
              if (profile == null) return const SizedBox.shrink();
              return _TrackTab(
                profile: profile,
                state: state,
                onScanFood: _scanForMeal,
                onVoiceFood: _voiceForMeal,
              );
            },
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _analyzeLabel,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Recipes Page ───────────────────────────────────────────────────────────

class _RecipesPage extends StatelessWidget {
  const _RecipesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: const _RecipesTab(),
    );
  }
}

// ─── Track Tab ──────────────────────────────────────────────────────────────

class _TrackTab extends StatelessWidget {
  const _TrackTab({
    required this.profile,
    required this.state,
    required this.onScanFood,
    required this.onVoiceFood,
  });

  final WeightLossProfileModel profile;
  final GymState state;
  final void Function(MealType meal, ImageSource source) onScanFood;
  final void Function(MealType meal) onVoiceFood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consumed = state.trackedCalories;
    final target = profile.dailyCalorieTarget;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Circular calorie header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: consumed > target
                            ? Colors.red
                            : theme.colorScheme.primary,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${consumed.round()}',
                              style:
                                  theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              '/ ${target.round()} kcal',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Macro bars
                Row(
                  children: [
                    Expanded(
                        child: _MacroBar(
                      label: 'Protein',
                      consumed: state.trackedProtein,
                      target: profile.proteinGrams,
                      color: Colors.blue,
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _MacroBar(
                      label: 'Carbs',
                      consumed: state.trackedCarbs,
                      target: profile.carbsGrams,
                      color: Colors.orange,
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _MacroBar(
                      label: 'Fat',
                      consumed: state.trackedFat,
                      target: profile.fatGrams,
                      color: Colors.red,
                    )),
                  ],
                ),
                // ── Micronutrients (collapsible) ──
                _CollapsibleSection(
                  icon: Icons.science_outlined,
                  title: 'Micronutrients',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MicroBar(
                            label: 'Fibre',
                            consumed: state.trackedFiber,
                            target: profile.fiberRDA,
                            unit: 'g',
                            color: Colors.brown,
                            icon: Icons.grass,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MicroBar(
                            label: 'Sugar',
                            consumed: state.trackedSugar,
                            target: profile.sugarLimit,
                            unit: 'g',
                            color: Colors.pink,
                            icon: Icons.cake_outlined,
                            isLimit: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MicroBar(
                            label: 'Iron',
                            consumed: state.trackedIron,
                            target: profile.ironRDA,
                            unit: 'mg',
                            color: Colors.red.shade700,
                            icon: Icons.bloodtype_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MicroBar(
                            label: 'Calcium',
                            consumed: state.trackedCalcium,
                            target: profile.calciumRDA,
                            unit: 'mg',
                            color: Colors.teal,
                            icon: Icons.accessibility_new,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MicroBar(
                            label: 'Potassium',
                            consumed: state.trackedPotassium,
                            target: profile.potassiumRDA,
                            unit: 'mg',
                            color: Colors.purple,
                            icon: Icons.bolt,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MicroBar(
                            label: 'Sodium',
                            consumed: state.trackedSodium,
                            target: profile.sodiumLimit,
                            unit: 'mg',
                            color: Colors.orange,
                            icon: Icons.water_drop_outlined,
                            isLimit: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MicroBar(
                            label: 'Zinc',
                            consumed: state.trackedZinc,
                            target: profile.zincRDA,
                            unit: 'mg',
                            color: Colors.blueGrey,
                            icon: Icons.shield_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MicroBar(
                            label: 'Magnesium',
                            consumed: state.trackedMagnesium,
                            target: profile.magnesiumRDA,
                            unit: 'mg',
                            color: Colors.indigo,
                            icon: Icons.electric_bolt,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MicroBar(
                      label: 'Cholesterol',
                      consumed: state.trackedCholesterol,
                      target: profile.cholesterolLimit,
                      unit: 'mg',
                      color: Colors.amber.shade800,
                      icon: Icons.favorite_outline,
                      isLimit: true,
                    ),
                  ],
                ),
                // ── Vitamins (collapsible) ──
                _CollapsibleSection(
                  icon: Icons.medication_outlined,
                  title: 'Vitamins',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MicroBar(
                            label: 'Vitamin A',
                            consumed: state.trackedVitaminA,
                            target: profile.vitaminARDA,
                            unit: 'mcg',
                            color: Colors.deepOrange,
                            icon: Icons.visibility_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MicroBar(
                            label: 'Vitamin C',
                            consumed: state.trackedVitaminC,
                            target: profile.vitaminCRDA,
                            unit: 'mg',
                            color: Colors.amber,
                            icon: Icons.local_florist_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MicroBar(
                            label: 'Vitamin D',
                            consumed: state.trackedVitaminD,
                            target: profile.vitaminDRDA,
                            unit: 'mcg',
                            color: Colors.lightBlue,
                            icon: Icons.wb_sunny_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MicroBar(
                            label: 'Vitamin B12',
                            consumed: state.trackedVitaminB12,
                            target: profile.vitaminB12RDA,
                            unit: 'mcg',
                            color: Colors.red.shade400,
                            icon: Icons.psychology_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MicroBar(
                            label: 'Vitamin E',
                            consumed: state.trackedVitaminE,
                            target: profile.vitaminERDA,
                            unit: 'mg',
                            color: Colors.green.shade600,
                            icon: Icons.spa_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MicroBar(
                            label: 'Vitamin K',
                            consumed: state.trackedVitaminK,
                            target: profile.vitaminKRDA,
                            unit: 'mcg',
                            color: Colors.green.shade800,
                            icon: Icons.eco_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MicroBar(
                            label: 'Vitamin B6',
                            consumed: state.trackedVitaminB6,
                            target: profile.vitaminB6RDA,
                            unit: 'mg',
                            color: Colors.cyan,
                            icon: Icons.energy_savings_leaf_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MicroBar(
                            label: 'Folate',
                            consumed: state.trackedFolate,
                            target: profile.folateRDA,
                            unit: 'mcg',
                            color: Colors.lime.shade700,
                            icon: Icons.local_florist,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // ── More Minerals (collapsible) ──
                _CollapsibleSection(
                  icon: Icons.diamond_outlined,
                  title: 'More Minerals',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MicroBar(
                            label: 'Phosphorus',
                            consumed: state.trackedPhosphorus,
                            target: profile.phosphorusRDA,
                            unit: 'mg',
                            color: Colors.brown.shade400,
                            icon: Icons.change_history,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MicroBar(
                            label: 'Selenium',
                            consumed: state.trackedSelenium,
                            target: profile.seleniumRDA,
                            unit: 'mcg',
                            color: Colors.teal.shade700,
                            icon: Icons.grain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MicroBar(
                      label: 'Manganese',
                      consumed: state.trackedManganese,
                      target: profile.manganeseRDA,
                      unit: 'mg',
                      color: Colors.deepPurple.shade300,
                      icon: Icons.hexagon_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Meal sections
        ...MealType.values.map((meal) => _MealSection(
              meal: meal,
              target: profile.dailyCalorieTarget,
              foods: state.trackedFoodsForMeal(meal),
              caloriesConsumed: state.trackedCaloriesForMeal(meal),
              onAddManually: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<GymCubit>(),
                      child: FoodSearchScreen(mealType: meal),
                    ),
                  ),
                );
              },
              onScan: (source) => onScanFood(meal, source),
              onVoice: () => onVoiceFood(meal),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  final String label;
  final double consumed;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Text(
          '${consumed.round()}/${target.round()}g',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.15),
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 12),
        Divider(
          height: 1,
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(widget.icon,
                    size: 14,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  widget.title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Column(
            children: widget.children,
          ),
        ),
      ],
    );
  }
}

class _MicroBar extends StatelessWidget {
  const _MicroBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
    required this.icon,
    this.isLimit = false,
  });

  final String label;
  final double consumed;
  final double target;
  final String unit;
  final Color color;
  final IconData icon;
  /// If true, exceeding target is bad (sodium, sugar, cholesterol)
  final bool isLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final percentage = target > 0 ? ((consumed / target) * 100).round() : 0;
    final isOver = consumed > target && target > 0;
    final barColor = isLimit && isOver ? Colors.red : color;
    final consumedStr = consumed >= 100
        ? '${consumed.round()}'
        : consumed.toStringAsFixed(1);
    final targetStr = target >= 100
        ? '${target.round()}'
        : target.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: barColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: barColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: barColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ),
              if (isLimit && isOver)
                Icon(Icons.warning_rounded, size: 12, color: Colors.red),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: barColor.withValues(alpha: 0.12),
              color: barColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$consumedStr / $targetStr $unit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: barColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.meal,
    required this.target,
    required this.foods,
    required this.caloriesConsumed,
    required this.onAddManually,
    required this.onScan,
    required this.onVoice,
  });

  final MealType meal;
  final double target;
  final List<TrackedFoodModel> foods;
  final double caloriesConsumed;
  final VoidCallback onAddManually;
  final void Function(ImageSource source) onScan;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealTarget = (target * meal.calorieShare).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAddOptions(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconForMeal(meal),
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meal.label,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${caloriesConsumed.round()} / $mealTarget kcal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.add_circle_outline,
                      size: 22, color: theme.colorScheme.primary),
                ],
              ),
              if (foods.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...foods.map((food) => Dismissible(
                      key: Key(food.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        context
                            .read<GymCubit>()
                            .deleteTrackedFood(food.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                food.quantity != 1
                                    ? '${food.name} x${food.displayQuantity}${food.measure != 'Serving' ? ' ${food.measure}' : ''}'
                                    : food.measure != 'Serving'
                                        ? '${food.name} (${food.measure})'
                                        : food.name,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${food.totalCalories.round()} kcal',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add to ${meal.label}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Search & Add Food'),
              subtitle: const Text('Pick from 300+ foods by category'),
              onTap: () {
                Navigator.pop(context);
                onAddManually();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Voice Search'),
              subtitle: const Text('Say what you ate'),
              onTap: () {
                Navigator.pop(context);
                onVoice();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              subtitle: const Text('Scan food with camera'),
              onTap: () {
                Navigator.pop(context);
                onScan(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Pick a food photo from gallery'),
              onTap: () {
                Navigator.pop(context);
                onScan(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _iconForMeal(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.morningSnack:
        return Icons.apple;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.eveningSnack:
        return Icons.cookie;
      case MealType.dinner:
        return Icons.dinner_dining;
    }
  }
}

// ─── Recipes Tab ────────────────────────────────────────────────────────────

class _RecipesTab extends StatefulWidget {
  const _RecipesTab();

  @override
  State<_RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<_RecipesTab>
    with SingleTickerProviderStateMixin {
  late final TabController _catTabCtrl;
  Map<RecipeCategory, List<RecipeModel>> _recipes = {};
  bool _loading = true;

  static const _categories = RecipeCategory.values;
  static const _assetFiles = {
    RecipeCategory.breakfast: 'assets/recipes/breakfast.json',
    RecipeCategory.lunch: 'assets/recipes/lunch.json',
    RecipeCategory.dinner: 'assets/recipes/dinner.json',
    RecipeCategory.snack: 'assets/recipes/snack.json',
    RecipeCategory.salad: 'assets/recipes/salad.json',
    RecipeCategory.soup: 'assets/recipes/soup.json',
    RecipeCategory.smoothie: 'assets/recipes/smoothie.json',
    RecipeCategory.healthyDessert: 'assets/recipes/healthyDessert.json',
  };

  @override
  void initState() {
    super.initState();
    _catTabCtrl = TabController(length: _categories.length, vsync: this);
    _loadRecipes();
  }

  @override
  void dispose() {
    _catTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    final map = <RecipeCategory, List<RecipeModel>>{};
    for (final entry in _assetFiles.entries) {
      try {
        final jsonStr = await rootBundle.loadString(entry.value);
        final list = json.decode(jsonStr) as List;
        map[entry.key] =
            list.map((e) => RecipeModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        map[entry.key] = [];
      }
    }
    if (!mounted) return;
    setState(() {
      _recipes = map;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TabBar(
          controller: _catTabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((c) => Tab(text: c.label)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _catTabCtrl,
            children: _categories.map((cat) {
              final recipes = _recipes[cat] ?? [];
              if (recipes.isEmpty) {
                return const Center(child: Text('No recipes'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: recipes.length,
                itemBuilder: (context, i) {
                  final r = recipes[i];
                  return _RecipeCard(recipe: r);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});
  final RecipeModel recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => RecipeDetailSheet(recipe: recipe),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (recipe.isVegetarian)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text(
                        'Veg',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MacroChip(
                    label: '${recipe.calories} kcal',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  _MacroChip(
                    label: 'P: ${recipe.protein.toStringAsFixed(0)}g',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  _MacroChip(
                    label: 'C: ${recipe.carbs.toStringAsFixed(0)}g',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  _MacroChip(
                    label: 'F: ${recipe.fat.toStringAsFixed(0)}g',
                    color: Colors.red,
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Searchable Picker Dialog ────────────────────────────────────────────────

class _SearchablePickerDialog<T> extends StatefulWidget {
  const _SearchablePickerDialog({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.labelBuilder,
    required this.onSelected,
    this.subtitleBuilder,
  });

  final String title;
  final List<T> items;
  final T selectedItem;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final ValueChanged<T> onSelected;

  @override
  State<_SearchablePickerDialog<T>> createState() =>
      _SearchablePickerDialogState<T>();
}

class _SearchablePickerDialogState<T>
    extends State<_SearchablePickerDialog<T>> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) {
      final label = widget.labelBuilder(item).toLowerCase();
      final sub = widget.subtitleBuilder?.call(item).toLowerCase() ?? '';
      return label.contains(q) || sub.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Flexible(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No results found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final isSelected = item == widget.selectedItem;

                        return ListTile(
                          selected: isSelected,
                          title: Text(widget.labelBuilder(item)),
                          subtitle: widget.subtitleBuilder != null
                              ? Text(widget.subtitleBuilder!(item))
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check,
                                  color: theme.colorScheme.primary)
                              : null,
                          onTap: () {
                            widget.onSelected(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
