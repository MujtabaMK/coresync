import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/splash_screen.dart';
import '../widgets/walkthrough_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';

import '../../features/calculator/presentation/screens/calculator_shell_screen.dart';
import '../../features/translator/presentation/screens/translator_shell_screen.dart';
import '../../features/gym/presentation/screens/exercise_category_screen.dart';
import '../../features/gym/presentation/screens/exercise_detail_screen.dart';
import '../../features/gym/domain/exercise_model.dart';
import '../../features/gym/data/workout_program_data.dart';
import '../../features/gym/presentation/screens/add_edit_medicine_screen.dart';
import '../../features/gym/presentation/screens/exercises_screen.dart';
import '../../features/gym/presentation/screens/gym_shell_screen.dart';
import '../../features/gym/presentation/screens/workout_detail_screen.dart';
import '../../features/gym/presentation/screens/workout_execution_screen.dart';
import '../../features/gym/presentation/screens/medicine_cabinet_screen.dart';
import '../../features/gym/presentation/screens/meal_reminder_screen.dart';
import '../../features/gym/presentation/screens/reminder_settings_screen.dart';
import '../../features/gym/presentation/screens/reminders_hub_screen.dart';
import '../../features/gym/presentation/screens/water_reminder_screen.dart';
import '../../features/gym/presentation/screens/weight_loss_screen.dart';
import '../../features/gym/presentation/screens/weight_loss_recipes_screen.dart';
import '../../features/gym/presentation/screens/weight_loss_tips_screen.dart';
import '../../features/gym/domain/weight_loss_profile_model.dart';
import '../../features/gym/domain/reminder_type.dart';
import '../../features/passwords/presentation/screens/add_password_screen.dart';
import '../../features/passwords/presentation/screens/password_detail_screen.dart';
import '../../features/passwords/presentation/screens/password_list_screen.dart';
import '../../features/qr_scanner/presentation/screens/qr_scanner_shell_screen.dart';
import '../../features/qr_scanner/presentation/screens/scan_history_screen.dart';
import '../../features/scanner/presentation/screens/document_detail_screen.dart';
import '../../features/scanner/presentation/screens/extract_pages_screen.dart';
import '../../features/scanner/presentation/screens/fill_sign_screen.dart';
import '../../features/scanner/presentation/screens/image_editor_screen.dart';
import '../../features/scanner/presentation/screens/ocr_result_screen.dart';
import '../../features/scanner/presentation/screens/scan_preview_screen.dart';
import '../../features/scanner/presentation/screens/scanner_list_screen.dart';
import '../../features/todo/presentation/screens/add_edit_task_screen.dart';
import '../../features/todo/presentation/screens/reports_screen.dart';
import '../../features/todo/presentation/screens/share_task_screen.dart';
import '../../features/todo/presentation/screens/shared_tasks_screen.dart';
import '../../features/todo/presentation/screens/task_detail_screen.dart';
import '../../features/habits/presentation/screens/add_edit_habit_screen.dart';
import '../../features/habits/presentation/screens/habit_shell_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/pdf_reader/presentation/screens/pdf_list_screen.dart';
import '../../features/pdf_reader/presentation/screens/pdf_viewer_screen.dart';
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
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _todoNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'todo');
final _passwordsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'passwords');
final _gymNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'gym');
final _scannerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'scanner');
final _qrScannerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'qrScanner');
final _calculatorNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'calculator');
final _translatorNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'translator');
final _habitsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'habits');
final _pdfReaderNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'pdfReader');

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      if (state.matchedLocation == '/splash') return null;
      if (state.matchedLocation == '/walkthrough') return null;

      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/walkthrough',
        builder: (context, state) => const WalkthroughScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Home branch
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
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
                      taskIds: [state.pathParameters['taskId']!],
                    ),
                  ),
                  GoRoute(
                    path: 'share-multiple',
                    builder: (context, state) => ShareTaskScreen(
                      taskIds: state.extra as List<String>,
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
                        path: 'workout/:programId',
                        builder: (context, state) {
                          final program = WorkoutProgramData.getById(
                            state.pathParameters['programId']!,
                          );
                          return WorkoutDetailScreen(program: program!);
                        },
                      ),
                      GoRoute(
                        path: ':category',
                        builder: (context, state) => ExerciseCategoryScreen(
                          category: state.pathParameters['category']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'detail',
                            builder: (context, state) => ExerciseDetailScreen(
                              exercise: state.extra! as ExerciseModel,
                            ),
                          ),
                        ],
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
                  GoRoute(
                    path: 'weight-loss',
                    builder: (context, state) =>
                        const WeightLossScreen(),
                    routes: [
                      GoRoute(
                        path: 'recipes',
                        builder: (context, state) =>
                            const WeightLossRecipesScreen(),
                      ),
                      GoRoute(
                        path: 'tips',
                        builder: (context, state) {
                          final goalName = state.uri.queryParameters['goal'];
                          final goalType = GoalType.values.firstWhere(
                            (e) => e.name == goalName,
                            orElse: () => GoalType.lose,
                          );
                          return WeightLossTipsScreen(goalType: goalType);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Habits branch (index 4 – after Gym)
          StatefulShellBranch(
            navigatorKey: _habitsNavigatorKey,
            routes: [
              GoRoute(
                path: '/habits',
                builder: (context, state) => const HabitShellScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) =>
                        const AddEditHabitScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:habitId',
                    builder: (context, state) => AddEditHabitScreen(
                      habitId: state.pathParameters['habitId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Scanner branch
          StatefulShellBranch(
            navigatorKey: _scannerNavigatorKey,
            routes: [
              GoRoute(
                path: '/scanner',
                builder: (context, state) => const ScannerListScreen(),
                routes: [
                  GoRoute(
                    path: 'preview',
                    builder: (context, state) => ScanPreviewScreen(
                      imagePaths: state.extra as List<String>,
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:documentId',
                    builder: (context, state) => DocumentDetailScreen(
                      documentId: state.pathParameters['documentId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // QR / NFC Scanner branch
          StatefulShellBranch(
            navigatorKey: _qrScannerNavigatorKey,
            routes: [
              GoRoute(
                path: '/qr-scanner',
                builder: (context, state) => const QrScannerShellScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const ScanHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Calculator branch
          StatefulShellBranch(
            navigatorKey: _calculatorNavigatorKey,
            routes: [
              GoRoute(
                path: '/calculator',
                builder: (context, state) => const CalculatorShellScreen(),
              ),
            ],
          ),
          // Translator branch
          StatefulShellBranch(
            navigatorKey: _translatorNavigatorKey,
            routes: [
              GoRoute(
                path: '/translator',
                builder: (context, state) => const TranslatorShellScreen(),
              ),
            ],
          ),
          // PDF Reader branch
          StatefulShellBranch(
            navigatorKey: _pdfReaderNavigatorKey,
            routes: [
              GoRoute(
                path: '/pdf-reader',
                builder: (context, state) => const PdfListScreen(),
                routes: [
                  GoRoute(
                    path: 'view/:documentId',
                    builder: (context, state) {
                      final docId = state.pathParameters['documentId']!;
                      return PdfViewerScreen(
                        key: ValueKey('pdf_viewer_$docId'),
                        documentId: docId,
                      );
                    },
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
      GoRoute(
        path: '/gym/exercises/workout/:programId/execute',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final program = WorkoutProgramData.getById(
            state.pathParameters['programId']!,
          );
          return WorkoutExecutionScreen(program: program!);
        },
      ),
      GoRoute(
        path: '/scanner/detail/:documentId/edit-page',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ImageEditorScreen(
            imagePath: extra['imagePath'] as String,
            pageIndex: extra['pageIndex'] as int,
          );
        },
      ),
      GoRoute(
        path: '/scanner/detail/:documentId/fill-sign',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return FillSignScreen(
            imagePath: extra['imagePath'] as String,
            pageIndex: extra['pageIndex'] as int,
          );
        },
      ),
      GoRoute(
        path: '/scanner/detail/:documentId/extract',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ExtractPagesScreen(
          documentId: state.pathParameters['documentId']!,
        ),
      ),
      GoRoute(
        path: '/scanner/detail/:documentId/ocr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OcrResultScreen(
            imagePaths: extra['imagePaths'] as List<String>,
            documentTitle: extra['title'] as String,
          );
        },
      ),
    ],
  );
}
