import 'package:flutter/material.dart';

/// InheritedWidget that provides the shell Scaffold's drawer opener
/// to child screens so they can show a hamburger icon.
class MainShellDrawer extends InheritedWidget {
  const MainShellDrawer({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static MainShellDrawer? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellDrawer>();
  }

  static VoidCallback? of(BuildContext context) {
    return maybeOf(context)?.openDrawer;
  }

  @override
  bool updateShouldNotify(MainShellDrawer oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}
