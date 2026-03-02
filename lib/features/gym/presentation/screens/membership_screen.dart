import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/membership_model.dart';
import '../providers/gym_provider.dart';
import '../widgets/membership_card.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  String? _selectedPlan;
  bool _isSaving = false;

  static const Map<String, String> _planLabels = {
    '1month': '1 Month',
    '3months': '3 Months',
    '6months': '6 Months',
    '1year': '1 Year',
  };

  static const Map<String, int> _planDays = {
    '1month': 30,
    '3months': 90,
    '6months': 180,
    '1year': 365,
  };

  static const Map<String, IconData> _planIcons = {
    '1month': Icons.looks_one,
    '3months': Icons.looks_3,
    '6months': Icons.looks_6,
    '1year': Icons.calendar_today,
  };

  Future<void> _saveMembership() async {
    if (_selectedPlan == null) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final days = _planDays[_selectedPlan]!;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current membership
            BlocBuilder<GymCubit, GymState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state.error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: ${state.error}'),
                  );
                }
                final membership = state.activeMembership;
                if (membership == null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.card_membership,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No active membership',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select a plan below to get started',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Current Membership',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      MembershipCard(membership: membership),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select a Plan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Plan selection
            ...(_planLabels.entries.map((entry) {
              final isSelected = _selectedPlan == entry.key;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Card(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: Icon(
                      _planIcons[entry.key],
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      entry.value,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text('${_planDays[entry.key]} days'),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: theme.colorScheme.primary)
                        : const Icon(Icons.circle_outlined),
                    onTap: () {
                      setState(() => _selectedPlan = entry.key);
                    },
                  ),
                ),
              );
            })),

            const SizedBox(height: 24),

            // Activate button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      _selectedPlan != null && !_isSaving ? _saveMembership : null,
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
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
