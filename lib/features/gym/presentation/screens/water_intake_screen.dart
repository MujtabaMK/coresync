import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/gym_provider.dart';

class WaterIntakeScreen extends StatefulWidget {
  const WaterIntakeScreen({super.key});

  @override
  State<WaterIntakeScreen> createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen> {
  bool _showSetup = false;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GymCubit, GymState>(
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
    const glassSize = 250; // ml
    final currentMl = state.waterGlasses * glassSize;
    final goalMl = state.dailyWaterGoalMl;
    final progress = goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.0) : 0.0;

    // Color: red if 0, green if goal reached, amber if in progress
    final progressColor = state.waterGlasses == 0
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
          // Circular progress
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _WaterProgressPainter(
                progress: progress,
                color: progressColor,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
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
          const SizedBox(height: 32),
          // Glass count
          Text(
            '${state.waterGlasses} glasses',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '(250ml each)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          // Add / Remove glass buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.waterGlasses > 0
                      ? () => context.read<GymCubit>().removeWaterGlass()
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
                  onPressed: () => context.read<GymCubit>().addWaterGlass(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Glass'),
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
              onPressed: () => context.read<GymCubit>().resetWaterIntake(),
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
                    child: Text(
                      'Daily goal: ${state.userWeight?.toStringAsFixed(0)} kg x 33 = $goalMl ml',
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

class _WaterProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _WaterProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 12.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
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
  bool shouldRepaint(covariant _WaterProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
