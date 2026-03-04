import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/user_model.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadUserModel();
  }

  Future<void> _loadUserModel() async {
    final model = await context.read<AuthCubit>().repository.getCurrentUserModel();
    if (mounted) setState(() => _userModel = model);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser = authState.user;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Profile'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentUser?.displayName ?? 'CoreSync User',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentUser?.email ?? 'No email',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _userModel?.phoneNumber ?? 'No phone',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Theme settings card
                Card(
                  child: BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, themeMode) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Appearance',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('System default'),
                            secondary: const Icon(Icons.settings_brightness),
                            value: ThemeMode.system,
                            groupValue: themeMode,
                            onChanged: (value) {
                              context.read<ThemeCubit>().setThemeMode(value!);
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('Light mode'),
                            secondary: const Icon(Icons.light_mode),
                            value: ThemeMode.light,
                            groupValue: themeMode,
                            onChanged: (value) {
                              context.read<ThemeCubit>().setThemeMode(value!);
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('Dark mode'),
                            secondary: const Icon(Icons.dark_mode),
                            value: ThemeMode.dark,
                            groupValue: themeMode,
                            onChanged: (value) {
                              context.read<ThemeCubit>().setThemeMode(value!);
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Test notifications
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications_active),
                        title: const Text('Test Local Notification'),
                        subtitle: const Text('Direct notification (no Firestore)'),
                        trailing: const Icon(Icons.send),
                        onTap: () async {
                          try {
                            await NotificationService.showInstantNotification(
                              id: 9999,
                              title: 'Local Test',
                              body: 'Direct local notification works!',
                              channelId: 'shared_tasks',
                              channelName: 'Shared Tasks',
                            );
                            if (context.mounted) {
                              showSuccessSnackBar(context, 'Local notification fired!');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showErrorSnackBar(context, 'Local notification failed: $e');
                            }
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cloud),
                        title: const Text('Test Firestore Notification'),
                        subtitle: const Text('Write to Firestore + listener'),
                        trailing: const Icon(Icons.send),
                        onTap: () async {
                          try {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) {
                              if (context.mounted) {
                                showErrorSnackBar(context, 'Not logged in');
                              }
                              return;
                            }
                            // Restart listener first
                            PushNotificationService.dispose();
                            PushNotificationService.listenForNotifications();

                            await PushNotificationService.sendNotification(
                              targetUid: uid,
                              title: 'Firestore Test',
                              body: 'Firestore listener notification works!',
                            );
                            if (context.mounted) {
                              showSuccessSnackBar(context, 'Firestore notification sent!');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showErrorSnackBar(context, 'Failed: $e');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.tonal(
                    onPressed: () async {
                      await context.read<AuthCubit>().signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    child: const Text('Logout'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}