import 'package:flutter/material.dart';

import '../../data/exercise_data.dart';
import '../../domain/exercise_model.dart';
import '../widgets/exercise_card.dart';

class ExerciseCategoryScreen extends StatefulWidget {
  final String category;

  const ExerciseCategoryScreen({super.key, required this.category});

  @override
  State<ExerciseCategoryScreen> createState() => _ExerciseCategoryScreenState();
}

class _ExerciseCategoryScreenState extends State<ExerciseCategoryScreen> {
  ExerciseDifficulty? _selectedDifficulty;

  List<ExerciseModel> get _filteredExercises {
    if (_selectedDifficulty == null) {
      return ExerciseData.getByCategory(widget.category);
    }
    return ExerciseData.getByCategoryAndDifficulty(
      widget.category,
      _selectedDifficulty!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _filteredExercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(null, 'All'),
                const SizedBox(width: 8),
                _buildFilterChip(ExerciseDifficulty.beginner, 'Beginner'),
                const SizedBox(width: 8),
                _buildFilterChip(
                    ExerciseDifficulty.intermediate, 'Intermediate'),
                const SizedBox(width: 8),
                _buildFilterChip(ExerciseDifficulty.advanced, 'Advanced'),
              ],
            ),
          ),
          Expanded(
            child: exercises.isEmpty
                ? const Center(child: Text('No exercises found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      return ExerciseCard(exercise: exercises[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ExerciseDifficulty? difficulty, String label) {
    final isSelected = _selectedDifficulty == difficulty;

    Color? chipColor;
    if (difficulty != null) {
      chipColor = switch (difficulty) {
        ExerciseDifficulty.beginner => Colors.green,
        ExerciseDifficulty.intermediate => Colors.orange,
        ExerciseDifficulty.advanced => Colors.red,
      };
    }

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: chipColor?.withAlpha(40),
      checkmarkColor: chipColor,
      side: isSelected && chipColor != null
          ? BorderSide(color: chipColor)
          : null,
      onSelected: (_) {
        setState(() {
          _selectedDifficulty = difficulty;
        });
      },
    );
  }
}
