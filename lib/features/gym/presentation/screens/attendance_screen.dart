import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/gym_provider.dart';
import '../widgets/attendance_calendar.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Future<void> _markAttendance(bool isPresent) async {
    final membership = context.read<GymCubit>().state.activeMembership;
    if (membership == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active subscription. Please subscribe to a plan first.')),
      );
      return;
    }

    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day first')),
      );
      return;
    }

    await context.read<GymCubit>().markAttendance(_selectedDay!, isPresent);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPresent ? 'Marked as Present' : 'Marked as Absent'),
        ),
      );
    }
  }

  Future<void> _deleteAttendance() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day first')),
      );
      return;
    }

    final state = context.read<GymCubit>().state;
    final normalizedDay = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    if (!state.attendanceMap.containsKey(normalizedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance record for this day')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: const Text(
          'Are you sure you want to delete this attendance record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<GymCubit>().deleteAttendance(_selectedDay!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance record deleted')),
        );
      }
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
        if (state.error != null) {
          return Center(child: Text('Error: ${state.error}'));
        }

        final attendanceMap = state.attendanceMap;
        final membership = state.activeMembership;

        // Check if selected day has a record
        final normalizedSelected = _selectedDay != null
            ? DateTime(
                _selectedDay!.year,
                _selectedDay!.month,
                _selectedDay!.day,
              )
            : null;
        final hasRecord =
            normalizedSelected != null &&
            attendanceMap.containsKey(normalizedSelected);

        return SingleChildScrollView(
          child: Column(
            children: [
              // Current plan info
              if (membership != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Current Plan: ${membership.planLabel}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
              ],

              // Calendar
              AttendanceCalendar(
                attendanceMap: attendanceMap,
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
              ),
              const SizedBox(height: 16),

              // No active plan warning
              if (membership == null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No active subscription. Subscribe to a plan to mark attendance.',
                              style: TextStyle(color: theme.colorScheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (attendanceMap.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear All Attendance'),
                            content: const Text(
                              'Delete all attendance records? This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete All'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await context.read<GymCubit>().deleteAllAttendance();
                        }
                      },
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      label: const Text(
                        'Clear All Attendance Data',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],

              // Mark attendance buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: membership != null ? () => _markAttendance(true) : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Present'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: membership != null ? () => _markAttendance(false) : null,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Absent'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: hasRecord ? _deleteAttendance : null,
                      icon: const Icon(Icons.delete_outline),
                      style: IconButton.styleFrom(
                        backgroundColor: hasRecord
                            ? theme.colorScheme.errorContainer
                            : null,
                        foregroundColor: hasRecord
                            ? theme.colorScheme.onErrorContainer
                            : null,
                      ),
                      tooltip: 'Delete record',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Attendance stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: 'Present',
                        count: state.presentCount,
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatChip(
                        label: 'Absent',
                        count: state.absentCount,
                        color: Colors.red,
                        icon: Icons.cancel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
