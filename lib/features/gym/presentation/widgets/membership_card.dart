import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/membership_model.dart';

class MembershipCard extends StatelessWidget {
  final MembershipModel membership;

  const MembershipCard({super.key, required this.membership});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final isExpired = membership.isExpired;

    final statusColor = isExpired ? Colors.red : Colors.green;
    final statusText = isExpired ? 'Expired' : 'Active';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  membership.planLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Start: ${dateFormat.format(membership.startDate)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'End: ${dateFormat.format(membership.endDate)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isExpired)
              LinearProgressIndicator(
                value: _progress(),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: statusColor,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            if (!isExpired) ...[
              const SizedBox(height: 8),
              Text(
                '${membership.daysRemaining} days remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _progress() {
    final total = membership.endDate.difference(membership.startDate).inDays;
    final elapsed = DateTime.now().difference(membership.startDate).inDays;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
