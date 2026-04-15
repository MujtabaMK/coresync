import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Returns a [Rect] suitable for [sharePositionOrigin] on iOS.
/// Uses the render object of the given [context] if available,
/// otherwise falls back to the centre of the screen.
Rect shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 1,
    height: 1,
  );
}

/// Share plain text using the native share sheet.
Future<ShareResult> shareText(
  String text, {
  required BuildContext context,
  String? subject,
}) {
  return Share.share(
    text,
    subject: subject,
    sharePositionOrigin: shareOrigin(context),
  );
}

/// Share files using the native share sheet.
Future<ShareResult> shareFiles(
  List<XFile> files, {
  required BuildContext context,
  String? subject,
  String? text,
}) {
  return Share.shareXFiles(
    files,
    subject: subject,
    text: text,
    sharePositionOrigin: shareOrigin(context),
  );
}