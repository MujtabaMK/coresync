import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Central service for managing coach marks (onboarding tutorials).
///
/// Checks Hive flags to determine if a tutorial has been shown,
/// displays [TutorialCoachMark], and marks as shown on skip/finish.
class CoachMarkService {
  CoachMarkService._();

  static const _boxName = 'app_settings';

  /// Monotonically increasing version, bumped on [resetAll].
  /// Screens compare their local `_coachMarkVersion` against this to
  /// detect resets and re-trigger coach marks even while mounted.
  static int _resetVersion = 0;
  static int get resetVersion => _resetVersion;

  /// Prevents multiple coach marks from showing simultaneously.
  static bool _isShowing = false;

  /// Show coach marks for [screenKey] if they haven't been shown before.
  ///
  /// [targets] is a list of [TargetFocus] to highlight.
  /// [screenKey] is the Hive key, e.g. `coach_mark_home_shown`.
  /// Returns true if the tutorial was shown, false if it was skipped
  /// (already shown previously).
  static Future<bool> showIfNeeded({
    required BuildContext context,
    required String screenKey,
    required List<TargetFocus> targets,
    bool force = false,
  }) async {
    final box = Hive.box(_boxName);

    if (!force && box.get(screenKey, defaultValue: false) == true) {
      return false;
    }

    // Wait for any currently-showing coach mark to finish (up to 30 s).
    for (int i = 0; i < 60 && _isShowing; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!context.mounted) return false;
    }

    // Re-check after waiting — another tutorial may have set the flag.
    if (!force && box.get(screenKey, defaultValue: false) == true) {
      return false;
    }

    // Don't show if a pushed route is currently on top of this screen.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    // Retry up to 5 times (≈2.5 s) waiting for widgets to render.
    // This handles screens that load data asynchronously before
    // building the widgets that hold the coach-mark GlobalKeys.
    for (int attempt = 0; attempt < 5; attempt++) {
      final validTargets = targets
          .where((t) => t.keyTarget?.currentContext != null)
          .toList();

      if (validTargets.isNotEmpty) {
        if (!context.mounted) return false;
        await _show(context, validTargets, box, screenKey);
        return true;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (!context.mounted) return false;
    }

    return false;
  }

  /// Force-show coach marks (used for "Replay Tutorial" or new signup).
  static Future<bool> forceShow({
    required BuildContext context,
    required String screenKey,
    required List<TargetFocus> targets,
  }) {
    return showIfNeeded(
      context: context,
      screenKey: screenKey,
      targets: targets,
      force: true,
    );
  }

  static Future<void> _show(
    BuildContext context,
    List<TargetFocus> targets,
    Box box,
    String screenKey,
  ) async {
    if (!context.mounted) return;

    _isShowing = true;
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.92,
      skipWidget: const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Text(
          'SKIP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      alignSkip: Alignment.topRight,
      paddingFocus: 10,
      // beforeFocus is async & awaited by the package BEFORE it reads
      // the target position — perfect for scrolling off-screen targets
      // into view first.
      beforeFocus: (target) async {
        await _scrollTargetIntoView(target);
      },
      onSkip: () {
        box.put(screenKey, true);
        _isShowing = false;
        return true;
      },
      onFinish: () {
        box.put(screenKey, true);
        _isShowing = false;
      },
    ).show(context: context);
  }

  /// Scrolls a coach mark target into the visible viewport.
  /// Uses [Scrollable.ensureVisible] which is a no-op if the widget
  /// is already visible or not inside a scrollable.
  static Future<void> _scrollTargetIntoView(TargetFocus target) async {
    final ctx = target.keyTarget?.currentContext;
    if (ctx == null) return;
    try {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.3, // position target in upper third of viewport
      );
    } catch (_) {
      // Widget not inside a Scrollable — ignore.
    }
  }

  /// Reset all coach mark flags so tutorials show again.
  /// Also bumps [resetVersion] so mounted screens re-trigger.
  static Future<void> resetAll() async {
    final box = Hive.box(_boxName);
    final keys = box.keys
        .where((k) => k.toString().startsWith('coach_mark_'))
        .toList();
    for (final key in keys) {
      await box.delete(key);
    }
    _isShowing = false; // Reset deadlock flag so forceShow works immediately
    _resetVersion++;
  }

  /// Reset a single screen's coach mark flag.
  static Future<void> reset(String screenKey) async {
    final box = Hive.box(_boxName);
    await box.delete(screenKey);
  }
}
