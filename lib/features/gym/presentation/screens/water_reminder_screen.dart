import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/notification_ids.dart';
import '../../../../core/services/notification_service.dart';
import '../providers/gym_provider.dart';

class WaterReminderScreen extends StatefulWidget {
  const WaterReminderScreen({super.key});

  @override
  State<WaterReminderScreen> createState() => _WaterReminderScreenState();
}

class _WaterReminderScreenState extends State<WaterReminderScreen> {
  static const _prefix = 'reminder_water';
  bool _masterEnabled = false;
  bool _onceAtEnabled = false;
  int _onceAtHour = 21;
  int _onceAtMinute = 30;
  int _startHour = 9;
  int _startMinute = 30;
  int _endHour = 21;
  int _endMinute = 30;
  String _intervalMode = 'count'; // 'count' or 'minutes'
  int _count = 6;
  int _intervalMinutes = 30;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = await context.read<GymCubit>().repository.getGymSettingsBox();
    setState(() {
      _masterEnabled = box.get('${_prefix}_enabled', defaultValue: false) as bool;
      _onceAtEnabled = box.get('${_prefix}_once_enabled', defaultValue: false) as bool;
      _onceAtHour = box.get('${_prefix}_once_hour', defaultValue: 21) as int;
      _onceAtMinute = box.get('${_prefix}_once_minute', defaultValue: 30) as int;
      _startHour = box.get('${_prefix}_start_hour', defaultValue: 9) as int;
      _startMinute = box.get('${_prefix}_start_minute', defaultValue: 30) as int;
      _endHour = box.get('${_prefix}_end_hour', defaultValue: 21) as int;
      _endMinute = box.get('${_prefix}_end_minute', defaultValue: 30) as int;
      _intervalMode = box.get('${_prefix}_interval_mode', defaultValue: 'count') as String;
      _count = box.get('${_prefix}_count', defaultValue: 6) as int;
      _intervalMinutes = box.get('${_prefix}_interval_minutes', defaultValue: 30) as int;
      _loaded = true;
    });
  }

  Future<void> _saveAndSchedule() async {
    final box = await context.read<GymCubit>().repository.getGymSettingsBox();
    await box.put('${_prefix}_enabled', _masterEnabled);
    await box.put('${_prefix}_once_enabled', _onceAtEnabled);
    await box.put('${_prefix}_once_hour', _onceAtHour);
    await box.put('${_prefix}_once_minute', _onceAtMinute);
    await box.put('${_prefix}_start_hour', _startHour);
    await box.put('${_prefix}_start_minute', _startMinute);
    await box.put('${_prefix}_end_hour', _endHour);
    await box.put('${_prefix}_end_minute', _endMinute);
    await box.put('${_prefix}_interval_mode', _intervalMode);
    await box.put('${_prefix}_count', _count);
    await box.put('${_prefix}_interval_minutes', _intervalMinutes);

    // Cancel all water notifications
    await NotificationService.cancel(NotificationIds.waterOnce);
    for (var i = 0; i < 50; i++) {
      await NotificationService.cancel(NotificationIds.waterInterval(i));
    }

    if (!_masterEnabled) return;

    await NotificationService.requestPermissions();

    // Schedule once-at reminder
    if (_onceAtEnabled) {
      await NotificationService.scheduleDailyNotification(
        id: NotificationIds.waterOnce,
        title: 'Water Reminder',
        body: 'Time to drink water!',
        hour: _onceAtHour,
        minute: _onceAtMinute,
      );
    }

    // Schedule interval-based reminders
    final startMinutes = _startHour * 60 + _startMinute;
    final endMinutes = _endHour * 60 + _endMinute;
    if (endMinutes <= startMinutes) return;

    final totalMinutes = endMinutes - startMinutes;
    List<int> reminderTimesInMinutes = [];

    if (_intervalMode == 'count' && _count > 0) {
      final interval = totalMinutes ~/ _count;
      for (var i = 0; i < _count; i++) {
        reminderTimesInMinutes.add(startMinutes + interval * i);
      }
    } else if (_intervalMode == 'minutes' && _intervalMinutes > 0) {
      var current = startMinutes;
      while (current <= endMinutes) {
        reminderTimesInMinutes.add(current);
        current += _intervalMinutes;
      }
    }

    for (var i = 0; i < reminderTimesInMinutes.length && i < 48; i++) {
      final t = reminderTimesInMinutes[i];
      await NotificationService.scheduleDailyNotification(
        id: NotificationIds.waterInterval(i),
        title: 'Water Reminder',
        body: 'Time to drink water!',
        hour: t ~/ 60,
        minute: t % 60,
      );
    }
  }

  String _formatTime(int hour, int minute) {
    final t = TimeOfDay(hour: hour, minute: minute);
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  Future<void> _pickTime(int currentHour, int currentMinute, void Function(int h, int m) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );
    if (picked != null) {
      onPicked(picked.hour, picked.minute);
      _saveAndSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Water Reminder')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Turn off Reminders'),
                  value: !_masterEnabled,
                  onChanged: (val) {
                    setState(() => _masterEnabled = !val);
                    _saveAndSchedule();
                  },
                ),
                const SizedBox(height: 8),
                // Once-at
                CheckboxListTile(
                  title: Text(
                    'Remind me once at',
                    style: TextStyle(
                      color: _masterEnabled ? null : theme.disabledColor,
                    ),
                  ),
                  secondary: TextButton(
                    onPressed: _masterEnabled
                        ? () => _pickTime(_onceAtHour, _onceAtMinute, (h, m) {
                              setState(() {
                                _onceAtHour = h;
                                _onceAtMinute = m;
                              });
                            })
                        : null,
                    child: Text(_formatTime(_onceAtHour, _onceAtMinute)),
                  ),
                  value: _onceAtEnabled,
                  onChanged: _masterEnabled
                      ? (val) {
                          setState(() => _onceAtEnabled = val ?? false);
                          _saveAndSchedule();
                        }
                      : null,
                ),
                const Divider(),
                // Time range
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('Between', style: theme.textTheme.bodyLarge),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _masterEnabled
                            ? () => _pickTime(_startHour, _startMinute, (h, m) {
                                  setState(() {
                                    _startHour = h;
                                    _startMinute = m;
                                  });
                                })
                            : null,
                        child: Text(_formatTime(_startHour, _startMinute)),
                      ),
                      Text('to', style: theme.textTheme.bodyLarge),
                      TextButton(
                        onPressed: _masterEnabled
                            ? () => _pickTime(_endHour, _endMinute, (h, m) {
                                  setState(() {
                                    _endHour = h;
                                    _endMinute = m;
                                  });
                                })
                            : null,
                        child: Text(_formatTime(_endHour, _endMinute)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Remind me X Times
                RadioListTile<String>(
                  title: Text(
                    'Remind me',
                    style: TextStyle(color: _masterEnabled ? null : theme.disabledColor),
                  ),
                  secondary: SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          child: TextFormField(
                            initialValue: _count.toString(),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            enabled: _masterEnabled && _intervalMode == 'count',
                            onChanged: (val) {
                              _count = int.tryParse(val) ?? _count;
                              _saveAndSchedule();
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('Times', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  value: 'count',
                  groupValue: _intervalMode,
                  onChanged: _masterEnabled
                      ? (val) {
                          setState(() => _intervalMode = val ?? 'count');
                          _saveAndSchedule();
                        }
                      : null,
                ),
                // Remind me every X Minutes
                RadioListTile<String>(
                  title: Text(
                    'Remind me every',
                    style: TextStyle(color: _masterEnabled ? null : theme.disabledColor),
                  ),
                  secondary: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          child: TextFormField(
                            initialValue: _intervalMinutes.toString(),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            enabled: _masterEnabled && _intervalMode == 'minutes',
                            onChanged: (val) {
                              _intervalMinutes = int.tryParse(val) ?? _intervalMinutes;
                              _saveAndSchedule();
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('Minutes', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  value: 'minutes',
                  groupValue: _intervalMode,
                  onChanged: _masterEnabled
                      ? (val) {
                          setState(() => _intervalMode = val ?? 'minutes');
                          _saveAndSchedule();
                        }
                      : null,
                ),
              ],
            ),
    );
  }
}