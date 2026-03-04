import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../domain/reminder_type.dart';
import '../providers/gym_provider.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key, required this.reminderType});

  final ReminderType reminderType;

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool _enabled = false;
  int _hour = 8;
  int _minute = 0;
  String _frequency = 'weekly'; // 'weekly' or 'monthly'
  int _dayOfWeek = 1; // Monday
  int _dayOfMonth = 1;
  bool _loaded = false;

  ReminderType get _type => widget.reminderType;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = context.read<GymCubit>().repository;
    final settings = await repo.getReminderSettings(_type.hivePrefix);
    if (!mounted) return;
    setState(() {
      _enabled = settings['enabled'] as bool;
      _hour = settings['hour'] as int;
      _minute = settings['minute'] as int;
      _frequency = settings['frequency'] as String;
      _dayOfWeek = settings['dayOfWeek'] as int;
      _dayOfMonth = settings['dayOfMonth'] as int;
      _loaded = true;
    });
  }

  Future<void> _saveAndSchedule() async {
    final repo = context.read<GymCubit>().repository;
    await repo.saveReminderSettings(_type.hivePrefix, {
      'enabled': _enabled,
      'hour': _hour,
      'minute': _minute,
      'frequency': _frequency,
      'dayOfWeek': _dayOfWeek,
      'dayOfMonth': _dayOfMonth,
    });

    // Cancel existing notification
    await NotificationService.cancel(_type.notificationId);

    if (_enabled) {
      final granted = await NotificationService.requestPermissions();

      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please allow notifications in device settings'),
          ),
        );
        return;
      }

      if (_type.uiPattern == ReminderUiPattern.onceAt) {
        await NotificationService.scheduleDailyNotification(
          id: _type.notificationId,
          title: _type.label,
          body: _type.description,
          hour: _hour,
          minute: _minute,
        );
      } else {
        // periodic
        if (_frequency == 'weekly') {
          await NotificationService.scheduleWeeklyNotification(
            id: _type.notificationId,
            title: _type.label,
            body: _type.description,
            dayOfWeek: _dayOfWeek,
            hour: _hour,
            minute: _minute,
          );
        } else {
          await NotificationService.scheduleMonthlyNotification(
            id: _type.notificationId,
            title: _type.label,
            body: _type.description,
            dayOfMonth: _dayOfMonth,
            hour: _hour,
            minute: _minute,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for $_formattedTime'),
          ),
        );
      }
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
      _saveAndSchedule();
    }
  }

  String get _formattedTime {
    final time = TimeOfDay(hour: _hour, minute: _minute);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static const _weekDays = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_type.label)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: Text(
                    _enabled ? 'Reminders On' : 'Reminders Off',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(_type.description),
                  value: _enabled,
                  onChanged: (val) {
                    setState(() => _enabled = val);
                    _saveAndSchedule();
                  },
                ),
                const SizedBox(height: 16),
                if (_enabled) ..._buildEnabledBody(theme),
              ],
            ),
    );
  }

  List<Widget> _buildEnabledBody(ThemeData theme) {
    if (_type.uiPattern == ReminderUiPattern.onceAt) {
      return _buildOnceAtUi(theme);
    }
    return _buildPeriodicUi(theme);
  }

  List<Widget> _buildOnceAtUi(ThemeData theme) {
    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.access_time),
          title: const Text('Remind me once at'),
          trailing: TextButton(
            onPressed: _pickTime,
            child: Text(
              _formattedTime,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPeriodicUi(ThemeData theme) {
    return [
      Card(
        child: RadioGroup<String>(
          groupValue: _frequency,
          onChanged: (val) {
            if (val == null) return;
            setState(() => _frequency = val);
            _saveAndSchedule();
          },
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Remind me every week'),
                value: 'weekly',
              ),
              if (_frequency == 'weekly')
                Padding(
                  padding:
                      const EdgeInsets.only(left: 32, right: 16, bottom: 8),
                  child: DropdownButtonFormField<int>(
                    initialValue: _dayOfWeek,
                    decoration: const InputDecoration(
                      labelText: 'Day of Week',
                      border: OutlineInputBorder(),
                    ),
                    items: _weekDays.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _dayOfWeek = val!);
                      _saveAndSchedule();
                    },
                  ),
                ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text('Remind me every month'),
                value: 'monthly',
              ),
              if (_frequency == 'monthly')
                Padding(
                  padding:
                      const EdgeInsets.only(left: 32, right: 16, bottom: 8),
                  child: DropdownButtonFormField<int>(
                    initialValue: _dayOfMonth,
                    decoration: const InputDecoration(
                      labelText: 'Day of Month',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      28,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _dayOfMonth = val!);
                      _saveAndSchedule();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.access_time),
          title: const Text('At time'),
          trailing: TextButton(
            onPressed: _pickTime,
            child: Text(
              _formattedTime,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
