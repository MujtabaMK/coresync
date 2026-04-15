import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/calculator_provider.dart';
import '../widgets/calculator_button.dart';
import '../widgets/calculator_display.dart';

class SimpleCalculatorScreen extends StatelessWidget {
  const SimpleCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<CalculatorCubit>();

    return BlocBuilder<CalculatorCubit, CalculatorState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              flex: 2,
              child: CalculatorDisplay(
                expression: state.expression,
                result: state.result,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    _row(theme, cubit, ['C', '⌫', '%', '÷']),
                    _row(theme, cubit, ['7', '8', '9', '×']),
                    _row(theme, cubit, ['4', '5', '6', '-']),
                    _row(theme, cubit, ['1', '2', '3', '+']),
                    _row(theme, cubit, ['00', '0', '.', '=']),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(ThemeData theme, CalculatorCubit cubit, List<String> labels) {
    return Expanded(
      child: Row(
        children: labels.map((l) {
          Color? bg;
          Color? fg;

          if (l == '=' ) {
            bg = theme.colorScheme.primary;
            fg = theme.colorScheme.onPrimary;
          } else if (['÷', '×', '-', '+', '%'].contains(l)) {
            bg = theme.colorScheme.primaryContainer;
            fg = theme.colorScheme.onPrimaryContainer;
          } else if (l == 'C' || l == '⌫') {
            bg = theme.colorScheme.errorContainer;
            fg = theme.colorScheme.onErrorContainer;
          }

          return CalculatorButton(
            label: l,
            backgroundColor: bg,
            foregroundColor: fg,
            onTap: () => _handleTap(cubit, l),
          );
        }).toList(),
      ),
    );
  }

  void _handleTap(CalculatorCubit cubit, String label) {
    switch (label) {
      case 'C':
        cubit.clear();
      case '⌫':
        cubit.backspace();
      case '=':
        cubit.evaluate();
      default:
        cubit.input(label);
    }
  }
}
