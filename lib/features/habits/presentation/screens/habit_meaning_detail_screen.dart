import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/habit_model.dart';
import '../providers/habit_provider.dart';

class HabitMeaningDetailScreen extends StatefulWidget {
  const HabitMeaningDetailScreen({super.key, required this.habit});
  final HabitModel habit;

  @override
  State<HabitMeaningDetailScreen> createState() =>
      _HabitMeaningDetailScreenState();
}

class _HabitMeaningDetailScreenState extends State<HabitMeaningDetailScreen> {
  static const _questions = [
    'Why would I do that?',
    'How will I feel when I receive it?',
    'How will it contribute to the lives of others? How will it affect my relationships with others?',
    'How will my life change after a long time from doing this regular habit?',
    'Write your own',
  ];

  String? _expandedQuestion;
  String? _editingQuestion;
  final _answerController = TextEditingController();

  HabitModel get _habit {
    final habits = context.read<HabitCubit>().state.habits;
    return habits.firstWhere(
      (h) => h.id == widget.habit.id,
      orElse: () => widget.habit,
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _selectQuestion(String question) {
    setState(() {
      if (_expandedQuestion == question) {
        _expandedQuestion = null;
        _editingQuestion = null;
      } else {
        _expandedQuestion = question;
        _editingQuestion = null;
      }
    });
  }

  void _startEditing(String question) {
    final existing = _habit.meanings[question] ?? '';
    _answerController.text = existing;
    setState(() {
      _editingQuestion = question;
    });
  }

  Future<void> _save() async {
    if (_editingQuestion == null) return;
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    await context
        .read<HabitCubit>()
        .saveMeaning(widget.habit.id, _editingQuestion!, answer);

    if (mounted) {
      setState(() {
        _editingQuestion = null;
        _answerController.clear();
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _editingQuestion = null;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<HabitCubit, HabitState>(
      builder: (context, state) {
        final habit = state.habits.firstWhere(
          (h) => h.id == widget.habit.id,
          orElse: () => widget.habit,
        );

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: theme.colorScheme.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              habit.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // If editing a question
                if (_editingQuestion != null) ...[
                  _EditingCard(
                    question: _editingQuestion!,
                    controller: _answerController,
                    onSave: _save,
                    onCancel: _cancelEditing,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Question list / expandable dropdown
                  _QuestionSelector(
                    expandedQuestion: _expandedQuestion,
                    questions: _questions,
                    meanings: habit.meanings,
                    onSelectQuestion: _selectQuestion,
                    onEditQuestion: _startEditing,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                ],

                // Description text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Here you can add motivation by answering a few questions or writing a note. These entries will help you stay committed to your habit. Feel free to share your thoughts or attach helpful links and materials.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),

                // Show saved meanings
                if (habit.meanings.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Your meanings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...habit.meanings.entries.map(
                    (entry) => _SavedMeaningCard(
                      question: entry.key,
                      answer: entry.value,
                      onEdit: () => _startEditing(entry.key),
                      onDelete: () => context
                          .read<HabitCubit>()
                          .deleteMeaning(habit.id, entry.key),
                      theme: theme,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuestionSelector extends StatelessWidget {
  const _QuestionSelector({
    required this.expandedQuestion,
    required this.questions,
    required this.meanings,
    required this.onSelectQuestion,
    required this.onEditQuestion,
    required this.theme,
  });

  final String? expandedQuestion;
  final List<String> questions;
  final Map<String, String> meanings;
  final ValueChanged<String> onSelectQuestion;
  final ValueChanged<String> onEditQuestion;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Header with current question or "Select a question"
          InkWell(
            onTap: () => onSelectQuestion(expandedQuestion ?? questions.first),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      expandedQuestion ?? 'Why would I do that?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    expandedQuestion != null
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded questions list
          if (expandedQuestion != null) ...[
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            ...questions.map((q) {
              final hasMeaning = meanings.containsKey(q);
              return InkWell(
                onTap: () => onEditQuestion(q),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          q,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: hasMeaning
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                      if (hasMeaning)
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _EditingCard extends StatelessWidget {
  const _EditingCard({
    required this.question,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.theme,
  });

  final String question;
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Your meaning',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onSave,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.link),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onCancel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedMeaningCard extends StatelessWidget {
  const _SavedMeaningCard({
    required this.question,
    required this.answer,
    required this.onEdit,
    required this.onDelete,
    required this.theme,
  });

  final String question;
  final String answer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(answer, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}