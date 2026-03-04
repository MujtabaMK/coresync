import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/gym/presentation/screens/exercise_category_screen.dart';
import '../../features/gym/presentation/screens/add_edit_medicine_screen.dart';
import '../../features/gym/presentation/screens/exercises_screen.dart';
import '../../features/gym/presentation/screens/gym_shell_screen.dart';
import '../../features/gym/presentation/screens/medicine_cabinet_screen.dart';
import '../../features/gym/presentation/screens/meal_reminder_screen.dart';
import '../../features/gym/presentation/screens/reminder_settings_screen.dart';
import '../../features/gym/presentation/screens/reminders_hub_screen.dart';
import '../../features/gym/presentation/screens/water_reminder_screen.dart';
import '../../features/gym/domain/reminder_type.dart';
import '../../features/passwords/presentation/screens/add_password_screen.dart';
import '../../features/passwords/presentation/screens/password_detail_screen.dart';
import '../../features/passwords/presentation/screens/password_list_screen.dart';
import '../../features/todo/presentation/screens/add_edit_task_screen.dart';
import '../../features/todo/presentation/screens/reports_screen.dart';
import '../../features/todo/presentation/screens/share_task_screen.dart';
import '../../features/todo/presentation/screens/shared_tasks_screen.dart';
import '../../features/todo/presentation/screens/task_detail_screen.dart';
import '../../features/todo/presentation/screens/todo_list_screen.dart';
import '../widgets/main_shell.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _todoNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'todo');
final _passwordsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'passwords');
final _gymNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'gym');

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/todo',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/todo';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Todo branch
          StatefulShellBranch(
            navigatorKey: _todoNavigatorKey,
            routes: [
              GoRoute(
                path: '/todo',
                builder: (context, state) => const TodoListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddEditTaskScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:taskId',
                    builder: (context, state) => AddEditTaskScreen(
                      taskId: state.pathParameters['taskId'],
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:taskId',
                    builder: (context, state) => TaskDetailScreen(
                      taskId: state.pathParameters['taskId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'share/:taskId',
                    builder: (context, state) => ShareTaskScreen(
                      taskId: state.pathParameters['taskId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'shared',
                    builder: (context, state) => const SharedTasksScreen(),
                  ),
                  GoRoute(
                    path: 'reports',
                    builder: (context, state) => const ReportsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Passwords branch
          StatefulShellBranch(
            navigatorKey: _passwordsNavigatorKey,
            routes: [
              GoRoute(
                path: '/passwords',
                builder: (context, state) => const PasswordListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddPasswordScreen(),
                  ),
                  GoRoute(
                    path: 'detail/:passwordId',
                    builder: (context, state) => PasswordDetailScreen(
                      passwordId: state.pathParameters['passwordId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Gym branch
          StatefulShellBranch(
            navigatorKey: _gymNavigatorKey,
            routes: [
              GoRoute(
                path: '/gym',
                builder: (context, state) => const GymShellScreen(),
                routes: [
                  GoRoute(
                    path: 'exercises',
                    builder: (context, state) => const ExercisesScreen(),
                    routes: [
                      GoRoute(
                        path: ':category',
                        builder: (context, state) => ExerciseCategoryScreen(
                          category: state.pathParameters['category']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'reminders',
                    builder: (context, state) => const RemindersHubScreen(),
                    routes: [
                      GoRoute(
                        path: ':type',
                        builder: (context, state) {
                          final typeName = state.pathParameters['type']!;
                          // Custom screens for food and water
                          if (typeName == 'food') {
                            return const MealReminderScreen();
                          }
                          if (typeName == 'water') {
                            return const WaterReminderScreen();
                          }
                          final reminderType = ReminderType.values.firstWhere(
                            (e) => e.name == typeName,
                            orElse: () => ReminderType.workout,
                          );
                          return ReminderSettingsScreen(
                            reminderType: reminderType,
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'medicines',
                    builder: (context, state) =>
                        const MedicineCabinetScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        builder: (context, state) =>
                            const AddEditMedicineScreen(),
                      ),
                      GoRoute(
                        path: 'edit/:medicineId',
                        builder: (context, state) => AddEditMedicineScreen(
                          medicineId: state.pathParameters['medicineId'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
