import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'attendance_screen.dart';
import 'gym_home_screen.dart';
import 'membership_screen.dart';
import 'report_screen.dart';
import 'water_intake_screen.dart';

class GymShellScreen extends StatefulWidget {
  const GymShellScreen({super.key});

  @override
  State<GymShellScreen> createState() => _GymShellScreenState();
}

class _GymShellScreenState extends State<GymShellScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_rounded), text: 'Home'),
    Tab(icon: Icon(Icons.card_membership_rounded), text: 'Plans'),
    Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Attendance'),
    Tab(icon: Icon(Icons.water_drop_rounded), text: 'Water'),
    Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Report'),
  ];

  static const List<Widget> _screens = [
    GymHomeScreen(),
    MembershipScreen(),
    AttendanceScreen(),
    WaterIntakeScreen(),
    ReportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Gym Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs,
        ),
      ),
      body: TabBarView(controller: _tabController, children: _screens),
    );
  }
}
