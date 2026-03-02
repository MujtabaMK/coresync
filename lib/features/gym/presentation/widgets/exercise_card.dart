import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/exercise_model.dart';

class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;

  const ExerciseCard({super.key, required this.exercise});

  Future<void> _launchUrl(BuildContext context) async {
    final uri = Uri.parse(exercise.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.fitness_center,
          color: theme.colorScheme.primary,
        ),
        title: Text(exercise.name),
        subtitle: Text(exercise.category),
        trailing: IconButton(
          icon: Icon(
            Icons.play_circle_fill,
            color: Colors.red.shade600,
            size: 32,
          ),
          onPressed: () => _launchUrl(context),
        ),
        onTap: () => _launchUrl(context),
      ),
    );
  }
}
