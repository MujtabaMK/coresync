import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/icon_picker_dialog.dart';

class AddEditHabitScreen extends StatefulWidget {
  const AddEditHabitScreen({super.key, this.habitId});

  final String? habitId;

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dailyVolumeController = TextEditingController(text: '3');
  final _volumePerPressController = TextEditingController(text: '1');

  String _icon = '\u{1F3AF}';
  ExecutionType _executionType = ExecutionType.oneTime;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _durationOption = 'unlimited';
  FrequencyMode _frequencyMode = FrequencyMode.byDays;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  int _timesPerWeek = 3;
  bool _reminderEnabled = false;
  int _reminderHour = 12;
  int _reminderMinute = 0;
  List<int> _reminderDays = [1, 2, 3, 4, 5, 6, 7];

  bool _isEditing = false;
  HabitModel? _existingHabit;

  @override
  void initState() {
    super.initState();
    if (widget.habitId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadHabit());
    }
  }

  void _loadHabit() {
    final habits = context.read<HabitCubit>().state.habits;
    final habit = habits.where((h) => h.id == widget.habitId).firstOrNull;
    if (habit == null) return;
    _existingHabit = habit;
    setState(() {
      _nameController.text = habit.name;
      _icon = habit.icon;
      _executionType = habit.executionType;
      _dailyVolumeController.text = habit.dailyVolume.toString();
      _volumePerPressController.text = habit.volumePerPress.toString();
      _startDate = habit.startDate;
      _endDate = habit.endDate;
      _durationOption = habit.endDate != null ? 'custom' : 'unlimited';
      _frequencyMode = habit.frequencyMode;
      _selectedDays = List.from(habit.selectedDays);
      _timesPerWeek = habit.timesPerWeek;
      _reminderEnabled = habit.reminderEnabled;
      _reminderHour = habit.reminderHour;
      _reminderMinute = habit.reminderMinute;
      _reminderDays = List.from(habit.reminderDays);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dailyVolumeController.dispose();
    _volumePerPressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit habit' : 'Add habit',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ── Name + Icon card ──
            _SectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter habit name',
                        border: InputBorder.none,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter a name' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Icon picker button (circular)
                  GestureDetector(
                    onTap: _pickIcon,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Execution type card ──
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Execution type',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildRadio(ExecutionType.oneTime, 'One-time'),
                  _buildRadio(ExecutionType.multiple, 'Multiple'),
                  _buildRadio(ExecutionType.trackVolume, 'Track by volume'),
                  _buildRadio(ExecutionType.dayCounter, 'Day counter'),

                  // Conditional fields
                  if (_executionType == ExecutionType.multiple) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dailyVolumeController,
                      decoration: const InputDecoration(
                        labelText: 'Enter daily volume',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (_executionType != ExecutionType.multiple) {
                          return null;
                        }
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'Enter a valid number';
                        return null;
                      },
                    ),
                  ],
                  if (_executionType == ExecutionType.trackVolume) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dailyVolumeController,
                      decoration: const InputDecoration(
                        labelText: 'Daily volume goal',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (_executionType != ExecutionType.trackVolume) {
                          return null;
                        }
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _volumePerPressController,
                      decoration: const InputDecoration(
                        labelText: 'What amount equals one press?',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (_executionType != ExecutionType.trackVolume) {
                          return null;
                        }
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'Enter a valid number';
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Date range card ──
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Start date / End date labels
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Start date',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'End date',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Date boxes
                  Row(
                    children: [
                      Expanded(
                        child: _DateBox(
                          date: _startDate,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _endDate != null
                            ? _DateBox(
                                date: _endDate!,
                                onTap: () => _pickDate(isStart: false),
                              )
                            : _DateBox(
                                placeholder: '\u2014',
                                onTap: () => _pickDate(isStart: false),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Duration dropdown
                  _DurationDropdown(
                    value: _durationOption,
                    onChanged: (v) {
                      setState(() {
                        _durationOption = v;
                        if (v == 'unlimited') {
                          _endDate = null;
                        } else {
                          _endDate ??=
                              _startDate.add(const Duration(days: 30));
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Frequency card ──
            _SectionCard(
              child: Column(
                children: [
                  // By days / X times a week toggle
                  Row(
                    children: [
                      Expanded(
                        child: _FrequencyToggle(
                          label: 'By days',
                          selected: _frequencyMode == FrequencyMode.byDays,
                          onTap: () => setState(
                            () => _frequencyMode = FrequencyMode.byDays,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FrequencyToggle(
                          label: 'X times a week',
                          selected:
                              _frequencyMode == FrequencyMode.timesPerWeek,
                          onTap: () => setState(
                            () =>
                                _frequencyMode = FrequencyMode.timesPerWeek,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_frequencyMode == FrequencyMode.byDays)
                    _DayCheckboxRow(
                      selected: _selectedDays,
                      onChanged: (days) =>
                          setState(() => _selectedDays = days),
                    )
                  else
                    _TimesPerWeekCounter(
                      value: _timesPerWeek,
                      onChanged: (v) =>
                          setState(() => _timesPerWeek = v),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Reminders card ──
            _SectionCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Reminders',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _reminderEnabled,
                        onChanged: (v) =>
                            setState(() => _reminderEnabled = v),
                      ),
                    ],
                  ),
                  if (_reminderEnabled) ...[
                    const SizedBox(height: 8),
                    // Time picker row
                    Row(
                      children: [
                        // Hour box
                        _TimeBox(
                          value: _reminderHour.toString().padLeft(2, '0'),
                          onTap: _pickReminderTime,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            ':',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _TimeBox(
                          value:
                              _reminderMinute.toString().padLeft(2, '0'),
                          onTap: _pickReminderTime,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(
                            () => _reminderEnabled = false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DayCheckboxRow(
                      selected: _reminderDays,
                      onChanged: (days) =>
                          setState(() => _reminderDays = days),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Submit button ──
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isEditing ? 'Update habit' : 'Create habit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(ExecutionType type, String label) {
    return RadioListTile<ExecutionType>(
      title: Text(label),
      value: type,
      groupValue: _executionType,
      onChanged: (v) => setState(() => _executionType = v!),
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _pickIcon() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const IconPickerDialog(),
    );
    if (result != null) setState(() => _icon = result);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
          _durationOption = 'custom';
        }
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();

    final habit = HabitModel(
      id: _existingHabit?.id ?? '',
      ownerId: uid,
      name: _nameController.text.trim(),
      icon: _icon,
      executionType: _executionType,
      dailyVolume: int.tryParse(_dailyVolumeController.text) ?? 1,
      volumePerPress: int.tryParse(_volumePerPressController.text) ?? 1,
      startDate: _startDate,
      endDate: _endDate,
      frequencyMode: _frequencyMode,
      selectedDays: _selectedDays,
      timesPerWeek: _timesPerWeek,
      reminderEnabled: _reminderEnabled,
      reminderHour: _reminderHour,
      reminderMinute: _reminderMinute,
      reminderDays: _reminderDays,
      completions: _existingHabit?.completions ?? const {},
      isArchived: false,
      createdAt: _existingHabit?.createdAt ?? now,
      updatedAt: now,
    );

    final cubit = context.read<HabitCubit>();
    if (_isEditing) {
      await cubit.updateHabit(habit);
    } else {
      await cubit.addHabit(habit);
    }

    if (mounted) context.pop();
  }
}

// ── Reusable sub-widgets ──

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({this.date, this.placeholder, required this.onTap});
  final DateTime? date;
  final String? placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = date != null
        ? DateFormat('dd.MM.yy').format(date!)
        : (placeholder ?? '\u2014');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationDropdown extends StatelessWidget {
  const _DurationDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'unlimited',
                    child: Text('Unlimited duration'),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text('Custom end date'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary),
          ),
          child: Icon(
            Icons.help_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _FrequencyToggle extends StatelessWidget {
  const _FrequencyToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? null
              : Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimesPerWeekCounter extends StatelessWidget {
  const _TimesPerWeekCounter({
    required this.value,
    required this.onChanged,
  });
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: Icons.remove,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$value times/week',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.add,
          onTap: value < 7 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerHighest,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _DayCheckboxRow extends StatelessWidget {
  const _DayCheckboxRow({required this.selected, required this.onChanged});
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  static const _labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isSelected = selected.contains(day);
        return Column(
          children: [
            Text(
              _labels[i],
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                final newDays = List<int>.from(selected);
                if (isSelected) {
                  newDays.remove(day);
                } else {
                  newDays.add(day);
                }
                newDays.sort();
                onChanged(newDays);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  border: isSelected
                      ? null
                      : Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
