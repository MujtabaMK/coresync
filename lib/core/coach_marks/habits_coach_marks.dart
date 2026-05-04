import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'coach_mark_keys.dart';
import 'coach_text_widget.dart';

List<TargetFocus> habitsCoachTargets() => [
      TargetFocus(
        identify: 'habit_add_fab',
        keyTarget: CoachMarkKeys.habitAddFab,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 1: Create Your First Habit',
              body:
                  'Tap this + button to create a new habit.\n\n'
                  'On the next screen:\n'
                  '1. Type a habit name (e.g. "Drink 8 glasses of water")\n'
                  '2. Pick an icon that represents your habit\n'
                  '3. Choose how to track it:\n'
                  '   \u2022 One-time — mark done once per day\n'
                  '   \u2022 Multiple — set a target count (e.g. 8 glasses)\n'
                  '   \u2022 Track by volume — for measurable goals\n'
                  '   \u2022 Day counter — counts consecutive days\n'
                  '4. Set which days to do it (daily, specific days, or X times/week)\n'
                  '5. Optionally set a reminder time\n'
                  '6. Tap Save — your habit is ready to track!',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'habit_counter',
        keyTarget: CoachMarkKeys.habitCounter,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 2: Complete Your Habits',
              body:
                  'This counter shows how many habits you\'ve completed today.\n\n'
                  'To complete a habit:\n'
                  '\u2022 Tap the habit card to mark it done\n'
                  '\u2022 For multi-count habits, tap multiple times to increase the count\n'
                  '\u2022 Watch your streak build up as you stay consistent!\n\n'
                  'The counter updates in real time as you check off habits.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'habit_date_nav',
        keyTarget: CoachMarkKeys.habitDateNav,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 3: Review Past Days',
              body:
                  'Use the arrows to navigate between days.\n\n'
                  '\u2022 Tap \u25c0 to go to yesterday\n'
                  '\u2022 Tap \u25b6 to go forward\n'
                  '\u2022 See which habits you completed on any past day\n\n'
                  'This helps you review your consistency and spot missed days.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'habit_filter',
        keyTarget: CoachMarkKeys.habitFilter,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 4: Sort Your Habits',
              body:
                  'Tap here to change the sort order:\n\n'
                  '\u2022 Completed first — see what you\'ve done at the top\n'
                  '\u2022 Incomplete first — focus on what\'s left to do\n\n'
                  'Useful when you have many habits and want to prioritize.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'habit_archive',
        keyTarget: CoachMarkKeys.habitArchive,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 5: Archive & Restore',
              body:
                  'Tap here to view archived habits.\n\n'
                  'To archive a habit you no longer track:\n'
                  '\u2022 Swipe or long-press a habit, then select Archive\n\n'
                  'To bring it back:\n'
                  '\u2022 Open this archive list and tap Restore\n\n'
                  'Archiving keeps your daily list clean without losing history.',
            ),
          ),
        ],
      ),
    ];
