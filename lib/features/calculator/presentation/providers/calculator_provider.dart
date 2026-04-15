import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/calculator_engine.dart';

class CalculatorState extends Equatable {
  const CalculatorState({
    this.expression = '',
    this.result = '',
    this.history = const [],
  });

  final String expression;
  final String result;
  final List<String> history; // "expression = result"

  CalculatorState copyWith({
    String? expression,
    String? result,
    List<String>? history,
  }) {
    return CalculatorState(
      expression: expression ?? this.expression,
      result: result ?? this.result,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [expression, result, history];
}

class CalculatorCubit extends Cubit<CalculatorState> {
  CalculatorCubit() : super(const CalculatorState());

  void input(String value) {
    final newExpr = state.expression + value;
    emit(state.copyWith(expression: newExpr, result: ''));
  }

  void clear() {
    emit(const CalculatorState());
  }

  void backspace() {
    if (state.expression.isEmpty) return;
    final newExpr = state.expression.substring(0, state.expression.length - 1);
    emit(state.copyWith(expression: newExpr, result: ''));
  }

  void evaluate() {
    if (state.expression.isEmpty) return;
    final result = CalculatorEngine.evaluate(state.expression);
    final entry = '${state.expression} = $result';
    emit(state.copyWith(
      result: result,
      history: [entry, ...state.history],
    ));
  }

  void setExpression(String expr) {
    emit(state.copyWith(expression: expr, result: ''));
  }
}
