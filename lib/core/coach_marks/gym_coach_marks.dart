import 'dart:io';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'coach_mark_keys.dart';
import 'coach_text_widget.dart';

List<TargetFocus> gymCoachTargets() => [
      TargetFocus(
        identify: 'gym_tab_bar',
        keyTarget: CoachMarkKeys.gymTabBar,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Fitness Tracker Tabs',
              body:
                  'Swipe or tap to switch between these tabs:\n\n'
                  '\u2022 Home — your daily dashboard with stats and quick access\n'
                  '\u2022 Plans — activate a gym membership plan\n'
                  '\u2022 Attendance — mark daily gym attendance\n'
                  '\u2022 Water — track your water intake with an animated bottle\n'
                  '\u2022 Food — log meals, track calories, macros, and micronutrients\n'
                  '\u2022 Steps — see your step count, activity rings, and calorie burn\n'
                  '\u2022 Report — view weekly/monthly fitness reports\n\n'
                  'Start by exploring each tab!',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> gymHomeCoachTargets() => [
      TargetFocus(
        identify: 'gym_exercises',
        keyTarget: CoachMarkKeys.gymExercises,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Exercises',
              body:
                  'Browse workouts by body focus — Abs, Chest, Legs, Arms, Back, and more. '
                  'Tap a program to see exercises with step-by-step instructions.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_reminders',
        keyTarget: CoachMarkKeys.gymReminders,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Reminders',
              body:
                  'Set up push notifications for meals, water, workouts, walks, '
                  'weighing, and health logging. Customize times for each.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_medicine',
        keyTarget: CoachMarkKeys.gymMedicine,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Medicine',
              body:
                  'Schedule medicines and supplements with dose reminders. '
                  'Set type, dose, frequency, and get notifications so you never miss a dose.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_weight_plan',
        keyTarget: CoachMarkKeys.gymWeightPlan,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Weight Plan',
              body:
                  'Enter your details to get personalized calorie targets, BMI score, '
                  'and macro goals. Export a PDF diet chart to share with your trainer.',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> stepsCoachTargets() => [
      TargetFocus(
        identify: 'steps_rings',
        keyTarget: CoachMarkKeys.stepsRings,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Your Activity Rings',
              body:
                  'These three rings track your daily activity:\n\n'
                  '\u2022 Outer ring (red) — Steps: Your step count toward your daily goal\n'
                  '\u2022 Middle ring (green) — Active minutes: How long you were moving\n'
                  '\u2022 Inner ring (blue) — Calories burned from walking and exercise\n\n'
                  'Your step goal is personalized based on your BMI. The rings fill up as you move throughout the day.\n\n'
                  'Just keep your phone in your pocket — steps are tracked automatically!',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'steps_stats',
        keyTarget: CoachMarkKeys.stepsStats,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 2: Detailed Stats',
              body:
                  'Here you can see your numbers at a glance:\n\n'
                  '\u2022 Steps — total steps counted today\n'
                  '\u2022 Distance — estimated walking distance\n'
                  '\u2022 Active Minutes — time spent in motion\n'
                  '\u2022 Calories — energy burned from activity\n\n'
                  'The app detects whether you\'re walking, running, or cycling, and your current activity shows at the top.\n\n'
                  'Tip: Steps sync to Firestore so they\'re preserved even if you reinstall the app.',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> stepPermissionCoachTargets() => [
      TargetFocus(
        identify: 'step_permission',
        keyTarget: CoachMarkKeys.stepsRings,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: CoachText(
              title: Platform.isIOS
                  ? 'Motion & Health Access'
                  : 'Step Tracking Permission',
              body: Platform.isIOS
                  ? 'CoreSync needs Motion & Health access to track your steps automatically.\n\n'
                      '1. A permission dialog will appear\n'
                      '2. Tap "Allow" to enable step counting\n'
                      '3. Your steps will start tracking in the background'
                  : 'CoreSync needs Activity Recognition permission to count your steps.\n\n'
                      '1. A permission dialog will appear next\n'
                      '2. Tap "Allow" to enable step counting\n'
                      '3. Steps will be tracked in the background automatically',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> batteryCoachTargets() => [
      TargetFocus(
        identify: 'step_battery',
        keyTarget: CoachMarkKeys.stepsBattery,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Important: Battery Settings',
              body:
                  'Your phone may stop step tracking when the app is in the background.\n\n'
                  'To fix this:\n'
                  '1. Tap this banner to open battery settings\n'
                  '2. Find "CoreSync" in the app list\n'
                  '3. Select "Unrestricted" or "Don\'t optimize"\n'
                  '4. This allows step counting to run all day\n\n'
                  'Without this, your step count may freeze when the screen turns off.',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> foodCoachTargets() => [
      TargetFocus(
        identify: 'food_summary',
        keyTarget: CoachMarkKeys.foodSummary,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Your Daily Summary',
              body:
                  'This card shows your daily calorie tracking:\n\n'
                  '\u2022 The circle fills as you eat — green means on track, red means over target\n'
                  '\u2022 "Remaining" tells you how many calories you have left for the day\n'
                  '\u2022 "Net" = calories eaten minus calories burned from steps and workouts\n\n'
                  'Your calorie target is calculated from your Weight Plan. Log meals to see this update!',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'food_track_food',
        keyTarget: CoachMarkKeys.foodTrackFood,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Track Food',
              body:
                  'Log your daily meals here. Choose a meal slot (Breakfast, Lunch, etc.) '
                  'then search, voice-add, scan with camera, or create food manually.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'food_workout',
        keyTarget: CoachMarkKeys.foodWorkout,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Workout',
              body:
                  'Log exercises with intensity and duration. '
                  'Estimated calories burned appear in your stats and net calorie calculation.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'food_sleep',
        keyTarget: CoachMarkKeys.foodSleep,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Sleep',
              body:
                  'Record your bedtime, wake time, and sleep quality. '
                  'Your sleep hours appear on the Home tab stats.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'food_recipes',
        keyTarget: CoachMarkKeys.foodRecipes,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Recipes',
              body:
                  'Browse healthy recipe ideas organized by category. '
                  'Search by name or calories, and filter by veg, low cal, or high protein.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'food_weight_plan',
        keyTarget: CoachMarkKeys.foodWeightPlan,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Weight Plan',
              body:
                  'View your BMI, daily calorie target, and macro goals. '
                  'Edit your profile to recalculate or export a PDF diet chart.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'food_tips',
        keyTarget: CoachMarkKeys.foodTips,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Tips',
              body:
                  'Read science-backed health and weight advice. '
                  'Practical tips for nutrition, exercise, and healthy habits.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'food_info',
        keyTarget: CoachMarkKeys.foodFoodInfo,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Food Info',
              body:
                  'Explore nutrition data for any food. '
                  'Search by name, nutrient, or calorie count to see full details including micronutrients.',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> waterCoachTargets() => [
      TargetFocus(
        identify: 'water_bottle',
        keyTarget: CoachMarkKeys.waterBottle,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: CustomTargetContentPosition(bottom: 80),
            child: const CoachText(
              title: 'Step 1: Your Water Bottle',
              body:
                  'This animated bottle shows your daily water intake.\n\n'
                  '\u2022 The water level rises as you log drinks\n'
                  '\u2022 Tilt your phone to see the water move!\n'
                  '\u2022 The color changes: red = no water, amber = in progress, green = goal reached\n'
                  '\u2022 Your daily goal is calculated from your weight (weight x 33 ml)\n\n'
                  'First time? You\'ll be asked to enter your height and weight to calculate your goal.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'water_add',
        keyTarget: CoachMarkKeys.waterAddBtn,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 2: Log Your Water',
              body:
                  'Here\'s how to track water:\n\n'
                  '1. Tap the "Add" button\n'
                  '2. Pick an amount from the popup (100ml, 250ml, 500ml, etc.)\n'
                  '3. Watch the pouring animation fill your bottle!\n\n'
                  'Logged too much? Tap "Remove" to subtract water.\n'
                  'Want to start over? Tap "Reset Today" below.\n\n'
                  'Tip: A standard glass is about 250 ml. Try to drink 8 glasses a day!',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> exercisesCoachTargets() => [
      TargetFocus(
        identify: 'exercise_categories',
        keyTarget: CoachMarkKeys.exerciseCategories,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'How to Use Exercises',
              body:
                  'Here\'s how to find and follow a workout:\n\n'
                  '1. Tap a body focus category above (Abs, Chest, Legs, Arms, Back, etc.)\n'
                  '2. Browse the workout programs that appear below\n'
                  '3. Tap a program to see its exercises with descriptions\n'
                  '4. Follow the exercises step by step during your workout\n\n'
                  'Each program shows the target muscle group, difficulty, and number of exercises.\n\n'
                  'Tip: Start with Abs or Chest for beginner-friendly routines!',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> weightPlanCoachTargets() => [
      TargetFocus(
        identify: 'weight_plan_setup',
        keyTarget: CoachMarkKeys.weightPlanSetup,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Set Up Your Weight Plan',
              body:
                  'Fill in this form to get your personalized plan:\n\n'
                  '1. Choose your goal: Lose, Gain, or Maintain weight\n'
                  '2. Enter your age, gender, height, and current weight\n'
                  '3. Set a target weight (if losing or gaining)\n'
                  '4. Pick your activity level (sedentary to very active)\n'
                  '5. Choose your weekly goal (0.25 to 1.0 kg/week)\n'
                  '6. Select veg or non-veg diet preference\n'
                  '7. Optionally set gym time, protein scoops, and supplements\n'
                  '8. Tap "Calculate My Plan"\n\n'
                  'You\'ll get: daily calorie target, protein/carbs/fat targets, BMI score, and you can export a PDF diet chart!',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> medicineCoachTargets() => [
      TargetFocus(
        identify: 'medicine_fab',
        keyTarget: CoachMarkKeys.medicineFab,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'How to Schedule Medicine',
              body:
                  'Tap this button to add your first medicine.\n\n'
                  'On the next screen:\n'
                  '1. Enter the medicine name (e.g. "Vitamin D3")\n'
                  '2. Choose the type (tablet, capsule, syrup, etc.)\n'
                  '3. Enter the dose strength (e.g. "500mg")\n'
                  '4. Set how often to take it (daily, twice a day, etc.)\n'
                  '5. Enable the scheduler to get reminders at specific times\n'
                  '6. Tap Save\n\n'
                  'You\'ll get notifications at the scheduled times so you never miss a dose!\n\n'
                  'Tip: Add supplements like whey protein and creatine here too.',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Gym Home stats grid (inside gym home screen).
List<TargetFocus> gymHomeStatsCoachTargets() => [
      TargetFocus(
        identify: 'gym_stat_present',
        keyTarget: CoachMarkKeys.gymStatPresent,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Present',
              body:
                  'Total days you marked gym attendance since your plan started. '
                  'Go to the Attendance tab to mark yourself present each day.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_stat_absent',
        keyTarget: CoachMarkKeys.gymStatAbsent,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Absent',
              body:
                  'Days missed since your plan started. '
                  'This counts automatically based on the days you did not mark present.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_stat_water',
        keyTarget: CoachMarkKeys.gymStatWater,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Water',
              body:
                  'Glasses of water (250ml each) you drank today. '
                  'Go to the Water tab to log your intake and see the animated bottle.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_stat_steps',
        keyTarget: CoachMarkKeys.gymStatSteps,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Steps',
              body:
                  'Live step count from your phone sensor. '
                  'Updates automatically throughout the day. '
                  'Your step goal is personalized based on your BMI.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_stat_food_cal',
        keyTarget: CoachMarkKeys.gymStatFoodCal,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Food Cal',
              body:
                  'Total calories eaten from tracked meals today. '
                  'Go to the Food tab to log your meals and track macros.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_stat_sleep',
        keyTarget: CoachMarkKeys.gymStatSleep,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Sleep',
              body:
                  'Hours of sleep logged today. '
                  'Log your bedtime and wake time in the Food tab to track sleep quality.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_stat_step_kcal',
        keyTarget: CoachMarkKeys.gymStatStepKcal,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step kcal',
              body:
                  'Calories burnt from walking, calculated from your step count and body weight. '
                  'Updates in real-time as you walk.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_stat_workout_kcal',
        keyTarget: CoachMarkKeys.gymStatWorkoutKcal,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Workout kcal',
              body:
                  'Calories burnt from logged workouts today. '
                  'Log exercises in the Food tab with intensity and duration.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'gym_stat_total_burnt',
        keyTarget: CoachMarkKeys.gymStatTotalBurnt,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Total Burnt',
              body:
                  'Step kcal + Workout kcal combined. '
                  'This total is subtracted from your food calories to get your net intake.',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Attendance screen (inside gym tabs).
List<TargetFocus> attendanceCoachTargets() => [
      TargetFocus(
        identify: 'attendance_calendar',
        keyTarget: CoachMarkKeys.attendanceCalendar,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Select a Day',
              body:
                  'This calendar shows your gym attendance history.\n\n'
                  '\u2022 Green dots = days you were present\n'
                  '\u2022 Tap any day to select it\n'
                  '\u2022 Swipe left/right to change months\n\n'
                  'Select today\'s date to mark yourself present.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'attendance_mark',
        keyTarget: CoachMarkKeys.attendanceMarkBtn,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 2: Mark Present',
              body:
                  'After selecting a day, tap this button to mark yourself present.\n\n'
                  '\u2022 The button turns green and shows "Already Marked" once done\n'
                  '\u2022 You need an active gym subscription to mark attendance\n'
                  '\u2022 Your Present/Absent counts update on the Home tab\n\n'
                  'Tip: Mark yourself present every day you go to the gym to track consistency!',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Log Workout screen (inner screen).
List<TargetFocus> logWorkoutCoachTargets() => [
      TargetFocus(
        identify: 'workout_search',
        keyTarget: CoachMarkKeys.workoutSearch,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Find & Log Your Workout',
              body:
                  'Type here to search for a workout type.\n\n'
                  'Available workouts include: Walking, Running, Cycling, '
                  'Swimming, Yoga, Weight Training, Treadmill, Jump Rope, '
                  'HIIT, and many more.\n\n'
                  'Tap any workout card below to open the logging form:\n'
                  '1. Choose intensity — Light, Moderate, or Intense\n'
                  '2. Enter duration in minutes (e.g. 30)\n'
                  '3. Optionally add distance in km\n'
                  '4. See the estimated calories you\'ll burn\n'
                  '5. Tap "Log Workout" to save\n\n'
                  'Your workout calories appear in the Home stats and Food tracker!',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Log Sleep screen (inner screen).
List<TargetFocus> logSleepCoachTargets() => [
      TargetFocus(
        identify: 'sleep_times',
        keyTarget: CoachMarkKeys.sleepTimePickers,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Set Bedtime & Wake Time',
              body:
                  'Tap each card to set your sleep and wake times:\n\n'
                  '\u2022 Bedtime (moon icon) — when you went to sleep last night\n'
                  '\u2022 Wake time (sun icon) — when you woke up this morning\n\n'
                  'The sleep duration calculates automatically. '
                  'Defaults are 11 PM to 7 AM (8 hours).\n\n'
                  'You can log multiple sleep segments (e.g. naps) in a single day.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'sleep_quality',
        keyTarget: CoachMarkKeys.sleepQuality,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 2: Rate Your Sleep (Optional)',
              body:
                  'Tap a chip to rate how well you slept:\n\n'
                  '\u2022 Excellent — deep, restful sleep\n'
                  '\u2022 Good — slept well overall\n'
                  '\u2022 Fair — okay but could be better\n'
                  '\u2022 Poor — restless or frequently woken\n\n'
                  'This is optional — you can skip it and just log the hours.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'sleep_save',
        keyTarget: CoachMarkKeys.sleepSaveBtn,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 3: Save Your Sleep',
              body:
                  'Tap "Log Sleep" to save your entry.\n\n'
                  'Your sleep hours will appear on:\n'
                  '\u2022 The Home tab "Sleep" stat card\n'
                  '\u2022 Today\'s Sleep summary at the top of this screen\n\n'
                  'To delete a sleep entry, expand the summary card and swipe left.',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Food Search screen (inner screen).
List<TargetFocus> foodSearchCoachTargets() => [
      TargetFocus(
        identify: 'food_search_bar',
        keyTarget: CoachMarkKeys.foodSearchBar,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'How to Find & Add Food',
              body:
                  'Type a food name to search (e.g. "rice", "paneer tikka").\n\n'
                  'The app searches 4 sources automatically:\n'
                  '1. Local database — 500+ common Indian & international foods\n'
                  '2. Cloud database — community-added foods\n'
                  '3. USDA — tap "Search online" for US nutrition database\n'
                  '4. AI — tap "Search with AI" as a last resort\n\n'
                  '\u2022 Tap the mic icon \U0001F3A4 for voice search — say a food name!\n'
                  '\u2022 When search is empty, browse foods by category\n\n'
                  'After finding a food:\n'
                  '1. Tap it or tap the + icon\n'
                  '2. Pick Quantity (0.25 to 10) and Measure (Serving, Katori, Cup, Grams, etc.)\n'
                  '3. See the Protein, Carbs, Fat, and total kcal preview\n'
                  '4. Tap "Add" to log it to your meal',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Create Food screen (inner screen).
List<TargetFocus> createFoodCoachTargets() => [
      TargetFocus(
        identify: 'create_food_form',
        keyTarget: CoachMarkKeys.createFoodForm,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Add a Custom Food',
              body:
                  'Can\'t find your food? Create it manually:\n\n'
                  '1. Enter the food name (e.g. "Max Protein Bar")\n'
                  '2. Set the serving size (e.g. "1 bar (60g)" or "100g")\n'
                  '3. Pick a category (Grains, Protein, Snacks, etc.)\n'
                  '4. Enter Calories, Protein, Carbs, and Fat\n'
                  '5. Optionally add Fiber, Sugar, Sodium, Cholesterol\n'
                  '6. Tap "Save Food"\n\n'
                  'Your food is saved locally AND backed up to the cloud, '
                  'so it\'ll appear in search results next time!',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Food Explorer screen (inner screen).
List<TargetFocus> foodExplorerCoachTargets() => [
      TargetFocus(
        identify: 'food_explorer_search',
        keyTarget: CoachMarkKeys.foodExplorerSearch,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Explore Food Nutrition',
              body:
                  'Search in 3 powerful ways:\n\n'
                  '1. By food name — type "chicken" to see full nutrition details '
                  'with expandable micronutrients (vitamins, minerals)\n\n'
                  '2. By nutrient — type "iron", "vitamin d", or "protein" to see '
                  'a ranked list of foods highest in that nutrient\n\n'
                  '3. By calories — type "200 kcal" or "200" to find foods '
                  'around that calorie count\n\n'
                  'Tap any food card to expand and see all micronutrients '
                  '(Vitamin A, B12, C, D, Iron, Calcium, Zinc, etc.).',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Meal Reminder screen (inner screen).
List<TargetFocus> mealReminderCoachTargets() => [
      TargetFocus(
        identify: 'meal_reminder_master',
        keyTarget: CoachMarkKeys.mealReminderMaster,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Set Up Meal Reminders',
              body:
                  'Here\'s how to configure meal reminders:\n\n'
                  '1. Turn ON "Enable Reminders" (this master switch)\n'
                  '2. Optionally check "Remind me once at" and set a time '
                  '— you\'ll get one daily "track your meals" reminder\n'
                  '3. Toggle individual meals below:\n'
                  '   \u2022 Breakfast (default 9:00 AM)\n'
                  '   \u2022 Morning Snack (11:00 AM)\n'
                  '   \u2022 Lunch (1:00 PM)\n'
                  '   \u2022 Evening Snack (5:00 PM)\n'
                  '   \u2022 Dinner (8:00 PM)\n'
                  '4. Tap the time next to each meal to change it\n\n'
                  'You\'ll get a push notification at each enabled meal time!',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Water Reminder screen (inner screen).
List<TargetFocus> waterReminderCoachTargets() => [
      TargetFocus(
        identify: 'water_reminder_master',
        keyTarget: CoachMarkKeys.waterReminderMaster,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Set Up Water Reminders',
              body:
                  'Stay hydrated with periodic reminders:\n\n'
                  '1. Turn ON "Enable Reminders"\n'
                  '2. Optionally set a single daily "drink water" reminder\n'
                  '3. Set your active hours (e.g. 9:30 AM to 9:30 PM)\n'
                  '4. Choose how to space reminders:\n'
                  '   \u2022 "Remind me X Times" — evenly spaced (e.g. 6 times)\n'
                  '   \u2022 "Remind me every X Min" — fixed interval (e.g. every 30 min)\n\n'
                  'Tip: 6-8 reminders per day helps you reach your water goal!',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Weight Plan Dashboard (inner screen, after setup).
List<TargetFocus> weightDashboardCoachTargets() => [
      TargetFocus(
        identify: 'weight_dashboard_bmi',
        keyTarget: CoachMarkKeys.weightDashboardBmi,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Your BMI Score',
              body:
                  'This gauge shows your Body Mass Index (BMI).\n\n'
                  '\u2022 Underweight — below 18.5\n'
                  '\u2022 Normal — 18.5 to 24.9 (green zone)\n'
                  '\u2022 Overweight — 25 to 29.9\n'
                  '\u2022 Obese — 30 and above\n\n'
                  'Your personalized step goal and calorie target are '
                  'adjusted based on your BMI category.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'weight_dashboard_calories',
        keyTarget: CoachMarkKeys.weightDashboardCalories,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 2: Daily Calorie Target',
              body:
                  'This is your personalized daily calorie target.\n\n'
                  'It\'s calculated using the Mifflin-St Jeor equation based '
                  'on your age, gender, height, weight, activity level, and '
                  'weekly goal.\n\n'
                  '\u2022 The progress bar fills as you log food\n'
                  '\u2022 Stay at or below this number to reach your goal\n'
                  '\u2022 Tap "Edit" in Profile Summary to recalculate anytime',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'weight_dashboard_macros',
        keyTarget: CoachMarkKeys.weightDashboardMacros,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 3: Macro Targets',
              body:
                  'These are your daily Protein, Carbs, and Fat targets in grams.\n\n'
                  '\u2022 Protein (blue) — builds and repairs muscle\n'
                  '\u2022 Carbs (orange) — your main energy source\n'
                  '\u2022 Fat (red) — essential for hormones and vitamins\n\n'
                  'As you log food, the "eaten" count updates in real-time. '
                  'Try to hit your protein target every day for best results!',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'weight_dashboard_export',
        keyTarget: CoachMarkKeys.weightDashboardExport,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 4: Export Your Diet Chart',
              body:
                  'Tap here to generate a personalized diet chart as a PDF!\n\n'
                  'The chart includes:\n'
                  '\u2022 Your daily calorie and macro targets\n'
                  '\u2022 Meal-by-meal food suggestions (veg or non-veg)\n'
                  '\u2022 Water intake goal\n'
                  '\u2022 Step count goal\n'
                  '\u2022 Supplement schedule (if configured)\n\n'
                  'Share the PDF with your nutritionist or gym trainer!',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the Recipes screen (inner screen).
List<TargetFocus> recipesCoachTargets() => [
      TargetFocus(
        identify: 'recipes_search',
        keyTarget: CoachMarkKeys.recipesSearch,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Search Recipes',
              body:
                  'Find healthy recipes in two ways:\n\n'
                  '\u2022 By name — type a dish name like "oats" or "chicken salad"\n'
                  '\u2022 By calories — type "200 kcal" to find recipes around that calorie count\n\n'
                  'Results come from a built-in recipe database organised by category '
                  '(Breakfast, Lunch, Dinner, Snacks, Smoothies, and Salads).\n\n'
                  'Tap any recipe card to see full ingredients, steps, and nutrition info!',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'recipes_filters',
        keyTarget: CoachMarkKeys.recipesFilters,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 2: Filter & Sort',
              body:
                  'Use these chips to refine your results:\n\n'
                  '\u2022 Veg Only — show only vegetarian recipes\n'
                  '\u2022 Low Cal — sort by fewest calories first\n'
                  '\u2022 High Protein — sort by most protein first\n'
                  '\u2022 Quick — sort by shortest prep time\n\n'
                  'Combine with the category tabs at the top to narrow down '
                  'to exactly what you need!',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> remindersCoachTargets() => [
      TargetFocus(
        identify: 'reminders_list',
        keyTarget: CoachMarkKeys.remindersListView,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Set Up Your Reminders',
              body:
                  'Tap any reminder type to configure it:\n\n'
                  '\u2022 Food — get reminded to eat meals at set times (breakfast, lunch, dinner, snacks)\n'
                  '\u2022 Water — periodic reminders to drink water throughout the day\n'
                  '\u2022 Workout — schedule your exercise sessions\n'
                  '\u2022 Walk — reminders to take walking breaks\n'
                  '\u2022 Weight — weekly reminders to weigh yourself\n'
                  '\u2022 Health Log — reminders to log health metrics\n'
                  '\u2022 Medicine — manage medicine dose schedules\n\n'
                  'Each reminder lets you set custom times and toggle individual notifications on/off.',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the inner Track Food screen (_TrackFoodPage).
List<TargetFocus> trackFoodInnerCoachTargets() => [
      TargetFocus(
        identify: 'track_food_cal',
        keyTarget: CoachMarkKeys.trackFoodCalCard,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Your Calorie & Macro Tracker',
              body:
                  'This card is your daily food dashboard:\n\n'
                  '\u2022 The circle fills as you log food — green is on track, red is over target\n'
                  '\u2022 Below are your Protein, Carbs, and Fat progress bars\n'
                  '\u2022 Expand "Micronutrients" and "Vitamins" to see Iron, Calcium, Vitamin D, and more\n\n'
                  'Scroll down to see your meal slots (Breakfast, Lunch, Dinner, etc.). '
                  'Tap the + button on any meal to search and add food items.',
            ),
          ),
        ],
      ),
    ];

/// Coach marks for the inner Recipes screen (_RecipesTab from Food grid).
List<TargetFocus> innerRecipesCoachTargets() => [
      TargetFocus(
        identify: 'inner_recipes_search',
        keyTarget: CoachMarkKeys.innerRecipesSearch,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Search Recipes',
              body:
                  'Find healthy recipes in two ways:\n\n'
                  '\u2022 By name — type a dish name like "oats" or "chicken salad"\n'
                  '\u2022 By calories — type "200 kcal" to find recipes around that calorie count\n\n'
                  'Results are organised by category (Breakfast, Lunch, Dinner, Snacks, etc.).\n\n'
                  'Tap any recipe card to see full ingredients, steps, and nutrition info!',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'inner_recipes_filters',
        keyTarget: CoachMarkKeys.innerRecipesFilters,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 2: Filter & Sort',
              body:
                  'Use these chips to refine your results:\n\n'
                  '\u2022 Veg Only — show only vegetarian recipes\n'
                  '\u2022 Low Cal — sort by fewest calories first\n'
                  '\u2022 High Protein — sort by most protein first\n'
                  '\u2022 Quick — sort by shortest prep time\n\n'
                  'Combine with the category tabs at the top to narrow down '
                  'to exactly what you need!',
            ),
          ),
        ],
      ),
    ];
