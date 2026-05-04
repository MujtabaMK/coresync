import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'coach_mark_keys.dart';
import 'coach_text_widget.dart';

/// Coach marks for the Add/Edit Task screen (inner screen).
List<TargetFocus> addTaskCoachTargets() => [
      TargetFocus(
        identify: 'add_task_title',
        keyTarget: CoachMarkKeys.addTaskTitle,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Enter a Title',
              body:
                  'Type your task title here (e.g. "Buy groceries").\n\n'
                  'Pro tip: Tap "Add another title" below to create multiple '
                  'tasks at once — each title becomes a separate task with the '
                  'same due date, description, and settings.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'add_task_date',
        keyTarget: CoachMarkKeys.addTaskDate,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 2: Pick a Due Date',
              body:
                  'Tap this field to open the date picker.\n\n'
                  'Select the day your task is due. This date is used for '
                  'sorting, filtering, and sending you a reminder notification.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'add_task_reminder',
        keyTarget: CoachMarkKeys.addTaskReminder,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 3: Set a Reminder Time',
              body:
                  'Tap to choose the time you want to be notified.\n\n'
                  'You\'ll receive a push notification at this time on the '
                  'due date so you don\'t forget your task.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'add_task_status',
        keyTarget: CoachMarkKeys.addTaskStatus,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 4: Set the Status',
              body:
                  'Choose your task\'s current status:\n\n'
                  '\u2022 Not Started — default for new tasks\n'
                  '\u2022 Working — you\'ve begun working on it\n'
                  '\u2022 Completed — mark it done!\n\n'
                  'You can change the status later from the task detail screen.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'add_task_save',
        keyTarget: CoachMarkKeys.addTaskSave,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 5: Save Your Task',
              body:
                  'Tap this button to create your task.\n\n'
                  'A reminder notification will be scheduled automatically. '
                  'Your task will appear in the list and can be filtered, '
                  'shared, or edited anytime.',
            ),
          ),
        ],
      ),
    ];

List<TargetFocus> todoCoachTargets() => [
      TargetFocus(
        identify: 'todo_fab',
        keyTarget: CoachMarkKeys.todoFab,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const CoachText(
              title: 'Step 1: Create a Task',
              body:
                  'Tap this + button to create your first task.\n\n'
                  'On the next screen:\n'
                  '1. Type a task title (e.g. "Buy groceries")\n'
                  '2. Add a description if needed\n'
                  '3. Pick a due date by tapping the calendar icon\n'
                  '4. Set a reminder time to get notified\n'
                  '5. Tap Save to create the task\n\n'
                  'Tip: You can add multiple titles at once to create several tasks in one go!',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'todo_filter',
        keyTarget: CoachMarkKeys.todoFilter,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 2: Filter Your Tasks',
              body:
                  'Tap these chips to filter tasks by status:\n\n'
                  '\u2022 All — show every task\n'
                  '\u2022 Not Started — tasks you haven\'t begun\n'
                  '\u2022 Working — tasks in progress\n'
                  '\u2022 Completed — finished tasks\n\n'
                  'This helps you focus on what needs attention right now.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'todo_shared',
        keyTarget: CoachMarkKeys.todoShared,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 3: Share Tasks with Friends',
              body:
                  'Tap this icon to view tasks shared with you.\n\n'
                  'To share YOUR tasks with someone:\n'
                  '1. Long-press any task to enter selection mode\n'
                  '2. Select one or more tasks\n'
                  '3. Tap the share icon in the top bar\n'
                  '4. Enter the person\'s phone number or pick from contacts\n'
                  '5. Tap Share — they\'ll get a notification!\n\n'
                  'Shared users can view the task and update its status.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'todo_reports',
        keyTarget: CoachMarkKeys.todoReports,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 4: Track Your Productivity',
              body:
                  'Tap here to see your task reports.\n\n'
                  'You\'ll see:\n'
                  '\u2022 Total tasks created\n'
                  '\u2022 How many you completed vs pending\n'
                  '\u2022 A visual breakdown chart\n'
                  '\u2022 Filter by time period (week, month, all time)\n\n'
                  'Use this to track your productivity over time!',
            ),
          ),
        ],
      ),
    ];
