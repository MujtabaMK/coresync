import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/password_coach_marks.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/services/coach_mark_service.dart';
import '../../../../core/widgets/main_shell_drawer.dart';
import '../providers/password_provider.dart';
import '../widgets/password_tile.dart';

enum _AuthState { checking, locked, unlocked }

class PasswordListScreen extends StatefulWidget {
  const PasswordListScreen({super.key});

  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen>
    with WidgetsBindingObserver {
  _AuthState _authState = _AuthState.checking;
  bool _biometricAvailable = false;
  bool _wasInBackground = false;
  int _coachMarkVersion = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndAuthenticate();
  }

  void _triggerCoachMark() {
    final v = CoachMarkService.resetVersion;
    if (_coachMarkVersion == v) return;
    _coachMarkVersion = v;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        CoachMarkService.showIfNeeded(
          context: context,
          screenKey: 'coach_mark_passwords_shown',
          targets: passwordCoachTargets(),
        );
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      if (_authState == _AuthState.unlocked) {
        setState(() => _authState = _AuthState.locked);
        _authenticate();
      }
    }
  }

  Future<void> _checkAndAuthenticate() async {
    _biometricAvailable = await BiometricAuthService.isAvailable();
    if (!_biometricAvailable) {
      if (mounted) setState(() => _authState = _AuthState.unlocked);
      return;
    }
    if (mounted) setState(() => _authState = _AuthState.locked);
    await _authenticate();
  }

  Future<void> _authenticate() async {
    final success = await BiometricAuthService.authenticate();
    if (mounted) {
      setState(() {
        _authState = success ? _AuthState.unlocked : _AuthState.locked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _triggerCoachMark();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: MainShellDrawer.of(context),
        ),
        title: const Text('Passwords'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: switch (_authState) {
        _AuthState.checking => const Center(child: CircularProgressIndicator()),
        _AuthState.locked => _buildLockedView(context),
        _AuthState.unlocked => _buildPasswordList(),
      },
      floatingActionButton: IgnorePointer(
        ignoring: _authState != _AuthState.unlocked,
        child: AnimatedOpacity(
          opacity: _authState == _AuthState.unlocked ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            key: CoachMarkKeys.passwordFab,
            heroTag: 'passwordFab',
            onPressed: () => context.go('/passwords/add'),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fingerprint,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Authentication Required',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your identity to view passwords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _authenticate,
            icon: const Icon(Icons.lock_open),
            label: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordList() {
    return Column(
      children: [
        Padding(
          key: CoachMarkKeys.passwordSearch,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search passwords...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              context.read<PasswordCubit>().setSearchQuery(value);
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<PasswordCubit, PasswordState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(child: Text('Error: ${state.error}'));
              }

              final passwords = state.filteredPasswords;

              if (passwords.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No passwords saved yet',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first password',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: passwords.length,
                itemBuilder: (context, index) {
                  return PasswordTile(entry: passwords[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
