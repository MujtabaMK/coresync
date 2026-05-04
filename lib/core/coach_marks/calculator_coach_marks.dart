import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'coach_mark_keys.dart';
import 'coach_text_widget.dart';

List<TargetFocus> calculatorCoachTargets() => [
      TargetFocus(
        identify: 'calc_simple',
        keyTarget: CoachMarkKeys.calcSimple,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 1: Simple Calculator',
              body:
                  'Tap here for everyday math.\n\n'
                  'How to use:\n'
                  '1. Enter your first number\n'
                  '2. Tap an operator (+, -, x, /)\n'
                  '3. Enter your second number\n'
                  '4. Tap = to see the result\n\n'
                  'Supports chain calculations, decimals, and percentage.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'calc_scientific',
        keyTarget: CoachMarkKeys.calcScientific,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 2: Scientific Calculator',
              body:
                  'Tap here for advanced math functions.\n\n'
                  'Available operations:\n'
                  '\u2022 Trigonometry — sin, cos, tan (and inverses)\n'
                  '\u2022 Logarithms — log, ln\n'
                  '\u2022 Powers — x\u00b2, x\u00b3, x^y, square root\n'
                  '\u2022 Constants — \u03c0, e\n'
                  '\u2022 Factorial, absolute value, and more\n\n'
                  'Great for students and engineers!',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'calc_converter',
        keyTarget: CoachMarkKeys.calcConverter,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const CoachText(
              title: 'Step 3: Unit Converter',
              body:
                  'Tap here to convert between units.\n\n'
                  'How to use:\n'
                  '1. Pick a category (length, weight, temperature, etc.)\n'
                  '2. Select the "from" unit\n'
                  '3. Select the "to" unit\n'
                  '4. Enter a value\n'
                  '5. See the converted result instantly\n\n'
                  'Supports length, weight, temperature, area, volume, speed, time, and data.',
            ),
          ),
        ],
      ),
    ];
