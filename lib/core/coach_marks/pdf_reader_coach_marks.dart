import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'coach_mark_keys.dart';
import 'coach_text_widget.dart';

List<TargetFocus> pdfReaderCoachTargets() => [
      TargetFocus(
        identify: 'pdf_search',
        keyTarget: CoachMarkKeys.pdfSearch,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Search Your Library',
              body:
                  'Type here to search your PDF library by title.\n\n'
                  'Results filter as you type. Tap the X to clear your search.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'pdf_import',
        keyTarget: CoachMarkKeys.pdfImport,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 2: Import a PDF',
              body:
                  'Tap this + button to add a PDF.\n\n'
                  'You\'ll see two options:\n\n'
                  '1. From device — pick a PDF file from your phone storage\n'
                  '2. From URL — paste a web link to download a PDF\n\n'
                  'After importing:\n'
                  '\u2022 Tap the PDF card to open and read it\n'
                  '\u2022 Swipe between pages\n'
                  '\u2022 Pinch to zoom in and out\n'
                  '\u2022 Swipe left on a card to delete it',
            ),
          ),
        ],
      ),
    ];
