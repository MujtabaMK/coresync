import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/gym_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';
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
  StreamSubscription<void>? _healthMetricsSub;
  StreamSubscription<Activity>? _activitySub;

  int _steps = 0;
  bool _permissionDenied = false;
  bool _initializing = true;
  ActivityType _activityType = ActivityType.UNKNOWN;
  ActivityType? _osActivityType; // from OS activity recognition
  Future<bool>? _batteryOptFuture;

  // Step-rate tracking for instant activity inference
  Timer? _stillDebounce; // fires after inactivity to set "Still"
  final List<DateTime> _recentStepTimes = []; // timestamps of recent steps

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
  int _coachMarkVersion = -1;

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
      _service.refreshOnResume(); // also refreshes health metrics
      // Refresh battery optimization status after returning from settings
      if (Platform.isAndroid) {
        setState(() {
          _batteryOptFuture = _batteryService.isIgnoringBatteryOptimizations();
        });
      }
    }
  }

  Future<void> _init() async {
    // 1. Show Firestore data IMMEDIATELY — highest priority source
    try {
      final saved = await _gymCubit.repository.getStepsForDate(DateTime.now());
      if (saved > 0) {
        _service.setMinSteps(saved);
        if (mounted) setState(() { _steps = saved; _initializing = false; });
      }
    } catch (_) {}

    // 2. Listen for live updates BEFORE initialize() so we catch every update
    _stepSub = _service.stepsStream.listen((steps) {
      if (!mounted) return;
      final prevSteps = _steps;
      if (_activityType != ActivityType.IN_VEHICLE && steps > _steps) {
        setState(() => _steps = steps);
        _gymCubit.saveSteps(DateTime.now(), steps, goalSteps: _computeStepGoal());
      }

      // Record step timestamps for rate calculation
      final now = DateTime.now();
      final newStepCount = steps - prevSteps;
      for (var i = 0; i < newStepCount.clamp(0, 10); i++) {
        _recentStepTimes.add(now);
      }
      // Keep only last 5 seconds of data
      _recentStepTimes.removeWhere(
        (t) => now.difference(t).inSeconds > 5,
      );

      // Infer activity from step rate instantly
      _inferActivity();

      // Reset the "still" debounce — if no steps for 3s, mark as Still
      _stillDebounce?.cancel();
      _stillDebounce = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        _recentStepTimes.clear();
        _inferActivity();
      });
    });

    // 2b. Rebuild UI when HealthKit kcal/distance refresh (every 30s)
    _healthMetricsSub = _service.healthMetricsStream.listen((_) {
      if (mounted) setState(() {});
    });

    // UI is ready — show whatever we have (even 0)
    if (mounted && _initializing) {
      setState(() => _initializing = false);
    }

    // 3. Initialize sensor + Health Connect — fire-and-forget so UI stays smooth
    _initSensors();
  }

  /// Runs the heavy sensor/Health Connect init without blocking the UI.
  Future<void> _initSensors() async {
    // Show permission guide coach mark before the system dialog (first visit only)
    final box = Hive.box('app_settings');
    if (box.get('step_permission_guide_shown', defaultValue: false) != true) {
      if (mounted) {
        final completer = Completer<void>();
        // Wait a frame so the rings widget is laid out
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        final targets = stepPermissionCoachTargets()
            .where((t) => t.keyTarget?.currentContext != null)
            .toList();

        if (targets.isNotEmpty) {
          TutorialCoachMark(
            targets: targets,
            colorShadow: Colors.black,
            opacityShadow: 0.8,
            textSkip: 'GOT IT',
            alignSkip: Alignment.topRight,
            paddingFocus: 10,
            onSkip: () {
              if (!completer.isCompleted) completer.complete();
              return true;
            },
            onFinish: () {
              if (!completer.isCompleted) completer.complete();
            },
            onClickOverlay: (_) {},
          ).show(context: context);

          await completer.future;
        }

        box.put('step_permission_guide_shown', true);
      }
    }

    if (!mounted) return;

    final ok = await _service.initialize();
    if (!ok) {
      if (mounted) setState(() { _permissionDenied = true; _initializing = false; });
      return;
    }

    // Check activity recognition permission (especially important on iOS)
    final activityPermission =
        await FlutterActivityRecognition.instance.checkPermission();
    if (activityPermission == PermissionRequestResult.PERMANENTLY_DENIED) {
      // On iOS, motion permission was denied — activity detection won't work.
      // Request via settings; on iOS the permission prompt is automatic on
      // first access, so this only fires if the user previously denied it.
      debugPrint('Activity recognition permission denied');
    }

    // Subscribe to activity recognition
    _activitySub = FlutterActivityRecognition.instance.activityStream.listen(
      (activity) {
        if (mounted) {
          _osActivityType = activity.type;
          if (activity.type == ActivityType.ON_BICYCLE ||
              activity.type == ActivityType.IN_VEHICLE) {
            setState(() => _activityType = activity.type);
          }
        }
      },
      onError: (error) {
        debugPrint('Activity recognition error: $error');
      },
    );

    // Use the best known value after all sources are checked
    if (_service.currentSteps > _steps && mounted) {
      setState(() => _steps = _service.currentSteps);
    }
    if (mounted) setState(() => _initializing = false);

    // Save today's step goal
    final goal = _computeStepGoal();
    if (_steps > 0) {
      _gymCubit.saveSteps(DateTime.now(), _steps, goalSteps: goal);
    }

    // Silently request battery optimization exemption if not already granted
    if (Platform.isAndroid) {
      _batteryService.requestIgnoreBatteryOptimizations();
    }

    // Show battery optimization coach mark (Android only)
    if (Platform.isAndroid && mounted) {
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        CoachMarkService.showIfNeeded(
          context: context,
          screenKey: 'step_battery_guide_shown',
          targets: batteryCoachTargets(),
        );
      });
    }

    // Sync historical steps in background
    _service.syncHistoricalSteps((date, steps) async {
      final normalized = DateTime(date.year, date.month, date.day);
      final now = DateTime.now();
      final todayNorm = DateTime(now.year, now.month, now.day);
      final goal = normalized == todayNorm ? _computeStepGoal() : null;
      await _gymCubit.saveSteps(date, steps, goalSteps: goal);
    });
  }

  void _inferActivity() {
    // OS overrides for non-step activities
    final os = _osActivityType;
    if (os == ActivityType.ON_BICYCLE || os == ActivityType.IN_VEHICLE) {
      if (_activityType != os) setState(() => _activityType = os!);
      return;
    }

    ActivityType inferred;
    if (_recentStepTimes.isEmpty) {
      inferred = ActivityType.STILL;
    } else {
      // Calculate steps/min from recent timestamps (last 5s window)
      final window = _recentStepTimes.length;
      final span = _recentStepTimes.last.difference(_recentStepTimes.first).inMilliseconds;
      final stepsPerMin = span > 0 ? (window / span) * 60000 : window * 60.0;
      if (stepsPerMin >= 140) {
        inferred = ActivityType.RUNNING;
      } else {
        inferred = ActivityType.WALKING;
      }
    }

    if (inferred != _activityType) {
      setState(() => _activityType = inferred);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stillDebounce?.cancel();
    _stepSub?.cancel();
    _healthMetricsSub?.cancel();
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
  void _triggerCoachMark() {
    final v = CoachMarkService.resetVersion;
    if (_coachMarkVersion == v) return;
    _coachMarkVersion = v;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        CoachMarkService.showIfNeeded(
          context: context,
          screenKey: 'coach_mark_steps_shown',
          targets: stepsCoachTargets(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _triggerCoachMark();
    final theme = Theme.of(context);
    final gymState = context.watch<GymCubit>().state;
    final weight = gymState.userWeight ?? 70.0;
    final heightCm = gymState.userHeight;
    // Prefer Apple Health active energy when available; fall back to formula
    final healthCalories = _service.cachedActiveEnergy?.round() ?? 0;
    final calories = healthCalories > 0
        ? healthCalories
        : StepCounterService.calculateStepCalories(
            steps: _steps,
            weightKg: weight,
            heightCm: heightCm,
          ).round();
    final minutes = (_steps / 100).round();

    // Personalized step goal based on BMI (if height & weight available)
    final goal = _computeStepGoal() ?? 10000;

    // Prefer Apple Health distance when available; fall back to formula
    final healthDistanceKm = _service.cachedDistanceKm ?? 0.0;
    final kmWalked = healthDistanceKm > 0
        ? healthDistanceKm
        : _steps * (heightCm != null ? heightCm * 0.415 / 100 : 0.75) / 1000;

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
                    key: CoachMarkKeys.stepsBattery,
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
            key: CoachMarkKeys.stepsRings,
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
            key: CoachMarkKeys.stepsStats,
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