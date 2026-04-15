import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/nfc_tag_model.dart';
import '../providers/qr_scanner_provider.dart';

class NfcScreen extends StatefulWidget {
  const NfcScreen({super.key});

  @override
  State<NfcScreen> createState() => _NfcScreenState();
}

class _NfcScreenState extends State<NfcScreen> {
  bool _checking = true;
  bool _available = false;
  bool _scanning = false;
  NfcTagModel? _lastTag;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final cubit = context.read<QrScannerCubit>();
    final available = await cubit.isNfcAvailable();
    if (mounted) {
      setState(() {
        _available = available;
        _checking = false;
      });
    }
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      _lastTag = null;
    });
    final cubit = context.read<QrScannerCubit>();
    cubit.nfcService.startSession(
      onTag: (tag) {
        if (!mounted) return;
        setState(() {
          _lastTag = tag;
          _scanning = false;
        });
        // Save to history
        final payload = tag.payload ?? tag.id;
        cubit.addScan(value: payload, type: 'nfc');
        cubit.nfcService.stopSession();
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NFC error: $e')),
        );
        cubit.nfcService.stopSession();
      },
    );
  }

  @override
  void dispose() {
    context.read<QrScannerCubit>().nfcService.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_checking) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_available) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.nfc, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'NFC Not Available',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Your device does not support NFC or it is disabled in settings.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.nfc,
              size: 80,
              color: _scanning
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            if (_scanning) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Hold your device near an NFC tag...',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.nfc),
                label: const Text('Scan NFC Tag'),
              ),
            ],
            if (_lastTag != null) ...[
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tag Read Successfully',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('ID: ${_lastTag!.id}'),
                      Text('Tech: ${_lastTag!.techType}'),
                      if (_lastTag!.payload != null)
                        Text('Payload: ${_lastTag!.payload}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
