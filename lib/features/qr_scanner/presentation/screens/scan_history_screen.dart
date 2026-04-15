import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/scan_result_model.dart';
import '../providers/qr_scanner_provider.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          BlocBuilder<QrScannerCubit, QrScannerState>(
            builder: (context, state) {
              if (state.history.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear history',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear History?'),
                      content: const Text(
                          'This will delete all scan history. This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    context.read<QrScannerCubit>().clearHistory();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<QrScannerCubit, QrScannerState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No scan history yet',
                      style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.history.length,
            itemBuilder: (context, index) {
              final item = state.history[index];
              return _ScanHistoryTile(item: item);
            },
          );
        },
      ),
    );
  }
}

class _ScanHistoryTile extends StatelessWidget {
  const _ScanHistoryTile({required this.item});

  final ScanResultModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y  h:mm a');

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) {
        context.read<QrScannerCubit>().deleteScan(item.id);
      },
      child: ListTile(
        leading: Icon(_iconFor(item.type)),
        title: Text(
          item.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(dateFormat.format(item.scannedAt)),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: item.value));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'qr' => Icons.qr_code,
      'barcode' => Icons.barcode_reader,
      'nfc' => Icons.nfc,
      _ => Icons.qr_code_scanner,
    };
  }
}
