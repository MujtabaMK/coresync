import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/password_repository.dart';
import '../../domain/password_entry_model.dart';

class PasswordState {
  const PasswordState({
    this.passwords = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<PasswordEntryModel> passwords;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  List<PasswordEntryModel> get filteredPasswords {
    if (searchQuery.isEmpty) return passwords;
    final q = searchQuery.toLowerCase();
    return passwords
        .where((p) =>
            p.passwordFor.toLowerCase().contains(q) ||
            p.username.toLowerCase().contains(q))
        .toList();
  }

  PasswordState copyWith({
    List<PasswordEntryModel>? passwords,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return PasswordState(
      passwords: passwords ?? this.passwords,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PasswordCubit extends Cubit<PasswordState> {
  PasswordCubit({required PasswordRepository repository})
      : _repository = repository,
        super(const PasswordState());

  final PasswordRepository _repository;

  PasswordRepository get repository => _repository;

  Future<void> loadPasswords() async {
    emit(state.copyWith(isLoading: true));
    try {
      final passwords = await _repository.getAllPasswords();
      emit(state.copyWith(passwords: passwords, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> addPassword(PasswordEntryModel entry) async {
    await _repository.addPassword(entry);
    await loadPasswords();
  }

  Future<void> deletePassword(String id) async {
    await _repository.deletePassword(id);
    await loadPasswords();
  }
}
