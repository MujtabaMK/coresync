import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'coach_mark_keys.dart';
import 'coach_text_widget.dart';

List<TargetFocus> translatorCoachTargets() => [
      TargetFocus(
        identify: 'trans_voice',
        keyTarget: CoachMarkKeys.transVoice,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Voice Translate',
              body:
                  'Tap here to translate by speaking.\n\n'
                  'How to use:\n'
                  '1. Select your source language (e.g. English)\n'
                  '2. Select the target language (e.g. Spanish)\n'
                  '3. Tap the microphone button and speak\n'
                  '4. Your speech is converted to text\n'
                  '5. The translation appears instantly\n\n'
                  'You can also type text directly to translate it.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'trans_conversation',
        keyTarget: CoachMarkKeys.transConversation,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 2: Conversation Mode',
              body:
                  'Tap here for two-way live translation.\n\n'
                  'How to use:\n'
                  '1. Set the two languages (e.g. English \u2194 Hindi)\n'
                  '2. Person 1 taps the left mic and speaks in Language 1\n'
                  '3. The translation appears in Language 2\n'
                  '4. Person 2 taps the right mic and speaks in Language 2\n'
                  '5. The translation appears in Language 1\n\n'
                  'Perfect for real-time conversations with someone who speaks a different language!',
            ),
          ),
        ],
      ),
    ];
