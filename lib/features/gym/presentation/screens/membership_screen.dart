import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/membership_model.dart';
import '../providers/gym_provider.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  String? _selectedPlan;
  bool _isSaving = false;

  Future<void> _saveMembership() async {
    if (_selectedPlan == null) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final days = MembershipModel.planDurations[_selectedPlan]!;
    final endDate = startDate.add(Duration(days: days));

    final membership = MembershipModel(
      id: const Uuid().v4(),
      plan: _selectedPlan!,
      startDate: startDate,
      endDate: endDate,
      isActive: true,
    );

    await context.read<GymCubit>().saveMembership(membership);

    setState(() {
      _isSaving = false;
      _selectedPlan = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membership activated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return BlocBuilder<GymCubit, GymState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeMembership = state.activeMembership;
        final activePlan = activeMembership?.plan;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active membership info
              if (activeMembership != null) ...[
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Plan: ${activeMembership.planLabel}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.calendar_today,
                                label: dateFormat.format(
                                  activeMembership.startDate,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.event,
                                label: dateFormat.format(
                                  activeMembership.endDate,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _membershipProgress(activeMembership),
                            minHeight: 6,
                            backgroundColor: theme
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activeMembership.daysRemaining} days remaining',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Text(
                'Choose a Plan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Plan cards grid
              ...MembershipModel.planLabels.entries.map((entry) {
                final planKey = entry.key;
                final planName = entry.value;
                final duration = MembershipModel.planDurations[planKey]!;
                final price = MembershipModel.planPrices[planKey]!;
                final isActive = activePlan == planKey;
                final isSelected = _selectedPlan == planKey;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isActive
                            ? theme.colorScheme.primary
                            : isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: isActive ? 2 : 1.5,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedPlan = planKey);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        planName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (isActive) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'Active',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$duration days',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rs. $price',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Rs. ${(price / (duration / 30)).round()}/mo',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.radio_button_checked,
                                color: theme.colorScheme.primary,
                              ),
                            ] else ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.radio_button_off,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Activate button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _selectedPlan != null && !_isSaving
                      ? _saveMembership
                      : null,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Activate Membership'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  double _membershipProgress(MembershipModel membership) {
    final total = membership.endDate.difference(membership.startDate).inDays;
    final elapsed = DateTime.now().difference(membership.startDate).inDays;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onPrimaryContainer),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
