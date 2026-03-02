import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/gym/data/gym_repository.dart';
import 'features/gym/presentation/providers/gym_provider.dart';
import 'features/passwords/data/password_repository.dart';
import 'features/passwords/presentation/providers/password_provider.dart';
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
  late final PasswordRepository _passwordRepository;
  late final PasswordCubit _passwordCubit;
  late final GymRepository _gymRepository;
  late final GymCubit _gymCubit;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
    _authRepository = AuthRepository();
    _authCubit = AuthCubit(authRepository: _authRepository)..init();
    _passwordRepository = PasswordRepository();
    _passwordCubit = PasswordCubit(repository: _passwordRepository)
      ..loadPasswords();
    _gymRepository = GymRepository();
    _gymCubit = GymCubit(repository: _gymRepository)..loadAll();
  }

  @override
  void dispose() {
    _gymCubit.close();
    _passwordCubit.close();
    _authCubit.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<PasswordCubit>.value(value: _passwordCubit),
        BlocProvider<GymCubit>.value(value: _gymCubit),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (prev, curr) => prev.user?.uid != curr.user?.uid,
        builder: (context, authState) {
          final uid = authState.user?.uid ??
              FirebaseAuth.instance.currentUser?.uid ??
              '';

          return MultiBlocProvider(
            providers: [
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
              BlocProvider<ReportCubit>(
                create: (_) => ReportCubit(),
              ),
            ],
            child: MaterialApp.router(
              title: 'CoreSync',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system,
              routerConfig: _router,
            ),
          );
        },
      ),
    );
  }
}
