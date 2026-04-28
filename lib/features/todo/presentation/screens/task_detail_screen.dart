import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/comment_model.dart';
import '../../domain/task_model.dart';
import '../../domain/task_status.dart';
import '../providers/todo_provider.dart';
import '../widgets/status_badge.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  TaskModel? _findTask(TodoState state) {
    for (final t in state.myTasks) {
      if (t.id == widget.taskId) return t;
    }
    for (final t in state.sharedTasks) {
      if (t.id == widget.taskId) return t;
    }
    return null;
  }

  Future<void> _changeStatus(TaskStatus newStatus) async {
    try {
      await context.read<TodoCubit>().updateTaskStatus(widget.taskId, newStatus);
      if (mounted) {
        showSuccessSnackBar(context, 'Status updated to ${newStatus.label}');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Task',
      content:
          'Are you sure you want to delete this task? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    try {
      await context.read<TodoCubit>().deleteTask(widget.taskId);
      if (mounted) {
        showSuccessSnackBar(context, 'Task deleted');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _addComment(TaskModel task) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _sending = true);

    final comment = CommentModel(
      id: '',
      authorId: user.uid,
      authorName: user.displayName ?? 'Unknown',
      content: text,
      createdAt: DateTime.now(),
    );

    try {
      await context.read<TodoCubit>().repository.addComment(
            widget.taskId,
            comment,
          );
      _commentController.clear();

      // Send push notifications
      final commenterName = user.displayName ?? 'Someone';
      final isOwner = user.uid == task.ownerId;

      if (isOwner) {
        // Owner comments → notify each shared user
        for (final uid in task.sharedWith) {
          await PushNotificationService.sendNotification(
            targetUid: uid,
            title: 'New Comment on "${task.title}"',
            body: '$commenterName: $text',
          );
        }
      } else {
        // Shared user comments → notify owner
        if (task.ownerId.isNotEmpty) {
          await PushNotificationService.sendNotification(
            targetUid: task.ownerId,
            title: 'New Comment on "${task.title}"',
            body: '$commenterName: $text',
          );
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TodoCubit, TodoState, TaskModel?>(
      selector: (state) => _findTask(state),
      builder: (context, task) {
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task Details')),
            body: const Center(child: Text('Task not found.')),
          );
        }

        final theme = Theme.of(context);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final isOwner = uid != null && task.ownerId == uid;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () => context.push('/todo/edit/${task.id}'),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share',
                  onPressed: () => context.push('/todo/share/${task.id}'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: _deleteTask,
                ),
              ],
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status badge
                      Row(
                        children: [
                          const Text('Status: '),
                          StatusBadge(status: task.status),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status change dropdown
                      DropdownButtonFormField<TaskStatus>(
                        key: ValueKey(task.status),
                        initialValue: task.status,
                        decoration: const InputDecoration(
                          labelText: 'Change Status',
                          border: OutlineInputBorder(),
                        ),
                        items: TaskStatus.values
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null && value != task.status) {
                            _changeStatus(value);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Description
                      if (task.description.isNotEmpty) ...[
                        Text(
                          'Description',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                      ],

                      const Divider(),
                      const SizedBox(height: 12),

                      // Dates
                      _buildInfoRow(
                        context,
                        icon: Icons.event,
                        label: 'Due Date',
                        value: DateHelpers.formatDate(task.dueDate),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        icon: Icons.calendar_today,
                        label: 'Created',
                        value: DateHelpers.formatDateTime(task.createdAt),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        icon: Icons.update,
                        label: 'Updated',
                        value: DateHelpers.formatDateTime(task.updatedAt),
                      ),
                      if (task.completedAt != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          context,
                          icon: Icons.check_circle_outline,
                          label: 'Completed',
                          value: DateHelpers.formatDateTime(task.completedAt!),
                        ),
                      ],

                      // Shared info
                      if (task.sharedWith.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Shared with ${task.sharedWith.length} '
                              '${task.sharedWith.length == 1 ? 'person' : 'people'}',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],

                      // Comments section
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Comments',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCommentsList(context, uid),
                    ],
                  ),
                ),
              ),

              // Bottom comment input bar
              _buildCommentInput(context, task),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsList(BuildContext context, String? uid) {
    final repo = context.read<TodoCubit>().repository;
    return StreamBuilder<List<CommentModel>>(
      stream: repo.watchComments(widget.taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final comments = snapshot.data ?? [];

        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No comments yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final comment = comments[index];
            final isMe = comment.authorId == uid;
            return _buildCommentTile(context, comment, isMe);
          },
        );
      },
    );
  }

  Widget _buildCommentTile(
    BuildContext context,
    CommentModel comment,
    bool isMe,
  ) {
    final theme = Theme.of(context);
    final initial = comment.authorName.isNotEmpty
        ? comment.authorName[0].toUpperCase()
        : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          child: Text(initial, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isMe ? 'You' : comment.authorName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateHelpers.formatRelativeTime(comment.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(comment.content, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput(BuildContext context, TaskModel task) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                isDense: true,
              ),
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => _addComment(task),
            ),
          ),
          IconButton(
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _sending ? null : () => _addComment(task),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
