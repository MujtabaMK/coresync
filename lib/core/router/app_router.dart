import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/gym/presentation/screens/attendance_screen.dart';
import '../../features/gym/presentation/screens/exercise_category_screen.dart';
import '../../features/gym/presentation/screens/exercises_screen.dart';
import '../../features/gym/presentation/screens/gym_home_screen.dart';
import '../../features/gym/presentation/screens/membership_screen.dart';
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
          state.matchedLocation == '/otp';

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
        path: '/otp',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return OtpScreen(
            verificationId: extras['verificationId'] as String,
            phoneNumber: extras['phoneNumber'] as String,
          );
        },
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
                builder: (context, state) => const GymHomeScreen(),
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
                    path: 'membership',
                    builder: (context, state) => const MembershipScreen(),
                  ),
                  GoRoute(
                    path: 'attendance',
                    builder: (context, state) => const AttendanceScreen(),
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
