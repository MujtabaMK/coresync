import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/step_counter_service.dart';
import '../providers/gym_provider.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> with WidgetsBindingObserver {
  static const _goal = 10000;

  final _service = StepCounterService.instance;
  late final GymCubit _gymCubit;

  StreamSubscription<int>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  int _steps = 0;
  bool _permissionDenied = false;
  bool _initializing = true;
  PedestrianStatus _status = PedestrianStatus.unknown;

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

    // Listen for step updates from the service
    _stepSub = _service.stepsStream.listen((steps) {
      if (mounted) {
        setState(() => _steps = steps);
        _gymCubit.saveSteps(DateTime.now(), steps);
      }
    });

    _statusSub = _service.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });

    // Sync historical steps in background
    _service.syncHistoricalSteps(
      (date, steps) => _gymCubit.saveSteps(date, steps),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gymState = context.watch<GymCubit>().state;
    final weight = gymState.userWeight ?? 70.0;
    final calories = (_steps * 0.04 * weight / 70).round();
    final minutes = (_steps / 100).round();

    final stepsProgress = (_steps / _goal).clamp(0.0, 1.0);
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
                          '/ $_goal steps',
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
          // Pedestrian status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _status == PedestrianStatus.walking
                    ? Icons.directions_walk_rounded
                    : Icons.accessibility_new_rounded,
                size: 28,
                color: _status == PedestrianStatus.walking
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                switch (_status) {
                  PedestrianStatus.walking => 'Walking',
                  PedestrianStatus.stopped => 'Stopped',
                  PedestrianStatus.unknown => 'Unknown',
                },
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _status == PedestrianStatus.walking
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
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
                      Platform.isAndroid
                          ? 'Steps are read from your device\'s motion sensor.'
                          : 'Steps are read from your device\'s motion sensor.',
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