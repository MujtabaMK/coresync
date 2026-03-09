import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health/health.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/gym_provider.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> with WidgetsBindingObserver {
  static const _goal = 10000;

  final _pedometer = Pedometer();
  late final GymCubit _gymCubit;

  StreamSubscription<int>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  int _steps = 0;
  int _platformBaseline = 0; // today's steps from Health Connect (Android) or CMPedometer (iOS)
  int? _streamBaseline; // first raw value from step stream
  bool _hasPlatformBaseline = false;
  bool _permissionDenied = false;
  bool _sensorError = false;
  bool _initializing = true;
  PedestrianStatus _status = PedestrianStatus.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gymCubit = context.read<GymCubit>();
    _initPedometer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-query Health Connect / CMPedometer when app is resumed
    if (state == AppLifecycleState.resumed) {
      _refreshStepsFromPlatform();
    }
  }

  /// Query Health Connect (Android) or CMPedometer (iOS) for today's total steps.
  Future<int?> _getTodayStepsFromPlatform() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    if (Platform.isAndroid) {
      try {
        final health = Health();
        await health.configure();
        final steps = await health.getTotalStepsInInterval(midnight, now);
        return steps;
      } catch (e) {
        debugPrint('Health Connect getSteps error: $e');
        return null;
      }
    } else if (Platform.isIOS) {
      try {
        return await _pedometer.getStepCount(from: midnight, to: now);
      } catch (e) {
        debugPrint('CMPedometer getStepCount error: $e');
        return null;
      }
    }
    return null;
  }

  /// Refresh step count from the platform (called on init and on app resume).
  Future<void> _refreshStepsFromPlatform() async {
    final steps = await _getTodayStepsFromPlatform();
    if (steps != null && mounted) {
      _platformBaseline = steps;
      _hasPlatformBaseline = true;
      // Reset stream baseline so delta restarts from 0
      _streamBaseline = null;
      setState(() => _steps = _platformBaseline);
      _gymCubit.saveSteps(DateTime.now(), _platformBaseline);
    }
  }

  Future<void> _initPedometer() async {
    // Request activity recognition permission
    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        if (mounted) setState(() { _permissionDenied = true; _initializing = false; });
        return;
      }

      // Request Health Connect permission for steps
      try {
        final health = Health();
        await health.configure();
        final authorized = await health.requestAuthorization(
          [HealthDataType.STEPS],
        );
        if (!authorized) {
          debugPrint('Health Connect authorization denied');
        }
      } catch (e) {
        debugPrint('Health Connect init error: $e');
      }
    }

    // Load today's previously saved steps from Firestore as fallback
    try {
      final saved = await _gymCubit.repository.getStepsForDate(DateTime.now());
      if (mounted) setState(() => _steps = saved);
    } catch (_) {}

    // Get today's actual step count from Health Connect (Android) or CMPedometer (iOS)
    await _refreshStepsFromPlatform();

    if (mounted) setState(() => _initializing = false);

    // Listen for live step updates (real-time while app is open)
    _stepSub = _pedometer.stepCountStream().listen(
      (rawSteps) {
        _streamBaseline ??= rawSteps;
        final delta = rawSteps - _streamBaseline!;

        // Platform baseline (from Health Connect or CMPedometer) + delta since we started listening
        final totalToday = _hasPlatformBaseline
            ? _platformBaseline + delta
            : _steps + delta;

        if (mounted) {
          setState(() => _steps = totalToday);
          _gymCubit.saveSteps(DateTime.now(), totalToday);
        }
      },
      onError: (error) {
        debugPrint('Step count error: $error');
        if (mounted) setState(() => _sensorError = true);
      },
    );

    // Listen for pedestrian status
    _statusSub = _pedometer.pedestrianStatusStream().listen(
      (status) {
        if (mounted) setState(() => _status = status);
      },
      onError: (error) {
        debugPrint('Pedestrian status error: $error');
      },
    );

    // Sync historical steps in background
    _syncHistoricalSteps();
  }

  Future<void> _syncHistoricalSteps() async {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final today = DateTime(now.year, now.month, now.day);

    if (Platform.isIOS) {
      for (var d = today.subtract(const Duration(days: 1));
          !d.isBefore(firstOfMonth);
          d = d.subtract(const Duration(days: 1))) {
        try {
          final dayEnd = d.add(const Duration(days: 1));
          final steps = await _pedometer.getStepCount(from: d, to: dayEnd);
          if (steps > 0) {
            await _gymCubit.saveSteps(d, steps);
          }
        } catch (e) {
          break;
        }
      }
    } else if (Platform.isAndroid) {
      try {
        final health = Health();
        await health.configure();
        for (var d = today.subtract(const Duration(days: 1));
            !d.isBefore(firstOfMonth);
            d = d.subtract(const Duration(days: 1))) {
          final dayEnd = d.add(const Duration(days: 1));
          final steps = await health.getTotalStepsInInterval(d, dayEnd);
          if (steps != null && steps > 0) {
            await _gymCubit.saveSteps(d, steps);
          }
        }
      } catch (e) {
        debugPrint('Health Connect historical sync error: $e');
      }
    }
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

    if (_sensorError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64,
                  color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Step sensor not available on this device.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
                          ? 'Steps update in real-time as you walk. Start walking to see your count increase.'
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
