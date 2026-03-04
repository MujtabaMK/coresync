import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneShareController = TextEditingController();
  TaskStatus _status = TaskStatus.notStarted;
  DateTime _dueDate = DateTime.now();
  bool _isLoading = false;
  bool _isEditing = false;
  TaskModel? _existingTask;

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
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _status = task.status;
      _dueDate = task.dueDate;
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneShareController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cubit = context.read<TodoCubit>();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) showErrorSnackBar(context, 'User not authenticated');
        return;
      }

      if (_isEditing && _existingTask != null) {
        final updatedTask = _existingTask!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          dueDate: _dueDate,
        );
        await cubit.updateTask(updatedTask);
        if (mounted) {
          showSuccessSnackBar(context, 'Task updated');
          context.pop();
        }
      } else {
        final newTask = TaskModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          ownerId: user.uid,
          ownerEmail: user.email ?? '',
          dueDate: _dueDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final taskId = await cubit.addTask(newTask);

        // Share with phone if provided
        final phone = _phoneShareController.text.trim();
        if (phone.isNotEmpty && mounted) {
          final shareRepo = cubit.shareRepository;
          final foundUser = await shareRepo.findUserByPhone(phone);
          if (foundUser != null) {
            await shareRepo.shareTask(taskId, foundUser['uid']);
            if (mounted) {
              showSuccessSnackBar(context, 'Task created and shared');
              context.pop();
              return;
            }
          }
        }

        if (mounted) {
          showSuccessSnackBar(context, 'Task created');
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter task title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => Validators.requiredField(v, 'Title'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
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
                      TextFormField(
                        controller: _phoneShareController,
                        decoration: const InputDecoration(
                          labelText: 'Share with (phone)',
                          hintText: 'Enter phone number (optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
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
                          : Text(_isEditing ? 'Update Task' : 'Create Task'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
