import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/gym/data/gym_repository.dart';
import 'features/gym/data/medicine_repository.dart';
import 'features/gym/presentation/providers/gym_provider.dart';
import 'features/gym/presentation/providers/medicine_provider.dart';
import 'features/passwords/data/password_repository.dart';
import 'features/passwords/data/password_sync_repository.dart';
import 'features/passwords/presentation/providers/password_provider.dart';
import 'features/calculator/presentation/providers/calculator_provider.dart';
import 'features/translator/presentation/providers/translator_provider.dart';
import 'features/gym/data/recipe_repository.dart';
import 'features/gym/presentation/providers/recipe_provider.dart';
import 'features/habits/data/habit_repository.dart';
import 'features/habits/presentation/providers/habit_provider.dart';
import 'features/qr_scanner/data/qr_scanner_repository.dart';
import 'features/qr_scanner/presentation/providers/qr_scanner_provider.dart';
import 'features/scanner/data/scanner_repository.dart';
import 'features/scanner/presentation/providers/scanner_provider.dart';
import 'features/todo/data/share_repository.dart';
import 'features/todo/data/todo_repository.dart';
import 'features/todo/presentation/providers/report_provider.dart';
import 'features/todo/presentation/providers/todo_provider.dart';

class CoreSyncApp extends StatefulWidget {
  const CoreSyncApp({super.key});

  @override
  State<CoreSyncApp> createState() => _CoreSyncAppState();
}

class _CoreSyncAppState extends State<CoreSyncApp> {
  late final GoRouter _router;
  late final AuthRepository _authRepository;
  late final AuthCubit _authCubit;
  late final ThemeCubit _themeCubit;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
    _authRepository = AuthRepository();
    _authCubit = AuthCubit(authRepository: _authRepository)..init();
    _themeCubit = ThemeCubit()..init();

    // Start notification listener if user is already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      PushNotificationService.saveTokenForUser();
      PushNotificationService.listenForNotifications();
    }
  }

  @override
  void dispose() {
    _themeCubit.close();
    _authCubit.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<ThemeCubit>.value(value: _themeCubit),
      ],
      child: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (prev, curr) => prev.user?.uid != curr.user?.uid,
        listener: (context, authState) {
          final uid =
              authState.user?.uid ??
              FirebaseAuth.instance.currentUser?.uid ??
              '';

          if (uid.isNotEmpty) {
            PushNotificationService.saveTokenForUser();
            PushNotificationService.listenForNotifications();
          } else {
            PushNotificationService.dispose();
          }
        },
        buildWhen: (prev, curr) => prev.user?.uid != curr.user?.uid,
        builder: (context, authState) {
          final uid =
              authState.user?.uid ??
              FirebaseAuth.instance.currentUser?.uid ??
              '';

          return MultiBlocProvider(
            providers: [
              BlocProvider<PasswordCubit>(
                key: ValueKey('password_$uid'),
                create: (_) {
                  final cubit = PasswordCubit(
                    repository: PasswordRepository(
                      syncRepo: PasswordSyncRepository(),
                      uid: uid,
                    ),
                  );
                  cubit.loadPasswords();
                  return cubit;
                },
              ),
              BlocProvider<TodoCubit>(
                key: ValueKey('todo_$uid'),
                create: (_) {
                  final cubit = TodoCubit(
                    todoRepository: TodoRepository(),
                    shareRepository: ShareRepository(),
                    uid: uid,
                  );
                  if (uid.isNotEmpty) {
                    cubit.loadMyTasks();
                    cubit.loadSharedTasks();
                  }
                  return cubit;
                },
              ),
              BlocProvider<GymCubit>(
                key: ValueKey('gym_$uid'),
                create: (_) {
                  final cubit = GymCubit(
                    repository: GymRepository(uid: uid),
                  );
                  if (uid.isNotEmpty) cubit.loadAll();
                  return cubit;
                },
              ),
              BlocProvider<MedicineCubit>(
                key: ValueKey('medicine_$uid'),
                create: (_) {
                  final cubit = MedicineCubit(
                    repository: MedicineRepository(uid: uid),
                  );
                  if (uid.isNotEmpty) cubit.loadMedicines();
                  return cubit;
                },
              ),
              BlocProvider<ScannerCubit>(
                key: ValueKey('scanner_$uid'),
                create: (_) {
                  final cubit = ScannerCubit(
                    repository: ScannerRepository(uid: uid),
                  );
                  if (uid.isNotEmpty) cubit.loadDocuments();
                  return cubit;
                },
              ),
              BlocProvider<ReportCubit>(create: (_) => ReportCubit()),
              BlocProvider<QrScannerCubit>(
                create: (_) {
                  final cubit = QrScannerCubit(
                    repository: QrScannerRepository(),
                  );
                  cubit.loadHistory();
                  return cubit;
                },
              ),
              BlocProvider<CalculatorCubit>(
                create: (_) => CalculatorCubit(),
              ),
              BlocProvider<TranslatorCubit>(
                create: (_) => TranslatorCubit(),
              ),
              BlocProvider<RecipeCubit>(
                create: (_) => RecipeCubit(
                  repository: RecipeRepository(),
                ),
              ),
              BlocProvider<HabitCubit>(
                key: ValueKey('habits_$uid'),
                create: (_) {
                  final cubit = HabitCubit(
                    repository: HabitRepository(uid: uid),
                  );
                  if (uid.isNotEmpty) cubit.loadHabits();
                  return cubit;
                },
              ),
            ],
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: MaterialApp.router(
                    title: 'CoreSync Go',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeMode,
                    routerConfig: _router,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}