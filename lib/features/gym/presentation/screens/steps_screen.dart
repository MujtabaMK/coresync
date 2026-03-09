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
    final progress = (_steps / _goal).clamp(0.0, 1.0);

    // Color: red if 0, green if goal reached, amber if in progress
    final progressColor = _steps == 0
        ? Colors.red
        : _steps >= _goal
            ? Colors.green
            : Colors.amber.shade700;

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
          // Circular progress ring
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _StepsProgressPainter(
                progress: progress,
                color: progressColor,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_steps',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
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
          const SizedBox(height: 32),
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

class _StepsProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _StepsProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StepsProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}