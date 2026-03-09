import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../providers/todo_provider.dart';

class ShareTaskScreen extends StatefulWidget {
  const ShareTaskScreen({super.key, required this.taskIds});

  final List<String> taskIds;

  @override
  State<ShareTaskScreen> createState() => _ShareTaskScreenState();
}

class _ShareTaskScreenState extends State<ShareTaskScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSearching = false;
  bool _isSharing = false;
  Map<String, dynamic>? _foundUser;
  String? _searchError;

  bool get _isMultiple => widget.taskIds.length > 1;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    try {
      final hasPermission = await FlutterContacts.requestPermission();
      if (!hasPermission) {
        if (mounted) {
          showErrorSnackBar(context, 'Contacts permission denied');
        }
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;

      // Fetch full contact to get phone numbers
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
        // Show a dialog to pick which number
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

      // Clean the phone number (remove spaces, dashes, etc.)
      phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

      setState(() {
        _phoneController.text = phone;
        _foundUser = null;
        _searchError = null;
      });

      // Auto-search after picking
      _searchUser();
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to pick contact: $e');
      }
    }
  }

  Future<void> _searchUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
      _searchError = null;
    });

    try {
      final shareRepo = context.read<TodoCubit>().shareRepository;
      final user = await shareRepo.findUserByPhone(
        _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSearching = false;
          if (user != null) {
            // Don't allow sharing with yourself
            final currentUid = FirebaseAuth.instance.currentUser?.uid;
            if (user['uid'] == currentUid) {
              _searchError = 'You cannot share a task with yourself.';
            } else {
              _foundUser = user;
            }
          } else {
            _searchError = 'This phone number or email is not registered in CoreSync.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchError = e.toString();
        });
      }
    }
  }

  Future<void> _shareWithUser() async {
    if (_foundUser == null) return;

    setState(() => _isSharing = true);

    try {
      final shareRepo = context.read<TodoCubit>().shareRepository;
      final targetUid = _foundUser!['uid'] as String;

      for (final taskId in widget.taskIds) {
        debugPrint('Sharing task $taskId with uid: $targetUid');
        await shareRepo.shareTask(taskId, targetUid);
      }
      debugPrint('All tasks shared successfully, now sending notification...');

      // Send push notification to the target user
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        final senderName = currentUser?.displayName ?? 'Someone';
        final body = _isMultiple
            ? '$senderName shared ${widget.taskIds.length} tasks with you'
            : '$senderName shared a task with you';
        await PushNotificationService.sendNotification(
          targetUid: targetUid,
          title: 'Task Shared',
          body: body,
        );
        debugPrint('Notification sent to $targetUid');
      } catch (e) {
        debugPrint('Failed to send notification: $e');
        if (mounted) {
          showErrorSnackBar(context, 'Shared but notification failed: $e');
        }
      }

      if (mounted) {
        final msg = _isMultiple
            ? '${widget.taskIds.length} tasks shared successfully'
            : 'Task shared successfully';
        showSuccessSnackBar(context, msg);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e.toString());
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isMultiple
        ? 'Share ${widget.taskIds.length} Tasks'
        : 'Share Task';
    final description = _isMultiple
        ? 'Find a user by phone number or email to share ${widget.taskIds.length} tasks.'
        : 'Find a user by phone number or email to share this task.';
    final shareLabel = _isSharing
        ? 'Sharing...'
        : (_isMultiple
            ? 'Share ${widget.taskIds.length} Tasks'
            : 'Share Task');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number or Email',
                        hintText: 'Enter phone number or email',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _searchUser,
                              ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a phone number or email';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        // Clear previous results when input changes
                        if (_foundUser != null || _searchError != null) {
                          setState(() {
                            _foundUser = null;
                            _searchError = null;
                          });
                        }
                      },
                      onFieldSubmitted: (_) => _searchUser(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.contacts),
                    tooltip: 'Pick from contacts',
                    onPressed: _pickContact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_searchError != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _searchError!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_foundUser != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Found',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              (_foundUser!['displayName'] as String? ?? '?')
                                  .characters
                                  .first
                                  .toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _foundUser!['displayName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _foundUser!['email'] ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (_foundUser!['phoneNumber'] != null &&
                                    (_foundUser!['phoneNumber'] as String).isNotEmpty)
                                  Text(
                                    _foundUser!['phoneNumber'],
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSharing ? null : _shareWithUser,
                          icon: _isSharing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.share),
                          label: Text(shareLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
