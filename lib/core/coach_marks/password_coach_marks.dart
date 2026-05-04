import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'coach_mark_keys.dart';
import 'coach_text_widget.dart';

List<TargetFocus> passwordCoachTargets() => [
      TargetFocus(
        identify: 'password_search',
        keyTarget: CoachMarkKeys.passwordSearch,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Search Passwords',
              body:
                  'Type here to quickly find a saved password by name.\n\n'
                  'As you type, the list filters in real time. Useful when you have many saved passwords.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'password_fab',
        keyTarget: CoachMarkKeys.passwordFab,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 2: Save a Password',
              body:
                  'Tap this + button to store a new password.\n\n'
                  'On the next screen:\n'
                  '1. Enter a title (e.g. "Gmail", "Netflix")\n'
                  '2. Enter your username or email\n'
                  '3. Enter the password\n'
                  '4. Optionally add notes\n'
                  '5. Tap Save\n\n'
                  'All passwords are encrypted and protected with biometric authentication (fingerprint or Face ID).\n\n'
                  'To view a saved password, tap its card and authenticate.',
            ),
          ),
        ],
      ),
    ];
