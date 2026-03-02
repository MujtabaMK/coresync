import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = true,
    this.error,
  });

  final User? user;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState());

  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthRepository get repository => _authRepository;

  void init() {
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) {
        emit(AuthState(user: user, isLoading: false));
      },
      onError: (error) {
        emit(AuthState(
          isLoading: false,
          error: error.toString(),
        ));
      },
    );
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
