import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/utils/share_utils.dart' as share_utils;
import 'package:share_plus/share_plus.dart';

class PdfToolsSheet extends StatelessWidget {
  const PdfToolsSheet({
    super.key,
    required this.title,
    required this.filePath,
    required this.onRename,
    required this.onDelete,
  });

  final String title;
  final String filePath;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              share_utils.shareFiles(
                [XFile(filePath)],
                context: context,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Print'),
            onTap: () async {
              Navigator.pop(context);
              final bytes = await File(filePath).readAsBytes();
              await Printing.layoutPdf(onLayout: (_) => bytes);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              onRename();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
