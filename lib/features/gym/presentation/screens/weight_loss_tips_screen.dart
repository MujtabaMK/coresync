import 'package:flutter/material.dart';

import '../../data/weight_loss_tips_data.dart';
import '../../domain/weight_loss_profile_model.dart';

class WeightLossTipsScreen extends StatelessWidget {
  const WeightLossTipsScreen({super.key, this.goalType = GoalType.lose});

  final GoalType goalType;

  String get _title {
    switch (goalType) {
      case GoalType.lose:
        return 'Weight Loss Tips';
      case GoalType.gain:
        return 'Weight Gain Tips';
      case GoalType.maintain:
        return 'Weight Maintain Tips';
    }
  }

  List<WeightLossTip> get _tips {
    switch (goalType) {
      case GoalType.lose:
        return WeightLossTipsData.lossTips;
      case GoalType.gain:
        return WeightLossTipsData.gainTips;
      case GoalType.maintain:
        return WeightLossTipsData.maintainTips;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tips.length,
        itemBuilder: (context, index) {
          final tip = _tips[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tip.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
