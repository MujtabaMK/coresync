import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../providers/medicine_provider.dart';
import '../widgets/medicine_type_sheet.dart';

class AddEditMedicineScreen extends StatefulWidget {
  const AddEditMedicineScreen({super.key, this.medicineId});

  final String? medicineId;

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _quantityController = TextEditingController();

  String _type = '';
  bool _schedulerEnabled = false;
  String _frequency = 'Once daily';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<String> _doseTimes = ['08:00'];
  bool _reminderEnabled = false;

  bool get _isEditing => widget.medicineId != null;

  static const _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final cubit = context.read<MedicineCubit>();
    // Find medicine in current state
    final medicines = cubit.state.medicines;
    final med = medicines.cast<Map<String, dynamic>?>().firstWhere(
          (m) => m?['id'] == widget.medicineId,
          orElse: () => null,
        );
    if (med == null) return;

    setState(() {
      _nameController.text = med['name'] as String? ?? '';
      _type = med['type'] as String? ?? '';
      _strengthController.text = med['doseStrength'] as String? ?? '';
      _quantityController.text = med['quantity'] as String? ?? '';
      _schedulerEnabled = med['schedulerEnabled'] as bool? ?? false;
      _frequency = med['frequency'] as String? ?? 'Once daily';
      _startDate = med['startDate'] != null
          ? DateTime.parse(med['startDate'] as String)
          : DateTime.now();
      _endDate = med['endDate'] != null
          ? DateTime.parse(med['endDate'] as String)
          : null;
      _doseTimes = (med['doseTimes'] as List?)?.cast<String>() ?? ['08:00'];
      _reminderEnabled = med['reminderEnabled'] as bool? ?? false;
    });
  }

  void _onFrequencyChanged(String? freq) {
    if (freq == null) return;
    setState(() {
      _frequency = freq;
      if (freq != 'Custom') {
        switch (freq) {
          case 'Once daily':
            _doseTimes = ['08:00'];
          case 'Twice daily':
            _doseTimes = ['08:00', '20:00'];
          case 'Three times daily':
            _doseTimes = ['08:00', '14:00', '20:00'];
        }
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickDoseTime(int index) async {
    final parts = _doseTimes[index].split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (picked != null) {
      setState(() {
        _doseTimes[index] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  String _formatTime(String timeStr) {
    final parts = timeStr.split(':');
    final time = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a medicine type')),
      );
      return;
    }

    final medicine = <String, dynamic>{
      'id': widget.medicineId ?? const Uuid().v4(),
      'name': _nameController.text.trim(),
      'type': _type,
      'doseStrength': _strengthController.text.trim(),
      'quantity': _quantityController.text.trim(),
      'schedulerEnabled': _schedulerEnabled,
      'frequency': _frequency,
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'doseTimes': _doseTimes,
      'reminderEnabled': _reminderEnabled,
      'createdAt': _isEditing
          ? (context
                  .read<MedicineCubit>()
                  .state
                  .medicines
                  .cast<Map<String, dynamic>?>()
                  .firstWhere((m) => m?['id'] == widget.medicineId,
                      orElse: () => null)?['createdAt'] as String?) ??
              DateTime.now().toIso8601String()
          : DateTime.now().toIso8601String(),
    };

    context.read<MedicineCubit>().saveMedicine(medicine);
    context.go('/gym/medicines');
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine'),
        content:
            const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<MedicineCubit>()
                  .deleteMedicine(widget.medicineId!);
              context.go('/gym/medicines');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medicine' : 'Add Medicine'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Medicine Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Medicine Type
            InkWell(
              onTap: () async {
                final selected = await MedicineTypeSheet.show(context);
                if (selected != null) {
                  setState(() => _type = selected);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _type.isEmpty ? 'Select type' : _type,
                      style: _type.isEmpty
                          ? theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dose Strength & Quantity
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _strengthController,
                    decoration: const InputDecoration(
                      labelText: 'Dose Strength',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Scheduler toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Schedule Doses',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: const Text('Set when to take this medicine'),
              value: _schedulerEnabled,
              onChanged: (val) => setState(() => _schedulerEnabled = val),
            ),

            if (_schedulerEnabled) ...[
              const SizedBox(height: 8),

              // Frequency
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: _frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: _onFrequencyChanged,
              ),
              const SizedBox(height: 16),

              // Start & End Date
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(dateFormat.format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _endDate != null
                              ? dateFormat.format(_endDate!)
                              : 'Not set',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dose Times
              Text('Dose Times',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._doseTimes.asMap().entries.map((entry) {
                final index = entry.key;
                final time = entry.value;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(_formatTime(time)),
                    trailing: _doseTimes.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() => _doseTimes.removeAt(index));
                            },
                          )
                        : null,
                    onTap: () => _pickDoseTime(index),
                  ),
                );
              }),
              if (_frequency == 'Custom')
                TextButton.icon(
                  onPressed: () {
                    setState(() => _doseTimes.add('08:00'));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Time'),
                ),
              const SizedBox(height: 8),

              // Reminder toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set Reminder'),
                subtitle:
                    const Text('Get notified when it\'s time to take medicine'),
                value: _reminderEnabled,
                onChanged: (val) => setState(() => _reminderEnabled = val),
              ),
            ],

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_isEditing ? 'Update Medicine' : 'Add Medicine'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
