import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/qr_scanner_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';
import '../../../../core/widgets/main_shell_drawer.dart';
import '../providers/qr_scanner_provider.dart';
import 'barcode_screen.dart';
import 'nfc_screen.dart';
import 'qr_code_screen.dart';

class QrScannerShellScreen extends StatefulWidget {
  const QrScannerShellScreen({super.key});

  @override
  State<QrScannerShellScreen> createState() => _QrScannerShellScreenState();
}

class _QrScannerShellScreenState extends State<QrScannerShellScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _nfcAvailable = false;
  bool _ready = false;
  bool _cameraReady = true;
  int _previousIndex = 0;
  int _coachMarkVersion = -1;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    final available = await context.read<QrScannerCubit>().isNfcAvailable();
    if (!mounted) return;
    setState(() {
      _nfcAvailable = available;
      _tabController = TabController(
        length: available ? 3 : 2,
        vsync: this,
      );
      _tabController!.addListener(_onTabChanged);
      _ready = true;
    });
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
          screenKey: 'coach_mark_qr_scanner_shown',
          targets: qrScannerCoachTargets(),
        );
      });
    });
  }

  void _onTabChanged() {
    if (_tabController!.indexIsChanging) return;
    final newIndex = _tabController!.index;
    if (newIndex == _previousIndex) return;
    _previousIndex = newIndex;

    // Close the camera briefly before reopening on the new tab.
    // This avoids the "MobileScannerController is already running" error
    // caused by the platform singleton not being fully released.
    setState(() => _cameraReady = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _cameraReady = true);
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildActiveTab() {
    if (!_cameraReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final index = _tabController!.index;
    switch (index) {
      case 0:
        return const QrCodeScreen();
      case 1:
        return const BarcodeScreen();
      case 2:
        return const NfcScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    _triggerCoachMark();
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: MainShellDrawer.of(context),
          ),
          title: const Text('QR / Barcode Scanner'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final tabs = <Tab>[
      const Tab(icon: Icon(Icons.qr_code), text: 'QR Code'),
      const Tab(icon: Icon(Icons.barcode_reader), text: 'Barcode'),
      if (_nfcAvailable) const Tab(icon: Icon(Icons.nfc), text: 'NFC'),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: MainShellDrawer.of(context),
        ),
        title: const Text('QR / Barcode Scanner'),
        actions: [
          IconButton(
            key: CoachMarkKeys.qrHistory,
            icon: const Icon(Icons.history),
            tooltip: 'Scan History',
            onPressed: () => context.push('/qr-scanner/history'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: TabBar(
          key: CoachMarkKeys.qrTabBar,
          controller: _tabController,
          tabs: tabs,
        ),
      ),
      body: _buildActiveTab(),
    );
  }
}