import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/gym_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';
import '../../../../core/widgets/main_shell_drawer.dart';
import 'attendance_screen.dart';
import 'gym_home_screen.dart';
import 'membership_screen.dart';
import 'report_screen.dart';
import 'steps_screen.dart';
import 'track_food_screen.dart';
import 'water_intake_screen.dart';

class GymShellScreen extends StatefulWidget {
  const GymShellScreen({super.key});

  @override
  State<GymShellScreen> createState() => _GymShellScreenState();
}

class _GymShellScreenState extends State<GymShellScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _coachMarkVersion = -1;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_rounded), text: 'Home'),
    Tab(icon: Icon(Icons.card_membership_rounded), text: 'Plans'),
    Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Attendance'),
    Tab(icon: Icon(Icons.water_drop_rounded), text: 'Water'),
    Tab(icon: Icon(Icons.restaurant_rounded), text: 'Food'),
    Tab(icon: Icon(Icons.directions_walk_rounded), text: 'Steps'),
    Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Report'),
  ];

  static const List<Widget> _screens = [
    GymHomeScreen(),
    MembershipScreen(),
    AttendanceScreen(),
    WaterIntakeScreen(),
    TrackFoodScreen(),
    StepsScreen(),
    ReportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
          screenKey: 'coach_mark_gym_shown',
          targets: gymCoachTargets(),
        );
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Fitness Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: TabBar(
          key: CoachMarkKeys.gymTabBar,
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
