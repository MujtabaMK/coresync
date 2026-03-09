import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/report_provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/report_chart.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoCubit, TodoState>(
      builder: (context, todoState) {
        if (todoState.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Reports')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Ensure the ReportCubit is recomputed whenever myTasks change.
        final reportCubit = context.read<ReportCubit>();
        // We call computeReport here so that any new task data flowing
        // through the TodoCubit is reflected in the report.
        reportCubit.computeReport(todoState.myTasks);

        return BlocBuilder<ReportCubit, ReportState>(
          builder: (context, reportState) {
            final report = reportState.data;
            final period = reportState.period;

            final total = report['total'] ?? 0;
            final completed = report['completed'] ?? 0;
            final pending = total - completed;

            return Scaffold(
              appBar: AppBar(title: const Text('Reports')),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Period selector
                    SegmentedButton<ReportPeriod>(
                      showSelectedIcon: false,
                      segments: ReportPeriod.values
                          .map((p) => ButtonSegment(
                                value: p,
                                label: Text(
                                  p.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ))
                          .toList(),
                      selected: {period},
                      onSelectionChanged: (selection) {
                        context.read<ReportCubit>().setPeriod(
                              selection.first,
                              todoState.myTasks,
                            );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Summary cards
                    Row(
                      children: [
                        _SummaryCard(
                          title: 'Total',
                          count: total,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          title: 'Completed',
                          count: completed,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          title: 'Pending',
                          count: pending,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Chart
                    Text(
                      'Task Breakdown',
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 16),
                    ReportChart(data: report),
                  ],
                ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
