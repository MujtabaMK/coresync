import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/workout_log_model.dart';
import '../providers/gym_provider.dart';

class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    context.read<GymCubit>().loadTodayWorkouts();
  }

  List<WorkoutType> get _filtered {
    if (_search.isEmpty) return WorkoutType.values;
    final q = _search.toLowerCase();
    return WorkoutType.values
        .where((t) => t.label.toLowerCase().contains(q))
        .toList();
  }

  void _selectWorkout(WorkoutType type) {
    final cubit = context.read<GymCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: _WorkoutDetailPage(workoutType: type),
            ),
          ),
        )
        .then((_) => cubit.loadTodayWorkouts());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Workout')),
      body: BlocBuilder<GymCubit, GymState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Today's summary
              if (state.todayWorkouts.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Workouts",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _SummaryChip(
                              icon: Icons.local_fire_department,
                              label:
                                  '${state.todayWorkoutCalories.round()} cal',
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            _SummaryChip(
                              icon: Icons.timer,
                              label: '${state.todayWorkoutMinutes} min',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...state.todayWorkouts.map((w) => Dismissible(
                              key: Key(w.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) {
                                context
                                    .read<GymCubit>()
                                    .deleteWorkoutLog(w.id);
                              },
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(w.workoutType.icon,
                                    color: theme.colorScheme.primary),
                                title: Text(w.workoutType.label),
                                subtitle: Text(
                                    '${w.durationMinutes} min \u00b7 ${w.intensity.label}'),
                                trailing: Text(
                                  '${w.effectiveCalories.round()} cal',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search workout...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 16),

              // Workout type grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final type = _filtered[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _selectWorkout(type),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(type.icon,
                                  size: 24,
                                  color:
                                      theme.colorScheme.onPrimaryContainer),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Workout Detail Page ────────────────────────────────────────────────────

class _WorkoutDetailPage extends StatefulWidget {
  const _WorkoutDetailPage({required this.workoutType});
  final WorkoutType workoutType;

  @override
  State<_WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<_WorkoutDetailPage> {
  WorkoutIntensity _intensity = WorkoutIntensity.moderate;
  final _durationCtrl = TextEditingController(text: '30');
  final _distanceCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  bool _manualCalories = false;

  @override
  void dispose() {
    _durationCtrl.dispose();
    _distanceCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  double get _weight =>
      context.read<GymCubit>().state.userWeight ?? 70.0;

  int get _duration => int.tryParse(_durationCtrl.text) ?? 0;

  double get _previewCalories {
    if (_manualCalories) {
      return double.tryParse(_caloriesCtrl.text) ?? 0;
    }
    return widget.workoutType.defaultMET *
        _intensity.multiplier *
        _weight *
        (_duration / 60);
  }

  double? get _speed {
    final dist = double.tryParse(_distanceCtrl.text);
    if (dist == null || dist <= 0 || _duration <= 0) return null;
    return dist / (_duration / 60);
  }

  Future<void> _save() async {
    if (_duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid duration')),
      );
      return;
    }

    final workout = WorkoutLogModel(
      id: const Uuid().v4(),
      workoutType: widget.workoutType,
      intensity: _intensity,
      durationMinutes: _duration,
      userWeightKg: _weight,
      distanceKm: double.tryParse(_distanceCtrl.text),
      speedKmh: _speed,
      caloriesBurnt: _manualCalories
          ? double.tryParse(_caloriesCtrl.text)
          : null,
    );

    try {
      await context.read<GymCubit>().saveWorkoutLog(workout);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${widget.workoutType.label} logged - ${workout.effectiveCalories.round()} cal')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.workoutType.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Icon header
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.workoutType.icon,
                  size: 48, color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 24),

          // Intensity selector
          Text('Intensity', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<WorkoutIntensity>(
            segments: WorkoutIntensity.values
                .map((i) => ButtonSegment(
                      value: i,
                      label: Text(i.label),
                    ))
                .toList(),
            selected: {_intensity},
            onSelectionChanged: (s) =>
                setState(() => _intensity = s.first),
          ),
          const SizedBox(height: 16),

          // Duration
          TextFormField(
            controller: _durationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration',
              suffixText: 'minutes',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Distance (optional)
          TextFormField(
            controller: _distanceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Distance (optional)',
              suffixText: 'km',
              border: const OutlineInputBorder(),
              helperText: _speed != null
                  ? 'Speed: ${_speed!.toStringAsFixed(1)} km/h'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Calorie preview card
          Card(
            color: Colors.orange.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.local_fire_department,
                      size: 32, color: Colors.orange),
                  const SizedBox(height: 8),
                  Text(
                    '${_previewCalories.round()}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'calories will be burnt',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Manual calories toggle
          SwitchListTile(
            title: const Text('Enter calories directly'),
            value: _manualCalories,
            onChanged: (v) => setState(() => _manualCalories = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_manualCalories)
            TextFormField(
              controller: _caloriesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories burnt',
                suffixText: 'cal',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 24),

          // Save
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Log Workout'),
            ),
          ),
        ],
      ),
    );
  }
}
