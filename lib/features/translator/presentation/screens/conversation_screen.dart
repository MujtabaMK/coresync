import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/translator_provider.dart';
import '../widgets/language_picker_widget.dart';
import '../widgets/transcript_bubble.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Enable conversation mode
    final cubit = context.read<TranslatorCubit>();
    if (!cubit.state.isConversationMode) {
      cubit.toggleConversationMode();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<TranslatorCubit, TranslatorState>(
      listener: (context, state) {
        if (state.conversationHistory.isNotEmpty) {
          _scrollToBottom();
        }
        if (state.status == TranslatorStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage)),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<TranslatorCubit>();

        // Determine current speaker
        final isSpeakerATurn = state.conversationHistory.isEmpty ||
            !state.conversationHistory.last.isFromSpeakerA;
        final currentSpeakerLang =
            isSpeakerATurn ? state.sourceLanguage : state.targetLanguage;

        return Column(
          children: [
            // Language selectors
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Speaker A', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        LanguagePickerWidget(
                          selectedLanguage: state.sourceLanguage,
                          onChanged: cubit.setSourceLanguage,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: IconButton(
                      onPressed: cubit.swapLanguages,
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Swap languages',
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Speaker B', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        LanguagePickerWidget(
                          selectedLanguage: state.targetLanguage,
                          onChanged: cubit.setTargetLanguage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Conversation history
            Expanded(
              child: state.conversationHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the microphone to begin',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.conversationHistory.length,
                      itemBuilder: (context, index) {
                        final entry = state.conversationHistory[index];
                        final targetCode =
                            TranslatorCubit.languages[entry.targetLang] ?? 'en';

                        return TranscriptBubble(
                          entry: entry,
                          onReplay: () =>
                              cubit.replayTts(entry.translatedText, targetCode),
                        );
                      },
                    ),
            ),

            // Status + mic area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Status indicator
                  if (state.status != TranslatorStatus.idle)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        switch (state.status) {
                          TranslatorStatus.listening => 'Listening...',
                          TranslatorStatus.translating => 'Translating...',
                          TranslatorStatus.speaking => 'Speaking...',
                          _ => '',
                        },
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: state.status == TranslatorStatus.listening
                              ? Colors.red
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),

                  // Recognized text preview
                  if (state.recognizedText.isNotEmpty &&
                      state.status == TranslatorStatus.listening)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        state.recognizedText,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.conversationHistory.isNotEmpty)
                        IconButton(
                          onPressed: cubit.clearConversation,
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Clear conversation',
                        ),
                      const SizedBox(width: 16),
                      FloatingActionButton(
                        heroTag: 'conversation_mic',
                        onPressed: () {
                          if (state.status == TranslatorStatus.listening) {
                            cubit.stopListening();
                          } else {
                            cubit.startListening();
                          }
                        },
                        backgroundColor:
                            state.status == TranslatorStatus.listening
                                ? Colors.red
                                : theme.colorScheme.primary,
                        child: Icon(
                          state.status == TranslatorStatus.listening
                              ? Icons.stop
                              : Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Speak in\n$currentSpeakerLang',
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
