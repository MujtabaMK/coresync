import 'package:flutter/material.dart';

import '../../domain/annotation_model.dart';

class FillSignToolbar extends StatelessWidget {
  const FillSignToolbar({
    super.key,
    required this.selectedTool,
    required this.onToolSelected,
    required this.onUndo,
    required this.onSignTap,
    required this.onTextTap,
    this.canUndo = false,
  });

  final AnnotationTool selectedTool;
  final ValueChanged<AnnotationTool> onToolSelected;
  final VoidCallback onUndo;
  final VoidCallback onSignTap;
  final VoidCallback onTextTap;
  final bool canUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _ToolButton(
                icon: Icons.undo,
                label: 'Undo',
                isSelected: false,
                onTap: canUndo ? onUndo : null,
              ),
              const SizedBox(width: 4),
              Container(width: 1, height: 32, color: theme.colorScheme.outlineVariant),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.edit,
                label: 'Pen',
                isSelected: selectedTool == AnnotationTool.pen,
                onTap: () => onToolSelected(AnnotationTool.pen),
              ),
              _ToolButton(
                icon: Icons.text_fields,
                label: 'Text',
                isSelected: selectedTool == AnnotationTool.text,
                onTap: onTextTap,
              ),
              _ToolButton(
                icon: Icons.check,
                label: 'Check',
                isSelected: selectedTool == AnnotationTool.checkmark,
                onTap: () => onToolSelected(AnnotationTool.checkmark),
              ),
              _ToolButton(
                icon: Icons.close,
                label: 'X',
                isSelected: selectedTool == AnnotationTool.cross,
                onTap: () => onToolSelected(AnnotationTool.cross),
              ),
              _ToolButton(
                icon: Icons.circle,
                label: 'Dot',
                isSelected: selectedTool == AnnotationTool.dot,
                onTap: () => onToolSelected(AnnotationTool.dot),
              ),
              _ToolButton(
                icon: Icons.horizontal_rule,
                label: 'Line',
                isSelected: selectedTool == AnnotationTool.line,
                onTap: () => onToolSelected(AnnotationTool.line),
              ),
              _ToolButton(
                icon: Icons.crop_square,
                label: 'Rect',
                isSelected: selectedTool == AnnotationTool.rectangle,
                onTap: () => onToolSelected(AnnotationTool.rectangle),
              ),
              _ToolButton(
                icon: Icons.draw_outlined,
                label: 'Sign',
                isSelected: selectedTool == AnnotationTool.signature,
                onTap: onSignTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = onTap == null
        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
        : isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
