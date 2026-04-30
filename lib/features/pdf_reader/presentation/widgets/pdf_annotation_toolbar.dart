import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../scanner/domain/annotation_model.dart';
import '../providers/pdf_viewer_provider.dart';

class PdfAnnotationToolbar extends StatelessWidget {
  const PdfAnnotationToolbar({super.key});

  static const _colors = [
    Color(0xFFFF0000),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF000000),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PdfViewerCubit, PdfViewerState>(
      builder: (context, state) {
        if (!state.isAnnotating) return const SizedBox.shrink();

        final cubit = context.read<PdfViewerCubit>();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              _toolButton(
                context,
                icon: Icons.edit,
                label: 'Pen',
                isSelected: state.annotationTool == AnnotationTool.pen,
                onTap: () => cubit.setAnnotationTool(AnnotationTool.pen),
              ),
              _toolButton(
                context,
                icon: Icons.title,
                label: 'Text',
                isSelected: state.annotationTool == AnnotationTool.text,
                onTap: () => cubit.setAnnotationTool(AnnotationTool.text),
              ),
              _toolButton(
                context,
                icon: Icons.crop_square,
                label: 'Rect',
                isSelected: state.annotationTool == AnnotationTool.rectangle,
                onTap: () => cubit.setAnnotationTool(AnnotationTool.rectangle),
              ),
              const SizedBox(width: 8),
              // Color picker
              ...List.generate(_colors.length, (i) {
                final color = _colors[i];
                final isSelected = state.annotationColor == color;
                return GestureDetector(
                  onTap: () => cubit.setAnnotationColor(color),
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                  ),
                );
              }),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                onPressed: () => cubit.undoAnnotation(state.currentPage - 1),
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => cubit.toggleAnnotationMode(),
                tooltip: 'Close',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
