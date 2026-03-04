import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../providers/medicine_provider.dart';

class MedicineCabinetScreen extends StatefulWidget {
  const MedicineCabinetScreen({super.key});

  @override
  State<MedicineCabinetScreen> createState() => _MedicineCabinetScreenState();
}

class _MedicineCabinetScreenState extends State<MedicineCabinetScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MedicineCubit>().loadMedicines();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Medicine Cabinet')),
      body: BlocBuilder<MedicineCubit, MedicineState>(
        builder: (context, state) {
          if (state.isLoading && state.medicines.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.medicines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 80,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No medicines scheduled!',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your medicines and set reminders to never miss a dose.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.go('/gym/medicines/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Schedule a Medicine'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.medicines.length,
            itemBuilder: (context, index) {
              final med = state.medicines[index];
              final name = med['name'] as String? ?? '';
              final type = med['type'] as String? ?? '';
              final strength = med['doseStrength'] as String? ?? '';
              final frequency = med['frequency'] as String? ?? '';
              final schedulerEnabled =
                  med['schedulerEnabled'] as bool? ?? false;

              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    child: const Icon(Icons.medication, color: Colors.green),
                  ),
                  title: Text(
                    name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    [type, strength, if (schedulerEnabled) frequency]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () =>
                      context.go('/gym/medicines/edit/${med['id']}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<MedicineCubit, MedicineState>(
        builder: (context, state) {
          if (state.medicines.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => context.go('/gym/medicines/add'),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
