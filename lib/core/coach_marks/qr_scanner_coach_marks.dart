import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'coach_mark_keys.dart';
import 'coach_text_widget.dart';

List<TargetFocus> qrScannerCoachTargets() => [
      TargetFocus(
        identify: 'qr_tab_bar',
        keyTarget: CoachMarkKeys.qrTabBar,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Choose Scanner Mode',
              body:
                  'Tap a tab to switch scanner modes:\n\n'
                  '\u2022 QR Code — scan QR codes on products, tickets, menus, etc. Just point your camera at the code and it will read automatically\n'
                  '\u2022 Barcode — scan product barcodes to get their details\n'
                  '\u2022 NFC — tap your phone on NFC tags to read them (if your device supports NFC)\n\n'
                  'The camera opens immediately — just point and scan!',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'qr_history',
        keyTarget: CoachMarkKeys.qrHistory,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 2: View Scan History',
              body:
                  'Tap here to see all your past scans.\n\n'
                  'From the history screen you can:\n'
                  '\u2022 Copy scanned text or URLs\n'
                  '\u2022 Re-open links in your browser\n'
                  '\u2022 Delete old scans\n\n'
                  'All scans are saved automatically so you never lose a result.',
            ),
          ),
        ],
      ),
    ];
