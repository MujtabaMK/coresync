import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'coach_mark_keys.dart';
import 'coach_text_widget.dart';

List<TargetFocus> scannerCoachTargets() => [
      TargetFocus(
        identify: 'scanner_search',
        keyTarget: CoachMarkKeys.scannerSearch,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Find Documents',
              body:
                  'Type here to search your scanned documents by title.\n\n'
                  'The list filters as you type, so you can quickly find any document.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'scanner_fab',
        keyTarget: CoachMarkKeys.scannerFab,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 2: Scan a Document',
              body:
                  'Tap this + button to add a document.\n\n'
                  'You\'ll see two options:\n\n'
                  '1. Scan Document — opens camera with auto edge detection:\n'
                  '   \u2022 Point your camera at a document\n'
                  '   \u2022 The app auto-detects edges\n'
                  '   \u2022 Tap capture to scan\n'
                  '   \u2022 You can scan up to 20 pages\n\n'
                  '2. Import from Gallery — pick existing photos:\n'
                  '   \u2022 Select one or more images\n'
                  '   \u2022 They\'ll be converted to a document\n\n'
                  'After scanning, you can crop, rotate, add OCR text extraction, and share as PDF.\n\n'
                  'Tip: Long-press documents to select multiple, then tap "Combine" to merge them.',
            ),
          ),
        ],
      ),
    ];
