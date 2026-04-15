import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart';

class CalculatorEngine {
  static final _parser = Parser();
  static final _contextModel = ContextModel()
    ..bindVariable(Variable('pi'), Number(math.pi))
    ..bindVariable(Variable('e'), Number(math.e));

  /// Evaluates a math expression string and returns the result as a string.
  /// Supports: +, -, *, /, ^, sqrt(), sin(), cos(), tan(), log(), ln(), (, )
  static String evaluate(String expression) {
    try {
      // Normalise user-friendly tokens into parser-compatible form
      var expr = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll('√(', 'sqrt(')
          .replaceAll('ln(', 'ln(');

      final parsed = _parser.parse(expr);
      final result = parsed.evaluate(EvaluationType.REAL, _contextModel);

      if (result is double) {
        if (result.isInfinite || result.isNaN) return 'Error';
        // Show integer when result is whole
        if (result == result.truncateToDouble()) {
          return result.toInt().toString();
        }
        // Cap decimal places at 10
        return result.toStringAsFixed(10)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }
      return result.toString();
    } catch (_) {
      return 'Error';
    }
  }
}
