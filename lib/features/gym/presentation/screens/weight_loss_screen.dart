import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/gym_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/diet_chart_pdf_service.dart';
import '../../data/diet_chart_service.dart';
import '../../domain/weight_loss_profile_model.dart';
import '../providers/gym_provider.dart';
import '../widgets/bmi_gauge_widget.dart';

class WeightLossScreen extends StatefulWidget {
  const WeightLossScreen({super.key});

  @override
  State<WeightLossScreen> createState() => _WeightLossScreenState();
}

class _WeightLossScreenState extends State<WeightLossScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        CoachMarkService.showIfNeeded(
          context: context,
          screenKey: 'coach_mark_weight_plan_shown',
          targets: weightPlanCoachTargets(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weight Plan')),
      body: BlocBuilder<GymCubit, GymState>(
        builder: (context, state) {
          final profile = state.weightLossProfile;
          if (profile == null) {
            return _SetupForm(
              initialWeight: state.userWeight,
              initialHeight: state.userHeight,
            );
          }
          return _Dashboard(profile: profile, state: state);
        },
      ),
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
  bool _isVegetarian = false;
  int? _gymTimeHour;
  int _proteinScoops = 0;
  bool _takesCreatine = false;
  bool _takesMassGainer = false;

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
      builder: (_) => _ActivityPickerDialog(
        selectedLevel: _activityLevel,
        onSelected: (a) => setState(() => _activityLevel = a),
      ),
    );
  }

  void _pickGymTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _gymTimeHour ?? 7, minute: 0),
      helpText: 'Select your gym time',
    );
    if (time != null) {
      setState(() => _gymTimeHour = time.hour);
    }
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
      isVegetarian: _isVegetarian,
      gymTimeHour: _gymTimeHour,
      proteinScoops: _proteinScoops,
      takesCreatine: _takesCreatine,
      takesMassGainer: _takesMassGainer,
    );
    context.read<GymCubit>().saveWeightLossProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: CoachMarkKeys.weightPlanSetup,
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

            // Age
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

            // Gender
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

            // Activity Level
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

            // Height
            TextFormField(
              controller: _heightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

            // Current Weight
            TextFormField(
              controller: _currentWeightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

              // Target Weight
              TextFormField(
                controller: _targetWeightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

            // Weekly Goal
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
                    onSelected: (_) => setState(() => _weeklyGoal = goal),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // Diet Preference
            Text('Diet Preference', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Veg'),
                  icon: Icon(Icons.eco),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Non-Veg'),
                  icon: Icon(Icons.restaurant),
                ),
              ],
              selected: {_isVegetarian},
              onSelectionChanged: (s) =>
                  setState(() => _isVegetarian = s.first),
            ),
            const SizedBox(height: 24),

            // ── Supplements & Gym ───
            Text('Supplements & Gym', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),

            // Gym Time (optional)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _pickGymTime,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Gym Time (Optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_gymTimeHour != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setState(() => _gymTimeHour = null),
                        ),
                      const Icon(Icons.access_time),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                child: Text(_gymTimeHour != null
                    ? _formatHour(_gymTimeHour!)
                    : 'Not set'),
              ),
            ),
            const SizedBox(height: 16),

            // Protein Scoops
            Text('Whey Protein Scoops/Day',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('0')),
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
              ],
              selected: {_proteinScoops},
              onSelectionChanged: (s) =>
                  setState(() => _proteinScoops = s.first),
            ),
            const SizedBox(height: 12),

            // Creatine
            SwitchListTile(
              title: const Text('Taking Creatine?'),
              subtitle:
                  const Text('5g creatine monohydrate daily'),
              value: _takesCreatine,
              onChanged: (v) => setState(() => _takesCreatine = v),
              contentPadding: EdgeInsets.zero,
            ),

            // Mass Gainer (only for weight gain)
            if (_goalType == GoalType.gain)
              SwitchListTile(
                title: const Text('Taking Mass Gainer?'),
                subtitle: const Text(
                    'High calorie supplement for weight gain'),
                value: _takesMassGainer,
                onChanged: (v) =>
                    setState(() => _takesMassGainer = v),
                contentPadding: EdgeInsets.zero,
              ),
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

// ─── Dashboard ──────────────────────────────────────────────────────────────

class _Dashboard extends StatefulWidget {
  const _Dashboard({required this.profile, required this.state});
  final WeightLossProfileModel profile;
  final GymState state;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        CoachMarkService.showIfNeeded(
          context: context,
          screenKey: 'coach_mark_weight_dashboard_shown',
          targets: weightDashboardCoachTargets(),
        );
      });
    });
  }

  WeightLossProfileModel get profile => widget.profile;
  GymState get state => widget.state;

  int _computeStepGoal() {
    final h = state.userHeight;
    final w = state.userWeight;
    if (h != null && w != null) {
      final bmi = w / ((h / 100) * (h / 100));
      if (bmi < 18.5) return 8000;
      if (bmi < 25) return 10000;
      if (bmi < 30) return 12000;
      return 15000;
    }
    return 10000;
  }

  Future<void> _exportDietChart() async {
    setState(() => _exporting = true);
    try {
      final authState = context.read<AuthCubit>().state;
      final uid = authState.user?.uid;
      String userName = authState.user?.displayName ?? 'User';
      if (uid != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final d = snap.data();
        if (d != null) {
          final full = [d['firstName'], d['lastName']]
              .where((s) => s != null && s.toString().isNotEmpty)
              .join(' ');
          if (full.isNotEmpty) userName = full;
          else if (d['displayName'] != null) userName = d['displayName'];
        }
      }

      // Use app's actual daily goals
      final waterGoal = state.effectiveWaterGoalMl > 0
          ? state.effectiveWaterGoalMl
          : (profile.currentWeight * 33).round();
      final stepsGoal = _computeStepGoal();

      final chart = await DietChartService.generate(
        profile,
        waterGoalMl: waterGoal,
        stepsGoal: stepsGoal,
        isVegetarian: profile.isVegetarian,
      );
      final pdf = await DietChartPdfService.generate(
        chart: chart,
        userName: userName,
      );

      final dir = await getTemporaryDirectory();
      final file = XFile(
        '${dir.path}/CoreSyncGo_DietChart.pdf',
        mimeType: 'application/pdf',
      );
      final bytes = await pdf.save();
      await XFile.fromData(bytes,
              mimeType: 'application/pdf', name: 'CoreSyncGo_DietChart.pdf')
          .saveTo(file.path);

      if (!mounted) return;
      await shareFiles(
        [file],
        context: context,
        subject: 'CoreSync Go Diet Chart',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consumed = state.dailyCalories + state.trackedCalories;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // BMI Gauge
          Card(
            key: CoachMarkKeys.weightDashboardBmi,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Body Mass Index',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  BmiGaugeWidget(
                    bmi: profile.bmi,
                    category: profile.bmiCategory,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.bmiWeightAdvice,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: profile.bmiCategory == 'Normal'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Daily Calorie Target
          Card(
            key: CoachMarkKeys.weightDashboardCalories,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Daily Calorie Target',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${profile.dailyCalorieTarget.round()}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  if (consumed > 0) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (consumed / profile.dailyCalorieTarget)
                          .clamp(0, 1),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${consumed.round()} / ${profile.dailyCalorieTarget.round()} kcal consumed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Macro Targets
          Card(
            key: CoachMarkKeys.weightDashboardMacros,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Macro Targets',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MacroCard(
                          label: 'Protein',
                          target: profile.proteinGrams,
                          consumed: _totalProtein,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroCard(
                          label: 'Carbs',
                          target: profile.carbsGrams,
                          consumed: _totalCarbs,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroCard(
                          label: 'Fat',
                          target: profile.fatGrams,
                          consumed: _totalFat,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Profile Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile Summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editProfile(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow('Age', '${profile.age} years'),
                  _SummaryRow('Gender', profile.gender.name[0].toUpperCase() +
                      profile.gender.name.substring(1)),
                  _SummaryRow('Height', '${profile.heightCm.round()} cm'),
                  _SummaryRow('Current Weight',
                      '${profile.currentWeight.toStringAsFixed(1)} kg'),
                  _SummaryRow('Target Weight',
                      '${profile.targetWeight.toStringAsFixed(1)} kg'),
                  _SummaryRow('Goal', profile.goalLabel),
                  _SummaryRow('Weekly Goal',
                      '${profile.weeklyGoalKg} kg/week'),
                  _SummaryRow('Activity', profile.activityLevel.label),
                  _SummaryRow('Diet',
                      profile.isVegetarian ? 'Vegetarian' : 'Non-Vegetarian'),
                  if (profile.hasGymTime)
                    _SummaryRow(
                        'Gym Time', _formatHour(profile.gymTimeHour!)),
                  _SummaryRow(
                      'Whey Protein', '${profile.proteinScoops} scoop/day'),
                  if (profile.takesCreatine)
                    const _SummaryRow('Creatine', 'Yes'),
                  if (profile.takesMassGainer &&
                      profile.goalType == GoalType.gain)
                    const _SummaryRow('Mass Gainer', 'Yes'),
                  _SummaryRow('Est. Duration',
                      '~${profile.estimatedWeeks} weeks'),
                  _SummaryRow('TDEE',
                      '${profile.tdee.round()} kcal/day'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Export Diet Chart
          _ActionCard(
            key: CoachMarkKeys.weightDashboardExport,
            icon: _exporting ? Icons.hourglass_top : Icons.restaurant_menu,
            label: 'Export Diet Chart',
            subtitle: _exporting
                ? 'Generating PDF...'
                : 'Personalized meal plan as PDF',
            color: Colors.teal,
            onTap: _exporting ? () {} : _exportDietChart,
          ),
          const SizedBox(height: 8),

          // Nav cards
          _ActionCard(
            icon: Icons.lightbulb_outline,
            label: profile.goalType == GoalType.gain
                ? 'Weight Gain Tips'
                : profile.goalType == GoalType.maintain
                    ? 'Maintain Tips'
                    : 'Weight Loss Tips',
            subtitle: 'Science-backed advice',
            color: Colors.amber.shade700,
            onTap: () => context.go('/gym/weight-loss/tips?goal=${profile.goalType.name}'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  double get _totalProtein {
    double total = state.trackedProtein;
    for (final scan in state.foodScans) {
      for (final item in scan.foodItems) {
        total += item.protein * item.quantity;
      }
    }
    return total;
  }

  double get _totalCarbs {
    double total = state.trackedCarbs;
    for (final scan in state.foodScans) {
      for (final item in scan.foodItems) {
        total += item.carbs * item.quantity;
      }
    }
    return total;
  }

  double get _totalFat {
    double total = state.trackedFat;
    for (final scan in state.foodScans) {
      for (final item in scan.foodItems) {
        total += item.fat * item.quantity;
      }
    }
    return total;
  }

  void _editProfile(BuildContext context) {
    final cubit = context.read<GymCubit>();
    cubit.deleteWeightLossProfile();
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.target,
    required this.consumed,
    required this.color,
  });

  final String label;
  final double target;
  final double consumed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${target.round()}g',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (consumed > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${consumed.round()}g eaten',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          )),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatHour(int hour) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  return '$h:00 $period';
}

class _ActivityPickerDialog extends StatefulWidget {
  const _ActivityPickerDialog({
    required this.selectedLevel,
    required this.onSelected,
  });

  final ActivityLevel selectedLevel;
  final ValueChanged<ActivityLevel> onSelected;

  @override
  State<_ActivityPickerDialog> createState() => _ActivityPickerDialogState();
}

class _ActivityPickerDialogState extends State<_ActivityPickerDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ActivityLevel> get _filtered {
    if (_query.isEmpty) return ActivityLevel.values;
    final q = _query.toLowerCase();
    return ActivityLevel.values
        .where((a) =>
            a.label.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q))
        .toList();
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
                  hintText: 'Search activity level...',
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
                        final level = items[i];
                        final isSelected = level == widget.selectedLevel;

                        return ListTile(
                          selected: isSelected,
                          title: Text(level.label),
                          subtitle: Text(level.description),
                          trailing: isSelected
                              ? Icon(Icons.check,
                                  color: theme.colorScheme.primary)
                              : null,
                          onTap: () {
                            widget.onSelected(level);
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
