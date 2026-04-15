import 'package:flutter/material.dart';

import '../../domain/conversation_entry.dart';

class TranscriptBubble extends StatelessWidget {
  const TranscriptBubble({
    super.key,
    required this.entry,
    required this.onReplay,
  });

  final ConversationEntry entry;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isA = entry.isFromSpeakerA;
    final alignment = isA ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final color = isA
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.tertiaryContainer;
    final textColor = isA
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            isA ? 'Speaker A' : 'Speaker B',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isA ? 4 : 16),
                bottomRight: Radius.circular(isA ? 16 : 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.originalText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.translatedText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry.sourceLang} → ${entry.targetLang}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onReplay,
                      borderRadius: BorderRadius.circular(12),
                      child: Icon(
                        Icons.volume_up,
                        size: 18,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
