import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/password_entry_model.dart';

class PasswordTile extends StatelessWidget {
  final PasswordEntryModel entry;

  const PasswordTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.lock),
        title: Text(entry.passwordFor),
        subtitle: Text(entry.username),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/passwords/detail/${entry.id}'),
      ),
    );
  }
}
