import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/notification_ids.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/task_model.dart';
import '../../domain/task_status.dart';
import '../providers/todo_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({super.key, this.taskId});

  final String? taskId;

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleControllers = <TextEditingController>[TextEditingController()];
  final _descriptionController = TextEditingController();
  final _phoneShareController = TextEditingController();
  TaskStatus _status = TaskStatus.notStarted;
  DateTime _dueDate = DateTime.now();
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;
  bool _isEditing = false;
  TaskModel? _existingTask;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      _isEditing = true;
      _loadTask();
    }
  }

  Future<void> _loadTask() async {
    setState(() => _isLoading = true);
    // Try Cubit state first for instant load
    final cubitState = context.read<TodoCubit>().state;
    for (final t in cubitState.myTasks) {
      if (t.id == widget.taskId) {
        _populateFields(t);
        return;
      }
    }
    // Fallback: fetch from Firestore
    final repo = context.read<TodoCubit>().repository;
    final task = await repo.getTaskById(widget.taskId!);
    if (task != null && mounted) {
      _populateFields(task);
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _populateFields(TaskModel task) {
    setState(() {
      _existingTask = task;
      _titleControllers.first.text = task.title;
      _descriptionController.text = task.description;
      _status = task.status;
      _dueDate = task.dueDate;
      _reminderTime = TimeOfDay(
        hour: task.dueDate.hour,
        minute: task.dueDate.minute,
      );
      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _addTitleField() {
    setState(() {
      _titleControllers.add(TextEditingController());
    });
  }

  void _removeTitleField(int index) {
    if (_titleControllers.length <= 1) return;
    setState(() {
      _titleControllers[index].dispose();
      _titleControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (final c in _titleControllers) {
      c.dispose();
    }
    _descriptionController.dispose();
    _phoneShareController.dispose();
    super.dispose();
  }

  DateTime get _combinedDueDateTime => DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _reminderTime.hour,
        _reminderTime.minute,
      );

  Future<void> _pickContact() async {
    try {
      final hasPermission = await FlutterContacts.requestPermission();
      if (!hasPermission) {
        if (mounted) showErrorSnackBar(context, 'Contacts permission denied');
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;

      final fullContact = await FlutterContacts.getContact(contact.id,
          withProperties: true);
      if (fullContact == null || fullContact.phones.isEmpty) {
        if (mounted) {
          showErrorSnackBar(context, 'Selected contact has no phone number');
        }
        return;
      }

      String phone;
      if (fullContact.phones.length == 1) {
        phone = fullContact.phones.first.number;
      } else {
        phone = await showDialog<String>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: Text('Pick a number for ${fullContact.displayName}'),
                children: fullContact.phones
                    .map(
                      (p) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, p.number),
                        child: Text(
                          '${p.label.name}: ${p.number}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ) ??
            '';
        if (phone.isEmpty) return;
      }

      phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      setState(() {
        _phoneShareController.text = phone;
        _phoneError = null;
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to pick contact: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate phone number if provided
    final phone = _phoneShareController.text.trim();
    if (!_isEditing && phone.isNotEmpty) {
      final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleaned.length < 10) {
        setState(() => _phoneError = 'Enter a valid phone number (min 10 digits)');
        return;
      }

      setState(() {
        _isLoading = true;
        _phoneError = null;
      });

      // Check if user is registered
      final shareRepo = context.read<TodoCubit>().shareRepository;
      final foundUser = await shareRepo.findUserByPhone(phone);
      if (foundUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _phoneError =
                'This phone number is not registered in CoreSync Go.';
          });
        }
        return;
      }

      // Check self-sharing
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (foundUser['uid'] == currentUid) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _phoneError = 'You cannot share a task with yourself.';
          });
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _phoneError = null;
    });

    try {
      final cubit = context.read<TodoCubit>();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) showErrorSnackBar(context, 'User not authenticated');
        return;
      }

      final dueDateTime = _combinedDueDateTime;

      if (_isEditing && _existingTask != null) {
        final updatedTask = _existingTask!.copyWith(
          title: _titleControllers.first.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          dueDate: dueDateTime,
        );
        await cubit.updateTask(updatedTask);

        // Reschedule alarm for the updated due date
        final alarmId = NotificationIds.taskAlarm(updatedTask.id);
        await NotificationService.cancel(alarmId);
        await NotificationService.scheduleOnceAlarm(
          id: alarmId,
          title: 'Task Reminder',
          body: _titleControllers.first.text.trim(),
          scheduledDate: dueDateTime,
        );

        if (mounted) {
          showSuccessSnackBar(context, 'Task updated');
          context.pop();
        }
      } else {
        // Collect all non-empty titles
        final titles = _titleControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();

        // Look up share target once if phone provided
        Map<String, dynamic>? shareTarget;
        if (phone.isNotEmpty) {
          shareTarget = await cubit.shareRepository.findUserByPhone(phone);
        }

        for (final title in titles) {
          final newTask = TaskModel(
            id: '',
            title: title,
            description: _descriptionController.text.trim(),
            status: _status,
            ownerId: user.uid,
            ownerEmail: user.email ?? '',
            dueDate: dueDateTime,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          final taskId = await cubit.addTask(newTask);

          // Schedule alarm for the due date
          await NotificationService.scheduleOnceAlarm(
            id: NotificationIds.taskAlarm(taskId),
            title: 'Task Reminder',
            body: title,
            scheduledDate: dueDateTime,
          );

          // Share with phone if provided
          if (shareTarget != null) {
            final targetUid = shareTarget['uid'] as String;
            await cubit.shareRepository.shareTask(taskId, targetUid);
          }
        }

        // Send push notification once if shared
        if (shareTarget != null && mounted) {
          try {
            final targetUid = shareTarget['uid'] as String;
            final senderName = user.displayName ?? 'Someone';
            final taskWord = titles.length == 1 ? 'a task' : '${titles.length} tasks';
            await PushNotificationService.sendNotification(
              targetUid: targetUid,
              title: 'Task Shared',
              body: '$senderName shared $taskWord with you',
            );
          } catch (_) {}
        }

        if (mounted) {
          final msg = titles.length == 1
              ? 'Task created${phone.isNotEmpty ? ' and shared' : ''}'
              : '${titles.length} tasks created${phone.isNotEmpty ? ' and shared' : ''}';
          showSuccessSnackBar(context, msg);
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Add Task'),
      ),
      body: _isLoading && _isEditing && _existingTask == null
          ? const LoadingWidget(message: 'Loading task...')
          : Center(
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title fields
                    for (int i = 0; i < _titleControllers.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _titleControllers[i],
                              decoration: InputDecoration(
                                labelText: _titleControllers.length > 1
                                    ? 'Title ${i + 1}'
                                    : 'Title',
                                hintText: 'Enter task title',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  Validators.requiredField(v, 'Title'),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          if (!_isEditing && _titleControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: 'Remove',
                              onPressed: () => _removeTitleField(i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (!_isEditing)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addTitleField,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add another title'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Enter task description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_dueDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Reminder Time',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.alarm),
                        ),
                        child: Text(
                          _reminderTime.format(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TaskStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: TaskStatus.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                    if (!_isEditing) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneShareController,
                              decoration: InputDecoration(
                                labelText: 'Share with (phone)',
                                hintText: 'Enter phone number (optional)',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.phone_outlined),
                                errorText: _phoneError,
                              ),
                              keyboardType: TextInputType.phone,
                              onChanged: (_) {
                                if (_phoneError != null) {
                                  setState(() => _phoneError = null);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.contacts),
                            tooltip: 'Pick from contacts',
                            onPressed: _pickContact,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing
                              ? 'Update Task'
                              : _titleControllers.length > 1
                                  ? 'Create ${_titleControllers.length} Tasks'
                                  : 'Create Task'),
                    ),
                  ],
                ),
              ),
              ),
            ),
            ),
    );
  }
}