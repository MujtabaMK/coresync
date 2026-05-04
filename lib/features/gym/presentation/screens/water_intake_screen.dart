import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/gym_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';
import '../../data/water_boost_foods_data.dart';
import '../providers/gym_provider.dart';

class WaterIntakeScreen extends StatefulWidget {
  const WaterIntakeScreen({super.key});

  @override
  State<WaterIntakeScreen> createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen>
    with TickerProviderStateMixin {
  bool _showSetup = false;
  int _coachMarkVersion = -1;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Animation
  late AnimationController _animController;
  late AnimationController _waveController;
  late Animation<double> _fillAnimation;
  double _previousProgress = 0;
  bool _fillInitialized = false;

  // Pour animation controllers
  late AnimationController _capController;
  late AnimationController _pourBottleController;
  late AnimationController _pourStreamController;
  late AnimationController _streamWaveController;
  late AnimationController _pourCapController;
  bool _isPourAnimating = false;
  bool _pourComplete = false; // stays true so bottle remains empty during exit

  // Accelerometer tilt
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _tiltX = 0.0;

  static const List<int> _mlOptions = [
    100, 150, 200, 250, 300, 350, 400, 450, 500, 750, 1000, 1500, 2000,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fillAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _capController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pourBottleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pourStreamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _streamWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat();
    _pourCapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Listen to accelerometer on mobile only
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _accelSub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 50),
      ).listen((event) {
        setState(() {
          _tiltX = _tiltX * 0.8 + event.x * 0.2;
        });
      });
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _animController.dispose();
    _waveController.dispose();
    _capController.dispose();
    _pourBottleController.dispose();
    _pourStreamController.dispose();
    _streamWaveController.dispose();
    _pourCapController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _openSetup(GymState state) {
    if (state.userHeight != null) {
      _heightController.text = state.userHeight!.toStringAsFixed(0);
    }
    if (state.userWeight != null) {
      _weightController.text = state.userWeight!.toStringAsFixed(0);
    }
    setState(() => _showSetup = true);
  }

  Future<void> _saveMetrics() async {
    if (!_formKey.currentState!.validate()) return;

    final height = double.parse(_heightController.text.trim());
    final weight = double.parse(_weightController.text.trim());

    await context.read<GymCubit>().saveUserMetrics(
      height: height,
      weight: weight,
    );

    if (mounted) {
      setState(() => _showSetup = false);
    }
  }

  void _animateToProgress(double newProgress) {
    setState(() {
      _fillAnimation = Tween<double>(
        begin: _previousProgress,
        end: newProgress,
      ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
      );
    });
    _animController.forward(from: 0);
    _previousProgress = newProgress;
  }

  Future<void> _playPourSequence(double newProgress, int selectedMl) async {
    setState(() {
      _isPourAnimating = true;
      _pourComplete = false;
    });
    try {
      // Phase 1: Main cap unscrews
      await _capController.forward();
      // Phase 2: Pouring bottle enters
      await _pourBottleController.forward();
      // Phase 3: Pouring bottle cap unscrews
      await _pourCapController.forward();
      // Phase 4: Stream pours + fill rises
      _animateToProgress(newProgress);
      context.read<GymCubit>().addWater(selectedMl);
      await _pourStreamController.forward();
      // Mark pour done so bottle stays empty during exit
      setState(() => _pourComplete = true);
      // Phase 5: Brief hold
      await Future.delayed(const Duration(milliseconds: 200));
      // Phase 6: Stream stops + pour cap screws back
      await _pourStreamController.reverse();
      await _pourCapController.reverse();
      // Phase 7: Pouring bottle exits
      await _pourBottleController.reverse();
      // Phase 8: Main cap screws back on
      await _capController.reverse();
    } on TickerCanceled catch (_) {
      // Widget disposed during animation
    } finally {
      if (mounted) {
        setState(() {
          _isPourAnimating = false;
          _pourComplete = false;
        });
      }
    }
  }

  Future<void> _showMlPicker({required bool isAdd}) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAdd ? 'Add Water' : 'Remove Water',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select amount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _mlOptions.map((ml) {
                    return ActionChip(
                      label: Text('$ml ml'),
                      onPressed: () => Navigator.pop(ctx, ml),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    final state = context.read<GymCubit>().state;
    final goalMl = state.effectiveWaterGoalMl;

    if (isAdd) {
      final newMl = state.waterMl + selected;
      final newProgress =
          goalMl > 0 ? (newMl / goalMl).clamp(0.0, 1.0) : 0.0;
      _playPourSequence(newProgress, selected);
    } else {
      final newMl = (state.waterMl - selected).clamp(0, state.waterMl);
      final newProgress =
          goalMl > 0 ? (newMl / goalMl).clamp(0.0, 1.0) : 0.0;
      _animateToProgress(newProgress);
      context.read<GymCubit>().removeWater(selected);
    }
  }

  @override
  void _triggerCoachMark() {
    final v = CoachMarkService.resetVersion;
    if (_coachMarkVersion == v) return;
    _coachMarkVersion = v;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        CoachMarkService.showIfNeeded(
          context: context,
          screenKey: 'coach_mark_water_shown',
          targets: waterCoachTargets(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _triggerCoachMark();
    final theme = Theme.of(context);

    return BlocConsumer<GymCubit, GymState>(
      listenWhen: (prev, curr) => prev.waterMl != curr.waterMl,
      listener: (context, state) {
        if (!_fillInitialized) return;
        final goalMl = state.effectiveWaterGoalMl;
        final progress =
            goalMl > 0 ? (state.waterMl / goalMl).clamp(0.0, 1.0) : 0.0;
        if ((_previousProgress - progress).abs() > 0.01 &&
            !_animController.isAnimating &&
            !_isPourAnimating) {
          _animateToProgress(progress);
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final needsSetup = state.userHeight == null || state.userWeight == null;

        if (needsSetup || _showSetup) {
          return _buildSetupForm(theme, state);
        }

        return _buildTracker(theme, state);
      },
    );
  }

  Widget _buildSetupForm(ThemeData theme, GymState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.water_drop, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Set Up Water Tracker',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your height and weight to calculate your daily water intake goal.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.height),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your height';
                }
                final v = double.tryParse(value.trim());
                if (v == null || v <= 0 || v > 300) {
                  return 'Please enter a valid height';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your weight';
                }
                final v = double.tryParse(value.trim());
                if (v == null || v <= 0 || v > 500) {
                  return 'Please enter a valid weight';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveMetrics,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracker(ThemeData theme, GymState state) {
    final currentMl = state.waterMl;
    final goalMl = state.effectiveWaterGoalMl;
    final progress = goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.0) : 0.0;

    // Initialize fill on first build with existing data
    if (!_fillInitialized) {
      _fillInitialized = true;
      _previousProgress = progress;
      _fillAnimation = AlwaysStoppedAnimation(progress);
    }

    final progressColor = currentMl == 0
        ? Colors.red
        : currentMl >= goalMl
            ? Colors.green
            : Colors.amber.shade700;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Settings row
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openSetup(state),
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Settings'),
            ),
          ),
          // Water bottle with fill animation
          SizedBox(
            key: CoachMarkKeys.waterBottle,
            width: 260,
            height: 370,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _fillAnimation,
                _waveController,
                _capController,
                _pourBottleController,
                _pourStreamController,
                _streamWaveController,
                _pourCapController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _CuteWaterBottlePainter(
                    progress: _fillAnimation.value,
                    wavePhase: _waveController.value,
                    color: progressColor,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    tiltX: _tiltX,
                    capOpenProgress: _capController.value,
                    pourBottleProgress: _pourBottleController.value,
                    pourStreamProgress: _pourStreamController.value,
                    pourComplete: _pourComplete,
                    streamWavePhase: _streamWaveController.value,
                    pourCapProgress: _pourCapController.value,
                  ),
                  child: child,
                );
              },
              child: Transform.rotate(
                angle: _tiltX.clamp(-10.0, 10.0) * -0.04,
                alignment: Alignment.bottomCenter,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 110),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$currentMl',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                        Text(
                          '/ $goalMl ml',
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
          const SizedBox(height: 16),
          // Glass equivalent
          Text(
            '${(currentMl / 250).toStringAsFixed(1)} glasses',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          // Add / Remove buttons (tap opens popup)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !_isPourAnimating && currentMl > 0
                      ? () => _showMlPicker(isAdd: false)
                      : null,
                  icon: const Icon(Icons.remove),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: CoachMarkKeys.waterAddBtn,
                  onPressed: !_isPourAnimating
                      ? () => _showMlPicker(isAdd: true)
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Reset button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: !_isPourAnimating
                  ? () {
                      _animateToProgress(0);
                      context.read<GymCubit>().resetWaterIntake();
                    }
                  : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Today'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Info
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Base: ${state.userWeight?.toStringAsFixed(0)} kg x 33 = ${state.dailyWaterGoalMl} ml',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (state.activityWaterBoostMl > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '+ ${state.activityWaterBoostMl} ml (${state.weightLossProfile!.activityLevel.label})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                        ],
                        if (state.waterBoostMl > 0) ...[
                          const SizedBox(height: 4),
                          ...state.trackedFoods
                              .where((f) => waterBoostForFood(f.name) > 0)
                              .map((f) => Text(
                                    '+ ${waterBoostForFood(f.name)} ml (${f.name})',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  )),
                        ],
                        if (state.activityWaterBoostMl > 0 ||
                            state.waterBoostMl > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Total goal: $goalMl ml',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
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
        ],
      ),
    );
  }
}

/// Cute rounded water bottle with cap, pouring animation
class _CuteWaterBottlePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color color;
  final Color backgroundColor;
  final double tiltX;
  final double capOpenProgress;
  final double pourBottleProgress;
  final double pourStreamProgress;
  final bool pourComplete;
  final double streamWavePhase;
  final double pourCapProgress;

  _CuteWaterBottlePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
    required this.backgroundColor,
    this.tiltX = 0.0,
    this.capOpenProgress = 0.0,
    this.pourBottleProgress = 0.0,
    this.pourStreamProgress = 0.0,
    this.pourComplete = false,
    this.streamWavePhase = 0.0,
    this.pourCapProgress = 0.0,
  });

  // Bottle constants
  static const _bw = 180.0;
  static const _bh = 280.0;

  // Pouring bottle constants (bigger, realistic water bottle)
  static const _pbBodyW = 60.0;
  static const _pbBodyH = 55.0;
  static const _pbNeckW = 18.0;
  static const _pbNeckH = 22.0;
  static const _pbCapW = 22.0;
  static const _pbCapH = 8.0;
  static const _pbShoulderH = 12.0; // shoulder taper from body to neck
  static const _pbSpoutDist = _pbBodyH + _pbShoulderH + _pbNeckH;
  static const _pourStartX = 240.0;
  static const _pourStartY = -90.0;
  static const _pourEndX = 175.0;
  static const _pourEndY = -25.0;
  static const _pourMaxTilt = -1.8;

  @override
  void paint(Canvas canvas, Size size) {
    final bx = (size.width - _bw) / 2;
    final by = size.height - _bh;

    // Translate so main bottle draws at (0,0) to (_bw, _bh)
    canvas.save();
    canvas.translate(bx, by);

    // Tilt entire bottle based on accelerometer (pivot at bottom-center)
    final bottleTilt = tiltX.clamp(-10.0, 10.0) * -0.04;
    canvas.translate(_bw / 2, _bh);
    canvas.rotate(bottleTilt);
    canvas.translate(-_bw / 2, -_bh);

    final w = _bw;
    final h = _bh;

    // -- Cap dimensions --
    final capWidth = w * 0.28;
    final capLeft = (w - capWidth) / 2;
    const capTop = 0.0;
    final capBottom = h * 0.07;
    const capRadius = 6.0;
    final capRect = RRect.fromLTRBR(
      capLeft, capTop, capLeft + capWidth, capBottom,
      const Radius.circular(capRadius),
    );

    // -- Neck --
    final neckWidth = w * 0.24;
    final neckLeft = (w - neckWidth) / 2;
    final neckTop = capBottom;
    final neckBottom = h * 0.14;

    // -- Body --
    final bodyLeft = w * 0.08;
    final bodyRight = w * 0.92;
    final bodyTop = h * 0.17;
    final bodyBottom = h * 0.97;
    const bodyRadius = 28.0;

    // Build bottle body path
    final bottlePath = Path()
      ..moveTo(neckLeft, neckTop)
      ..lineTo(neckLeft, neckBottom)
      ..quadraticBezierTo(neckLeft, bodyTop, bodyLeft + bodyRadius, bodyTop)
      ..lineTo(bodyLeft + bodyRadius, bodyTop)
      ..quadraticBezierTo(bodyLeft, bodyTop, bodyLeft, bodyTop + bodyRadius)
      ..lineTo(bodyLeft, bodyBottom - bodyRadius)
      ..quadraticBezierTo(
          bodyLeft, bodyBottom, bodyLeft + bodyRadius, bodyBottom)
      ..lineTo(bodyRight - bodyRadius, bodyBottom)
      ..quadraticBezierTo(
          bodyRight, bodyBottom, bodyRight, bodyBottom - bodyRadius)
      ..lineTo(bodyRight, bodyTop + bodyRadius)
      ..quadraticBezierTo(bodyRight, bodyTop, bodyRight - bodyRadius, bodyTop)
      ..lineTo(neckLeft + neckWidth, bodyTop)
      ..quadraticBezierTo(
          neckLeft + neckWidth, bodyTop, neckLeft + neckWidth, neckBottom)
      ..lineTo(neckLeft + neckWidth, neckTop)
      ..close();

    // 1. Bottle background fill
    canvas.drawPath(
      bottlePath,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
    );

    // 2. Water fill with waves
    if (progress > 0) {
      canvas.save();
      canvas.clipPath(bottlePath);

      final fillableHeight = bodyBottom - neckTop;
      final fillHeight = fillableHeight * progress;
      final fillTop = bodyBottom - fillHeight;

      final waterColor = color == Colors.red
          ? Colors.blue.shade300
          : color == Colors.green
              ? Colors.blue.shade400
              : Colors.blue.shade300;

      final waterPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            waterColor.withValues(alpha: 0.5),
            waterColor.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromLTWH(0, fillTop, w, fillHeight));

      final clampedTilt = tiltX.clamp(-10.0, 10.0);
      final tiltFactor = clampedTilt * 10.0;
      const baseWaveHeight = 4.0;
      final waveHeight = baseWaveHeight + clampedTilt.abs() * 1.2;

      // Back wave (gentle, offset phase for depth)
      final backWavePath = Path();
      backWavePath.moveTo(0, fillTop + tiltFactor * (0 / w - 0.5));
      for (var x = 0.0; x <= w; x += 1) {
        final slope = tiltFactor * (x / w - 0.5);
        final y = fillTop +
            slope +
            sin(x * 0.05 - wavePhase * pi * 2 + 1.5) * (waveHeight * 0.7);
        backWavePath.lineTo(x, y);
      }
      backWavePath.lineTo(w, bodyBottom + 10);
      backWavePath.lineTo(0, bodyBottom + 10);
      backWavePath.close();

      canvas.drawPath(
        backWavePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              waterColor.withValues(alpha: 0.3),
              waterColor.withValues(alpha: 0.6),
            ],
          ).createShader(Rect.fromLTWH(0, fillTop, w, fillHeight)),
      );

      // Front wave (smooth single sine)
      final wavePath = Path();
      wavePath.moveTo(0, fillTop + tiltFactor * (0 / w - 0.5));
      for (var x = 0.0; x <= w; x += 1) {
        final slope = tiltFactor * (x / w - 0.5);
        final y =
            fillTop + slope + sin(x * 0.06 + wavePhase * pi * 2) * waveHeight;
        wavePath.lineTo(x, y);
      }
      wavePath.lineTo(w, bodyBottom + 10);
      wavePath.lineTo(0, bodyBottom + 10);
      wavePath.close();

      canvas.drawPath(wavePath, waterPaint);
      canvas.restore();
    }

    // 3. Bottle outline
    canvas.drawPath(
      bottlePath,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 4. Cap — Phase 1: twist on bottle, Phase 2: lift off
    {
      canvas.save();
      final cx = w / 2;
      final cy = capBottom / 2;
      final t = capOpenProgress;

      // Phase 1 (0→0.65): twist in place on the bottle neck
      final twistT = (t / 0.65).clamp(0.0, 1.0);
      // Phase 2 (0.65→1.0): lift off and drift away
      final liftT = ((t - 0.65) / 0.35).clamp(0.0, 1.0);
      final easedLift = Curves.easeOut.transform(liftT);

      // During twist: wobble + perspective squash only, cap stays on bottle
      // Tiny thread rise during twist (cap lifts ~3px as threads loosen)
      final twistLiftY = twistT * -3;
      // After twist: cap drifts to bottom-left of bottle (placed aside, with gap)
      final liftY = twistLiftY + easedLift * (bodyBottom - cy + 12);
      final driftX = easedLift * -(cx - bodyLeft + capWidth / 2 + 8);

      // Tilt wobble while twisting (stops once lifted)
      final tiltAngle = sin(twistT * 6 * pi) * 0.12 * (1.0 - liftT);
      // Perspective squash while twisting (simulates 3D rotation)
      final scaleX =
          1.0 - sin(twistT * 5 * pi).abs() * 0.18 * (1.0 - liftT);

      canvas.translate(cx + driftX, cy + liftY);
      canvas.rotate(tiltAngle);
      canvas.scale(scaleX, 1.0);
      canvas.translate(-cx, -cy);

      // Cap fill
      canvas.drawRRect(
        capRect,
        Paint()
          ..color = color.withValues(alpha: 0.7)
          ..style = PaintingStyle.fill,
      );
      // Cap outline
      canvas.drawRRect(
        capRect,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      // Grip lines (ridges on cap)
      final gripPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      for (var i = 1; i <= 3; i++) {
        final gy = capTop + (capBottom - capTop) * i / 4;
        canvas.drawLine(
          Offset(capLeft + 4, gy),
          Offset(capLeft + capWidth - 4, gy),
          gripPaint,
        );
      }
      canvas.restore();
    }

    // 5. Shine highlight
    canvas.drawRRect(
      RRect.fromLTRBR(
        bodyLeft + 6,
        bodyTop + 20,
        bodyLeft + 24,
        bodyBottom - 20,
        const Radius.circular(10),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(
            bodyLeft + 6, bodyTop + 20, 18, bodyBottom - bodyTop - 40)),
    );

    // Save neck center for stream target (in translated coords)
    final neckCenterX = w / 2;
    final neckCenterY = neckTop + 5;

    canvas.restore(); // Restore from bx, by translate

    // Compute tilt shift once for both pouring bottle and stream
    final bottleTiltAngle = tiltX.clamp(-10.0, 10.0) * -0.04;
    final tiltShiftX = (_bh - neckCenterY) * sin(bottleTiltAngle);

    // 6. Pouring bottle
    if (pourBottleProgress > 0) {
      _drawPouringBottle(canvas, bx, by, tiltShiftX);
    }

    // 7. Water stream
    if (pourStreamProgress > 0) {
      _drawWaterStream(canvas, bx, by, neckCenterX, neckCenterY, tiltShiftX);
    }

    // 8. Pour bottle cap — animates from pouring bottle neck to bottom-right of main bottle
    if (pourCapProgress > 0 && pourBottleProgress > 0) {
      _drawPourCap(canvas, bx, by, tiltShiftX, bodyRight, bodyTop, bodyBottom);
    }
  }

  void _drawPouringBottle(Canvas canvas, double bx, double by, double tiltShiftX) {
    final t = Curves.easeOut.transform(pourBottleProgress);
    final px = bx + _pourStartX + (_pourEndX - _pourStartX) * t + tiltShiftX * t;
    final py = by + _pourStartY + (_pourEndY - _pourStartY) * t;
    final angle = t * _pourMaxTilt;

    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(angle);

    // Bottle drawn with body bottom at (0,0), extending upward
    const bw2 = _pbBodyW / 2;
    const nw2 = _pbNeckW / 2;
    const bodyBottom = 0.0;
    const bodyTop = -_pbBodyH;
    const shoulderTop = bodyTop - _pbShoulderH;
    const neckBottom = shoulderTop;
    const neckTop = neckBottom - _pbNeckH;
    const capBottom = neckTop;
    const capTop = capBottom - _pbCapH;
    const bodyR = 10.0;

    // Water bottle shape path (body + shoulders + neck)
    final bottlePath = Path()
      // Start bottom-left
      ..moveTo(-bw2 + bodyR, bodyBottom)
      // Bottom edge
      ..lineTo(bw2 - bodyR, bodyBottom)
      // Bottom-right corner
      ..quadraticBezierTo(bw2, bodyBottom, bw2, bodyBottom - bodyR)
      // Right side
      ..lineTo(bw2, bodyTop + bodyR)
      // Top-right corner
      ..quadraticBezierTo(bw2, bodyTop, bw2 - bodyR, bodyTop)
      // Right shoulder (taper from body width to neck width)
      ..quadraticBezierTo(nw2 + 4, shoulderTop + 4, nw2, shoulderTop)
      // Right neck
      ..lineTo(nw2, neckTop)
      // Left neck
      ..lineTo(-nw2, neckTop)
      // Left shoulder
      ..lineTo(-nw2, shoulderTop)
      ..quadraticBezierTo(-nw2 - 4, shoulderTop + 4, -bw2 + bodyR, bodyTop)
      // Top-left corner
      ..quadraticBezierTo(-bw2, bodyTop, -bw2, bodyTop + bodyR)
      // Left side
      ..lineTo(-bw2, bodyBottom - bodyR)
      // Bottom-left corner
      ..quadraticBezierTo(-bw2, bodyBottom, -bw2 + bodyR, bodyBottom)
      ..close();

    // Fill
    canvas.drawPath(
      bottlePath,
      Paint()
        ..color = Colors.blue.shade50
        ..style = PaintingStyle.fill,
    );

    // Water inside (starts full, empties as pour progresses, stays empty after)
    final waterLevel = pourComplete
        ? 0.0
        : (0.85 - pourStreamProgress * 0.8).clamp(0.0, 1.0);
    if (waterLevel > 0) {
      canvas.save();
      canvas.clipPath(bottlePath);
      final waterTop = bodyBottom - (bodyBottom - bodyTop) * waterLevel;
      canvas.drawRect(
        Rect.fromLTRB(-bw2, waterTop, bw2, bodyBottom),
        Paint()..color = Colors.blue.shade300.withValues(alpha: 0.5),
      );
      canvas.restore();
    }

    // Outline
    canvas.drawPath(
      bottlePath,
      Paint()
        ..color = Colors.blue.shade400.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Cap drawn when pourCapProgress == 0 (before/after animation)
    if (pourCapProgress == 0) {
      final capRR = RRect.fromLTRBR(
        -_pbCapW / 2, capTop, _pbCapW / 2, capBottom,
        const Radius.circular(3),
      );
      canvas.drawRRect(
        capRR,
        Paint()
          ..color = Colors.blue.shade400.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        capRR,
        Paint()
          ..color = Colors.blue.shade400.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Shine on body
    canvas.drawRRect(
      RRect.fromLTRBR(
        -bw2 + 5, bodyTop + 8, -bw2 + 14, bodyBottom - 8,
        const Radius.circular(6),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromLTWH(-bw2 + 5, bodyTop + 8, 9, _pbBodyH - 16)),
    );

    canvas.restore();
  }

  void _drawWaterStream(
    Canvas canvas,
    double bx,
    double by,
    double neckCX,
    double neckCY,
    double tiltShiftX,
  ) {
    // Compute spout position from fully-positioned pouring bottle (same as _drawPouringBottle)
    final t = Curves.easeOut.transform(pourBottleProgress);
    final px = bx + _pourStartX + (_pourEndX - _pourStartX) * t + tiltShiftX * t;
    final py = by + _pourStartY + (_pourEndY - _pourStartY) * t;
    final angle = t * _pourMaxTilt;

    // Neck opening is _pbSpoutDist above pivot, rotated
    final spoutX = px + _pbSpoutDist * sin(angle);
    final spoutY = py - _pbSpoutDist * cos(angle);

    // Target: main bottle neck center, accounting for accelerometer tilt
    final bottleTilt = tiltX.clamp(-10.0, 10.0) * -0.04;
    // Tilt pivot is at bottom-center of main bottle
    final pivotX = bx + _bw / 2;
    final pivotY = by + _bh;
    final dx = bx + neckCX - pivotX;
    final dy = by + neckCY - pivotY;
    final targetX = pivotX + dx * cos(bottleTilt) - dy * sin(bottleTilt);
    final targetY = pivotY + dx * sin(bottleTilt) + dy * cos(bottleTilt);

    // Stream bezier with wobble
    final wobble = sin(streamWavePhase * pi * 2) * 1.0;
    final streamPaint = Paint()
      ..color = Colors.blue.shade300.withValues(alpha: 0.7 * pourStreamProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + wobble
      ..strokeCap = StrokeCap.round;

    final controlX = spoutX + (targetX - spoutX) * 0.5;
    final controlY = spoutY + (targetY - spoutY) * 0.5;

    final streamPath = Path()
      ..moveTo(spoutX, spoutY)
      ..quadraticBezierTo(controlX, controlY, targetX, targetY);

    canvas.drawPath(streamPath, streamPaint);

    // Splash droplets at impact
    if (pourStreamProgress > 0.3) {
      final splashPaint = Paint()
        ..color =
            Colors.blue.shade200.withValues(alpha: 0.6 * pourStreamProgress)
        ..style = PaintingStyle.fill;

      for (var i = 0; i < 4; i++) {
        final phase = (streamWavePhase + i * 0.25) % 1.0;
        final dx = sin(phase * pi * 2) * 8;
        final dy = -cos(phase * pi * 2) * 5 - 3;
        canvas.drawCircle(
          Offset(targetX + dx, targetY + dy),
          1.5,
          splashPaint,
        );
      }
    }
  }

  void _drawPourCap(
    Canvas canvas,
    double bx,
    double by,
    double tiltShiftX,
    double bodyRight,
    double bodyTop,
    double bodyBottom,
  ) {
    final p = pourCapProgress;

    // Phase 1 (0→0.65): twist on pouring bottle
    final twistT = (p / 0.65).clamp(0.0, 1.0);
    // Phase 2 (0.65→1.0): fly to main bottle bottom-right
    final liftT = ((p - 0.65) / 0.35).clamp(0.0, 1.0);
    final easedLift = Curves.easeOut.transform(liftT);

    // Start position: cap on the pouring bottle (in canvas coords)
    // Same formula as spoutX/Y but with cap distance instead of spout distance
    final bt = Curves.easeOut.transform(pourBottleProgress);
    final pourPx = bx + _pourStartX + (_pourEndX - _pourStartX) * bt + tiltShiftX * bt;
    final pourPy = by + _pourStartY + (_pourEndY - _pourStartY) * bt;
    final pourAngle = bt * _pourMaxTilt;
    const capDist = _pbBodyH + _pbShoulderH + _pbNeckH + _pbCapH / 2;
    final startX = pourPx + capDist * sin(pourAngle);
    final startY = pourPy - capDist * cos(pourAngle);

    // End position: bottom-right of main bottle, accounting for tilt rotation
    // Compute in main bottle's local coords, then rotate around its pivot
    final bottleTilt = tiltX.clamp(-10.0, 10.0) * -0.04;
    final pivotX = bx + _bw / 2;
    final pivotY = by + _bh;
    // Local position: right of body edge + gap, at body bottom
    final localDx = bx + bodyRight + _pbCapW / 2 + 8 - pivotX;
    final localDy = by + bodyBottom - pivotY;
    final endX = pivotX + localDx * cos(bottleTilt) - localDy * sin(bottleTilt);
    final endY = pivotY + localDx * sin(bottleTilt) + localDy * cos(bottleTilt);

    // During twist: stay on pouring bottle. After twist: fly to main bottle.
    final capX = startX + (endX - startX) * easedLift;
    final capY = startY + (endY - startY) * easedLift;
    final capAngle = pourAngle + (0.0 - pourAngle) * easedLift;

    // Twist wobble (only during twist phase)
    final wobble = sin(twistT * 6 * pi) * 0.10 * (1.0 - liftT);
    final scaleX = 1.0 - sin(twistT * 5 * pi).abs() * 0.15 * (1.0 - liftT);

    canvas.save();
    canvas.translate(capX, capY);
    canvas.rotate(capAngle + wobble);
    canvas.scale(scaleX, 1.0);

    // Draw the cap
    final capRR = RRect.fromLTRBR(
      -_pbCapW / 2, -_pbCapH / 2, _pbCapW / 2, _pbCapH / 2,
      const Radius.circular(3),
    );
    canvas.drawRRect(
      capRR,
      Paint()
        ..color = Colors.blue.shade400.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      capRR,
      Paint()
        ..color = Colors.blue.shade400.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Grip ridges
    final gripPaint = Paint()
      ..color = Colors.blue.shade400.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var i = 1; i <= 2; i++) {
      final gy = -_pbCapH / 2 + _pbCapH * i / 3;
      canvas.drawLine(
        Offset(-_pbCapW / 2 + 3, gy),
        Offset(_pbCapW / 2 - 3, gy),
        gripPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CuteWaterBottlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.capOpenProgress != capOpenProgress ||
        oldDelegate.pourBottleProgress != pourBottleProgress ||
        oldDelegate.pourStreamProgress != pourStreamProgress ||
        oldDelegate.pourComplete != pourComplete ||
        oldDelegate.streamWavePhase != streamWavePhase ||
        oldDelegate.pourCapProgress != pourCapProgress;
  }
}