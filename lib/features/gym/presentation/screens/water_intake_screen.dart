import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Animation
  late AnimationController _animController;
  late AnimationController _waveController;
  late Animation<double> _fillAnimation;
  double _previousProgress = 0;
  bool _fillInitialized = false;

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
  }

  @override
  void dispose() {
    _animController.dispose();
    _waveController.dispose();
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
      _animateToProgress(newProgress);
      context.read<GymCubit>().addWater(selected);
    } else {
      final newMl = (state.waterMl - selected).clamp(0, state.waterMl);
      final newProgress =
          goalMl > 0 ? (newMl / goalMl).clamp(0.0, 1.0) : 0.0;
      _animateToProgress(newProgress);
      context.read<GymCubit>().removeWater(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<GymCubit, GymState>(
      listenWhen: (prev, curr) => prev.waterMl != curr.waterMl,
      listener: (context, state) {
        if (!_fillInitialized) return;
        final goalMl = state.effectiveWaterGoalMl;
        final progress =
            goalMl > 0 ? (state.waterMl / goalMl).clamp(0.0, 1.0) : 0.0;
        if ((_previousProgress - progress).abs() > 0.01 &&
            !_animController.isAnimating) {
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
            width: 180,
            height: 280,
            child: AnimatedBuilder(
              animation: Listenable.merge([_fillAnimation, _waveController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _CuteWaterBottlePainter(
                    progress: _fillAnimation.value,
                    wavePhase: _waveController.value,
                    color: progressColor,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
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
                  onPressed: currentMl > 0
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
                  onPressed: () => _showMlPicker(isAdd: true),
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
              onPressed: () {
                _animateToProgress(0);
                context.read<GymCubit>().resetWaterIntake();
              },
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

/// Cute rounded water bottle with cap
class _CuteWaterBottlePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color color;
  final Color backgroundColor;

  _CuteWaterBottlePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // -- Cap --
    final capWidth = w * 0.28;
    final capLeft = (w - capWidth) / 2;
    final capTop = 0.0;
    final capBottom = h * 0.07;
    final capRadius = 6.0;
    final capRect = RRect.fromLTRBR(
      capLeft, capTop, capLeft + capWidth, capBottom, Radius.circular(capRadius),
    );

    // -- Neck --
    final neckWidth = w * 0.24;
    final neckLeft = (w - neckWidth) / 2;
    final neckTop = capBottom;
    final neckBottom = h * 0.14;

    // -- Body (big rounded rectangle) --
    final bodyLeft = w * 0.08;
    final bodyRight = w * 0.92;
    final bodyTop = h * 0.17;
    final bodyBottom = h * 0.97;
    final bodyRadius = 28.0;

    // Build bottle body path (neck + shoulders + rounded body)
    final bottlePath = Path()
      // Start at neck top-left
      ..moveTo(neckLeft, neckTop)
      ..lineTo(neckLeft, neckBottom)
      // Left shoulder curve to body
      ..quadraticBezierTo(neckLeft, bodyTop, bodyLeft + bodyRadius, bodyTop)
      // Top-left corner
      ..lineTo(bodyLeft + bodyRadius, bodyTop)
      ..quadraticBezierTo(bodyLeft, bodyTop, bodyLeft, bodyTop + bodyRadius)
      // Left side
      ..lineTo(bodyLeft, bodyBottom - bodyRadius)
      // Bottom-left corner
      ..quadraticBezierTo(bodyLeft, bodyBottom, bodyLeft + bodyRadius, bodyBottom)
      // Bottom
      ..lineTo(bodyRight - bodyRadius, bodyBottom)
      // Bottom-right corner
      ..quadraticBezierTo(bodyRight, bodyBottom, bodyRight, bodyBottom - bodyRadius)
      // Right side
      ..lineTo(bodyRight, bodyTop + bodyRadius)
      // Top-right corner
      ..quadraticBezierTo(bodyRight, bodyTop, bodyRight - bodyRadius, bodyTop)
      // Right shoulder curve to neck
      ..lineTo(neckLeft + neckWidth, bodyTop)
      ..quadraticBezierTo(neckLeft + neckWidth, bodyTop, neckLeft + neckWidth, neckBottom)
      ..lineTo(neckLeft + neckWidth, neckTop)
      ..close();

    // Draw bottle background fill
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bottlePath, bgPaint);

    // Draw water fill (clipped to bottle)
    if (progress > 0) {
      canvas.save();
      canvas.clipPath(bottlePath);

      final fillableHeight = bodyBottom - neckTop;
      final fillHeight = fillableHeight * progress;
      final fillTop = bodyBottom - fillHeight;

      // Water gradient
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

      // Back wave (slightly transparent, offset phase)
      final backWavePath = Path();
      backWavePath.moveTo(0, fillTop);
      const waveHeight = 4.0;
      for (var x = 0.0; x <= w; x += 1) {
        final y = fillTop +
            sin(x * 0.05 - wavePhase * pi * 2 + 1.5) * (waveHeight * 0.7);
        backWavePath.lineTo(x, y);
      }
      backWavePath.lineTo(w, bodyBottom + 10);
      backWavePath.lineTo(0, bodyBottom + 10);
      backWavePath.close();

      final backWavePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            waterColor.withValues(alpha: 0.3),
            waterColor.withValues(alpha: 0.6),
          ],
        ).createShader(Rect.fromLTWH(0, fillTop, w, fillHeight));
      canvas.drawPath(backWavePath, backWavePaint);

      // Front wave (main)
      final wavePath = Path();
      wavePath.moveTo(0, fillTop);
      for (var x = 0.0; x <= w; x += 1) {
        final y = fillTop +
            sin(x * 0.06 + wavePhase * pi * 2) * waveHeight;
        wavePath.lineTo(x, y);
      }
      wavePath.lineTo(w, bodyBottom + 10);
      wavePath.lineTo(0, bodyBottom + 10);
      wavePath.close();

      canvas.drawPath(wavePath, waterPaint);
      canvas.restore();
    }

    // Draw bottle outline
    final outlinePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(bottlePath, outlinePaint);

    // Draw cap
    final capPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(capRect, capPaint);

    final capOutlinePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(capRect, capOutlinePaint);

    // Draw subtle highlight on left side of body (cute shine)
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(bodyLeft + 6, bodyTop + 20, 18, bodyBottom - bodyTop - 40));
    canvas.drawRRect(
      RRect.fromLTRBR(
        bodyLeft + 6, bodyTop + 20, bodyLeft + 24, bodyBottom - 20,
        const Radius.circular(10),
      ),
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CuteWaterBottlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}