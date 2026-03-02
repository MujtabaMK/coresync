import 'package:flutter/material.dart';

import '../../data/exercise_data.dart';
import '../widgets/exercise_card.dart';

class ExerciseCategoryScreen extends StatelessWidget {
  final String category;

  const ExerciseCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final exercises = ExerciseData.getByCategory(category);

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: exercises.isEmpty
          ? const Center(child: Text('No exercises found'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                return ExerciseCard(exercise: exercises[index]);
              },
            ),
    );
  }
}
