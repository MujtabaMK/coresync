import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/sleep_log_model.dart';
import '../providers/gym_provider.dart';

class LogSleepScreen extends StatefulWidget {
  const LogSleepScreen({super.key});

  @override
  State<LogSleepScreen> createState() => _LogSleepScreenState();
}

class _LogSleepScreenState extends State<LogSleepScreen> {
  late DateTime _sleepTime;
  late DateTime _wakeTime;
  SleepQuality? _quality;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default: 11 PM previous day -> 7 AM today
    _sleepTime = DateTime(now.year, now.month, now.day - 1, 23, 0);
    _wakeTime = DateTime(now.year, now.month, now.day, 7, 0);
    context.read<GymCubit>().loadTodaySleep();

    // If sleep already logged today, pre-populate with that data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<GymCubit>().state;
      if (state.todaySleep.isNotEmpty) {
        final latest = state.todaySleep.first;
        setState(() {
          _sleepTime = latest.sleepTime;
          _wakeTime = latest.wakeTime;
          _quality = latest.quality;
          if (latest.notes != null) _notesCtrl.text = latest.notes!;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Duration get _duration => _wakeTime.difference(_sleepTime);

  String get _durationFormatted {
    final d = _duration;
    if (d.isNegative) return 'Invalid';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  /// Recalculate dates so duration is always correct:
  /// - Wake time always uses today's date
  /// - Sleep time uses today's date too; if sleep >= wake, subtract 1 day
  void _recalculateDates() {
    final now = DateTime.now();
    // Set both to today's date with their respective times
    _wakeTime = DateTime(now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
    _sleepTime = DateTime(now.year, now.month, now.day, _sleepTime.hour, _sleepTime.minute);
    // If sleep time is at or after wake time, bedtime was yesterday
    if (_sleepTime.isAtSameMomentAs(_wakeTime) || _sleepTime.isAfter(_wakeTime)) {
      _sleepTime = _sleepTime.subtract(const Duration(days: 1));
    }
  }

  Future<void> _pickSleepTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_sleepTime),
    );
    if (time == null) return;
    setState(() {
      _sleepTime = DateTime(
        _sleepTime.year,
        _sleepTime.month,
        _sleepTime.day,
        time.hour,
        time.minute,
      );
      _recalculateDates();
    });
  }

  Future<void> _pickWakeTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_wakeTime),
    );
    if (time == null) return;
    setState(() {
      _wakeTime = DateTime(
        _wakeTime.year,
        _wakeTime.month,
        _wakeTime.day,
        time.hour,
        time.minute,
      );
      _recalculateDates();
    });
  }

  Future<void> _save() async {
    if (_duration.isNegative || _duration.inMinutes < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wake time must be after sleep time')),
      );
      return;
    }

    final sleep = SleepLogModel(
      id: const Uuid().v4(),
      sleepTime: _sleepTime,
      wakeTime: _wakeTime,
      quality: _quality,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      await context.read<GymCubit>().saveSleepLog(sleep);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sleep logged - $_durationFormatted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Sleep')),
      body: BlocBuilder<GymCubit, GymState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Existing sleep log
              if (state.todaySleep.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Sleep",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...state.todaySleep.map((s) => Dismissible(
                              key: Key(s.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) {
                                context
                                    .read<GymCubit>()
                                    .deleteSleepLog(s.id);
                              },
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.bedtime,
                                    color: Colors.indigo),
                                title: Text(s.durationFormatted),
                                subtitle: Text(
                                  '${_formatTime(s.sleepTime)} - ${_formatTime(s.wakeTime)}'
                                  '${s.quality != null ? ' \u00b7 ${s.quality!.label}' : ''}',
                                ),
                                trailing: s.notes != null
                                    ? const Icon(Icons.note, size: 18)
                                    : null,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Duration preview
              Center(
                child: Card(
                  color: Colors.indigo.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    child: Column(
                      children: [
                        const Icon(Icons.bedtime,
                            size: 40, color: Colors.indigo),
                        const SizedBox(height: 12),
                        Text(
                          _durationFormatted,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        Text(
                          'sleep duration',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sleep time picker
              ListTile(
                leading: const Icon(Icons.nights_stay, color: Colors.indigo),
                title: const Text('Bedtime'),
                subtitle: Text(_formatTime(_sleepTime)),
                trailing: const Icon(Icons.edit),
                onTap: _pickSleepTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
              ),
              const SizedBox(height: 12),

              // Wake time picker
              ListTile(
                leading:
                    const Icon(Icons.wb_sunny, color: Colors.amber),
                title: const Text('Wake time'),
                subtitle: Text(_formatTime(_wakeTime)),
                trailing: const Icon(Icons.edit),
                onTap: _pickWakeTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
              ),
              const SizedBox(height: 20),

              // Quality selector
              Text('Sleep Quality (optional)',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: SleepQuality.values.map((q) {
                  final selected = _quality == q;
                  return ChoiceChip(
                    label: Text(q.label),
                    selected: selected,
                    onSelected: (v) =>
                        setState(() => _quality = v ? q : null),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Woke up once at 3 AM',
                ),
              ),
              const SizedBox(height: 24),

              // Save
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Log Sleep'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}
