import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/share_utils.dart';
import '../providers/qr_scanner_provider.dart';
import '../widgets/scan_result_sheet.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _permissionGranted = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permission when user returns from app settings
    if (state == AppLifecycleState.resumed && !_permissionGranted) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    var status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (!mounted) return;

    if (status.isGranted || status.isLimited) {
      _controller = MobileScannerController(
        formats: [
          BarcodeFormat.ean8,
          BarcodeFormat.ean13,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code39,
          BarcodeFormat.code93,
          BarcodeFormat.code128,
          BarcodeFormat.itf14,
          BarcodeFormat.codabar,
          BarcodeFormat.dataMatrix,
          BarcodeFormat.pdf417,
        ],
      );
      setState(() {
        _permissionGranted = true;
        _permissionChecked = true;
      });
    } else {
      setState(() {
        _permissionGranted = false;
        _permissionChecked = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _hasScanned = true;
    _controller?.stop();

    final value = barcode!.rawValue!;
    final cubit = context.read<QrScannerCubit>();

    cubit.addScan(value: value, type: 'barcode').then((result) {
      if (!mounted) return;
      showModalBottomSheet<ScanResultAction>(
        context: context,
        builder: (_) => ScanResultSheet(result: result),
      ).then((action) async {
        if (action == ScanResultAction.share && mounted) {
          await shareText(result.value, context: context);
        }
        if (mounted) {
          setState(() => _hasScanned = false);
          _controller?.start();
        }
      });
    });
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Access Required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Please grant camera permission to scan barcodes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                // Try requesting again first
                final status = await Permission.camera.request();
                if (status.isGranted || status.isLimited) {
                  if (!mounted) return;
                  _controller = MobileScannerController(
                    formats: [
                      BarcodeFormat.ean8,
                      BarcodeFormat.ean13,
                      BarcodeFormat.upcA,
                      BarcodeFormat.upcE,
                      BarcodeFormat.code39,
                      BarcodeFormat.code93,
                      BarcodeFormat.code128,
                      BarcodeFormat.itf14,
                      BarcodeFormat.codabar,
                      BarcodeFormat.dataMatrix,
                      BarcodeFormat.pdf417,
                    ],
                  );
                  setState(() => _permissionGranted = true);
                } else if (status.isPermanentlyDenied) {
                  await openAppSettings();
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_permissionGranted) {
      return _buildPermissionDenied();
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _controller!,
          onDetect: _onDetect,
          errorBuilder: (context, error) {
            return _buildPermissionDenied();
          },
        ),
        Center(
          child: Container(
            width: 300,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Point camera at a barcode',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    shadows: [const Shadow(blurRadius: 8)],
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
