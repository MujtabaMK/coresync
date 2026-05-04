import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/yoga_api_service.dart';
import '../../domain/workout_program_model.dart';
import 'workout_program_card.dart';

class YogaTab extends StatefulWidget {
  const YogaTab({super.key});

  @override
  State<YogaTab> createState() => _YogaTabState();
}

class _YogaTabState extends State<YogaTab>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  bool _error = false;
  List<WorkoutProgram> _programs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPoses();
  }

  Future<void> _loadPoses() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    final poses = await YogaApiService.instance.fetchPoses();

    if (!mounted) return;
    setState(() {
      _programs = YogaApiService.instance.programs;
      _loading = false;
      _error = poses.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Could not load yoga poses',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _loadPoses,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _programs.isEmpty
        ? const Center(child: Text('No yoga programs available'))
        : ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 16),
            itemCount: _programs.length,
            itemBuilder: (context, index) {
              final program = _programs[index];
              return WorkoutProgramCard(
                program: program,
                onTap: () => context.push(
                  '/gym/exercises/workout/${program.id}',
                ),
              );
            },
          );
  }
}
