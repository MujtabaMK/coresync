import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/battery_optimization_service.dart';
import '../../data/step_counter_service.dart';
import '../providers/gym_provider.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> with WidgetsBindingObserver {
  final _service = StepCounterService.instance;
  final _batteryService = BatteryOptimizationService.instance;
  late final GymCubit _gymCubit;

  StreamSubscription<int>? _stepSub;
  StreamSubscription<Activity>? _activitySub;

  int _steps = 0;
  bool _permissionDenied = false;
  bool _initializing = true;
  ActivityType _activityType = ActivityType.UNKNOWN;

  Future<bool>? _batteryOptFuture;

  /// Returns BMI-based step goal, or null if user metrics aren't loaded yet.
  int? _computeStepGoal() {
    final gymState = _gymCubit.state;
    final heightCm = gymState.userHeight;
    if (heightCm != null && gymState.userWeight != null) {
      final heightM = heightCm / 100;
      final bmi = gymState.userWeight! / (heightM * heightM);
      if (bmi < 18.5) return 8000;
      if (bmi < 25) return 10000;
      if (bmi < 30) return 12000;
      return 15000;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gymCubit = context.read<GymCubit>();
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _service.refreshOnResume();
      // Refresh battery optimization status after returning from settings
      if (Platform.isAndroid) {
        setState(() {
          _batteryOptFuture = _batteryService.isIgnoringBatteryOptimizations();
        });
      }
    }
  }

  Future<void> _init() async {
    // Load today's previously saved steps from Firestore as fallback
    try {
      final saved = await _gymCubit.repository.getStepsForDate(DateTime.now());
      if (mounted) setState(() => _steps = saved);
      _service.setMinSteps(saved);
    } catch (_) {}

    final ok = await _service.initialize();
    if (!ok) {
      if (mounted) setState(() { _permissionDenied = true; _initializing = false; });
      return;
    }

    // Use current value from service
    if (_service.currentSteps > 0) {
      setState(() => _steps = _service.currentSteps);
    }

    if (mounted) setState(() => _initializing = false);

    // Save today's step goal (metrics may not be loaded yet from loadAll,
    // so _saveTodaysGoals() in GymCubit handles persistent storage;
    // here we just save the current steps with goal if available).
    final goal = _computeStepGoal();
    if (_steps > 0) {
      _gymCubit.saveSteps(DateTime.now(), _steps, goalSteps: goal);
    }

    // Silently request battery optimization exemption if not already granted
    if (Platform.isAndroid) {
      _batteryService.requestIgnoreBatteryOptimizations();
    }

    // Listen for step updates from the service
    _stepSub = _service.stepsStream.listen((steps) {
      if (mounted && _activityType != ActivityType.IN_VEHICLE) {
        setState(() => _steps = steps);
        _gymCubit.saveSteps(DateTime.now(), steps, goalSteps: _computeStepGoal());
      }
    });

    _activitySub = FlutterActivityRecognition.instance.activityStream.listen(
      (activity) {
        if (mounted) setState(() => _activityType = activity.type);
      },
      onError: (_) {},
    );

    // Sync historical steps in background — only set goalSteps for today,
    // not for historical dates (their goals should stay as originally saved).
    _service.syncHistoricalSteps((date, steps) async {
      final normalized = DateTime(date.year, date.month, date.day);
      final now = DateTime.now();
      final todayNorm = DateTime(now.year, now.month, now.day);
      final goal = normalized == todayNorm ? _computeStepGoal() : null;
      await _gymCubit.saveSteps(date, steps, goalSteps: goal);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepSub?.cancel();
    _activitySub?.cancel();
    super.dispose();
  }

  IconData _activityIcon(ActivityType type) => switch (type) {
    ActivityType.WALKING => Icons.directions_walk_rounded,
    ActivityType.RUNNING => Icons.directions_run_rounded,
    ActivityType.ON_BICYCLE => Icons.directions_bike_rounded,
    ActivityType.IN_VEHICLE => Icons.directions_car_rounded,
    ActivityType.STILL => Icons.accessibility_new_rounded,
    _ => Icons.help_outline_rounded,
  };

  String _activityLabel(ActivityType type) => switch (type) {
    ActivityType.WALKING => 'Walking',
    ActivityType.RUNNING => 'Running',
    ActivityType.ON_BICYCLE => 'Cycling',
    ActivityType.IN_VEHICLE => 'In Vehicle',
    ActivityType.STILL => 'Still',
    _ => 'Unknown',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gymState = context.watch<GymCubit>().state;
    final weight = gymState.userWeight ?? 70.0;
    final heightCm = gymState.userHeight;
    final calories = (_steps * 0.04 * weight / 70).round();
    final minutes = (_steps / 100).round();

    // Personalized step goal based on BMI (if height & weight available)
    final goal = _computeStepGoal() ?? 10000;

    // Km walked: stride length ≈ height * 0.415, default 0.75m
    final strideLengthM = heightCm != null ? heightCm * 0.415 / 100 : 0.75;
    final kmWalked = _steps * strideLengthM / 1000;

    final stepsProgress = (_steps / goal).clamp(0.0, 1.0);
    final minutesProgress = (minutes / 60).clamp(0.0, 1.0); // 60 min goal
    final caloriesProgress = (calories / 500).clamp(0.0, 1.0); // 500 kcal goal

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sensors_off, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Permission Required',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Activity recognition permission is needed to count steps.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Battery optimization warning banner
          if (Platform.isAndroid)
            FutureBuilder<bool>(
              future: _batteryOptFuture ??= _batteryService.isIgnoringBatteryOptimizations(),
              builder: (context, snapshot) {
                final isIgnoring = snapshot.data ?? true;
                if (isIgnoring) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () async {
                      await _batteryService.openOemBatterySettings();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: theme.colorScheme.onErrorContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Battery optimization may stop step tracking. Tap to fix.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: theme.colorScheme.onErrorContainer),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          // 3-ring activity progress (Samsung Health style)
          SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(
              painter: _ActivityRingsPainter(
                stepsProgress: stepsProgress,
                minutesProgress: minutesProgress,
                caloriesProgress: caloriesProgress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_steps',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '/ $goal steps',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stats row: Steps, Minutes, Calories (Samsung Health style)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _HealthStatColumn(
                icon: Icons.directions_walk,
                value: '$_steps',
                label: 'steps',
                color: Colors.green,
              ),
              _HealthStatColumn(
                icon: Icons.straighten,
                value: kmWalked.toStringAsFixed(2),
                label: 'km',
                color: Colors.orange,
              ),
              _HealthStatColumn(
                icon: Icons.timer_outlined,
                value: '$minutes',
                label: 'mins',
                color: Colors.blue,
              ),
              _HealthStatColumn(
                icon: Icons.local_fire_department,
                value: '$calories',
                label: 'kcal',
                color: Colors.pinkAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Activity status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _activityIcon(_activityType),
                size: 28,
                color: _activityType == ActivityType.STILL || _activityType == ActivityType.UNKNOWN
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _activityLabel(_activityType),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _activityType == ActivityType.STILL || _activityType == ActivityType.UNKNOWN
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      heightCm != null && gymState.userWeight != null
                          ? 'Your daily goal of $goal steps is personalized based on your BMI. Distance is estimated from your height.'
                          : 'Set your height & weight in the gym section to get a personalized step goal.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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

class _HealthStatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HealthStatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  final double stepsProgress;
  final double minutesProgress;
  final double caloriesProgress;
  final Color backgroundColor;

  _ActivityRingsPainter({
    required this.stepsProgress,
    required this.minutesProgress,
    required this.caloriesProgress,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 16.0;
    const gap = 5.0;

    // 3 concentric rings: outer = steps (green), middle = mins (blue), inner = kcal (pink)
    final rings = [
      (radius: min(size.width, size.height) / 2 - 12, progress: stepsProgress, color: Colors.green),
      (radius: min(size.width, size.height) / 2 - 12 - strokeWidth - gap, progress: minutesProgress, color: Colors.blue),
      (radius: min(size.width, size.height) / 2 - 12 - (strokeWidth + gap) * 2, progress: caloriesProgress, color: Colors.pinkAccent),
    ];

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final ring in rings) {
      // Draw background ring
      canvas.drawCircle(center, ring.radius, bgPaint);

      // Draw progress arc
      if (ring.progress > 0) {
        final progressPaint = Paint()
          ..color = ring.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: ring.radius),
          -pi / 2,
          2 * pi * ring.progress,
          false,
          progressPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter oldDelegate) {
    return oldDelegate.stepsProgress != stepsProgress ||
        oldDelegate.minutesProgress != minutesProgress ||
        oldDelegate.caloriesProgress != caloriesProgress ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}