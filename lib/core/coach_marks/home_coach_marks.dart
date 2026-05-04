import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'coach_mark_keys.dart';
import 'coach_text_widget.dart';

List<TargetFocus> homeCoachTargets() => [
      TargetFocus(
        identify: 'home_menu',
        keyTarget: CoachMarkKeys.homeMenu,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Open the Menu',
              body:
                  'Tap this icon to open the side drawer. From there you can jump to any feature — Fitness, Todo, Passwords, Scanner, and more — without going back to this screen.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_profile',
        keyTarget: CoachMarkKeys.homeProfile,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 2: Your Profile',
              body:
                  'Tap here to open your profile. You can update your display name, change your avatar, manage account settings, and sign out.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_todo',
        keyTarget: CoachMarkKeys.homeTodo,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Todo',
              body:
                  'Create tasks with due dates and reminders. '
                  'Organize with filters, share tasks with friends, '
                  'and view weekly reports.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_passwords',
        keyTarget: CoachMarkKeys.homePasswords,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Passwords',
              body:
                  'Store your credentials in an encrypted vault. '
                  'Search saved passwords and add new ones securely.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_fitness',
        keyTarget: CoachMarkKeys.homeFitness,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Fitness',
              body:
                  'Your complete health tracker — steps, water, food, sleep, '
                  'exercises, weight goals, and daily reports all in one place.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_habits',
        keyTarget: CoachMarkKeys.homeHabits,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Habits',
              body:
                  'Build daily habits with streaks. '
                  'Set target counts, track progress by date, '
                  'and archive completed habits.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_scanner',
        keyTarget: CoachMarkKeys.homeScanner,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Scanner',
              body:
                  'Scan documents using your camera. '
                  'Captured scans are saved and searchable for quick access.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_qr',
        keyTarget: CoachMarkKeys.homeQr,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'QR / Barcode',
              body:
                  'Scan QR codes, barcodes, and NFC tags. '
                  'View your scan history and quickly access results.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_calculator',
        keyTarget: CoachMarkKeys.homeCalculator,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Calculator',
              body:
                  'Three modes: simple calculator for everyday math, '
                  'scientific mode for advanced functions, '
                  'and a unit converter for length, weight, temperature, and more.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_translator',
        keyTarget: CoachMarkKeys.homeTranslator,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Translator',
              body:
                  'Translate text and voice between languages. '
                  'Use conversation mode for real-time two-way translation.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_pdf',
        keyTarget: CoachMarkKeys.homePdf,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'PDF Reader',
              body:
                  'Import and read PDF files. '
                  'Search through your library and view documents on the go.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home_replay',
        keyTarget: CoachMarkKeys.homeReplayTutorial,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Replay Training',
              body:
                  'Forgot how something works? Tap this button anytime to restart the step-by-step training for every screen in the app.',
            ),
          ),
        ],
      ),
    ];
