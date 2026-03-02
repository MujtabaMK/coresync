import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/password_entry_model.dart';
import '../providers/password_provider.dart';

class PasswordDetailScreen extends StatefulWidget {
  final String passwordId;

  const PasswordDetailScreen({super.key, required this.passwordId});

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _obscurePassword = true;

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      showSuccessSnackBar(context, '$label copied to clipboard');
    }
  }

  Future<void> _deletePassword(PasswordEntryModel entry) async {
    final cubit = context.read<PasswordCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Password',
      content:
          'Are you sure you want to delete the password for "${entry.passwordFor}"? This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    try {
      await cubit.deletePassword(entry.id);

      if (mounted) {
        showSuccessSnackBar(context, 'Password deleted');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to delete: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Details'),
      ),
      body: BlocBuilder<PasswordCubit, PasswordState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(child: Text('Error: ${state.error}'));
          }

          final entry = state.passwords
              .cast<PasswordEntryModel?>()
              .firstWhere(
                (e) => e!.id == widget.passwordId,
                orElse: () => null,
              );

          if (entry == null) {
            return const Center(child: Text('Password not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldRow(
                        context,
                        label: 'Service',
                        value: entry.passwordFor,
                        icon: Icons.apps,
                        onCopy: () => _copyToClipboard(
                          entry.passwordFor,
                          'Service name',
                        ),
                      ),
                      const Divider(height: 24),
                      _buildFieldRow(
                        context,
                        label: 'Username',
                        value: entry.username,
                        icon: Icons.person,
                        onCopy: () => _copyToClipboard(
                          entry.username,
                          'Username',
                        ),
                      ),
                      const Divider(height: 24),
                      _buildPasswordRow(context, entry),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _deletePassword(entry),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                icon: const Icon(Icons.delete),
                label: const Text('Delete Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFieldRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: onCopy,
          tooltip: 'Copy $label',
        ),
      ],
    );
  }

  Widget _buildPasswordRow(BuildContext context, PasswordEntryModel entry) {
    return Row(
      children: [
        Icon(
          Icons.lock,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _obscurePassword
                    ? '\u2022' * entry.password.length
                    : entry.password,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            size: 20,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _copyToClipboard(entry.password, 'Password'),
          tooltip: 'Copy password',
        ),
      ],
    );
  }
}
