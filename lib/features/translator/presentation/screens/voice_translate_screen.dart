import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/translator_provider.dart';
import '../widgets/language_picker_widget.dart';

class VoiceTranslateScreen extends StatefulWidget {
  const VoiceTranslateScreen({super.key});

  @override
  State<VoiceTranslateScreen> createState() => _VoiceTranslateScreenState();
}

class _VoiceTranslateScreenState extends State<VoiceTranslateScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<TranslatorCubit, TranslatorState>(
      listener: (context, state) {
        if (state.status == TranslatorStatus.listening) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }

        if (state.status == TranslatorStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage)),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<TranslatorCubit>();

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
                        Text('From', style: theme.textTheme.labelMedium),
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
                        Text('To', style: theme.textTheme.labelMedium),
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
            const SizedBox(height: 16),

            // Status indicator
            if (state.status != TranslatorStatus.idle)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.status == TranslatorStatus.listening)
                      const Icon(Icons.hearing, size: 18, color: Colors.red),
                    if (state.status == TranslatorStatus.translating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (state.status == TranslatorStatus.speaking)
                      const Icon(Icons.volume_up, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      switch (state.status) {
                        TranslatorStatus.listening => 'Listening...',
                        TranslatorStatus.translating => 'Translating...',
                        TranslatorStatus.speaking => 'Speaking...',
                        TranslatorStatus.error => 'Error',
                        _ => '',
                      },
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Recognized text
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mic, size: 18,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Recognized Text',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.recognizedText.isEmpty
                                ? 'Tap the microphone to start speaking...'
                                : state.recognizedText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: state.recognizedText.isEmpty
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Translated text
                  Card(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.translate, size: 18,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Translation (${state.targetLanguage})',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (state.translatedText.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.volume_up, size: 20),
                                  onPressed: () {
                                    final code = TranslatorCubit
                                            .languages[state.targetLanguage] ??
                                        'en';
                                    cubit.replayTts(
                                        state.translatedText, code);
                                  },
                                  tooltip: 'Play translation',
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.translatedText.isEmpty
                                ? 'Translation will appear here...'
                                : state.translatedText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: state.translatedText.isEmpty
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Text input fallback
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Or type text to translate...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          final text = _textController.text.trim();
                          if (text.isNotEmpty) {
                            cubit.translateText(text);
                            _textController.clear();
                          }
                        },
                      ),
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        cubit.translateText(text.trim());
                        _textController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Mic button
            Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale =
                      1.0 + (_pulseController.value * 0.15);
                  return Transform.scale(
                    scale: state.status == TranslatorStatus.listening
                        ? scale
                        : 1.0,
                    child: child,
                  );
                },
                child: FloatingActionButton.large(
                  heroTag: 'voice_mic',
                  onPressed: () {
                    if (state.status == TranslatorStatus.listening) {
                      cubit.stopListening();
                    } else {
                      cubit.startListening();
                    }
                  },
                  backgroundColor: state.status == TranslatorStatus.listening
                      ? Colors.red
                      : theme.colorScheme.primary,
                  child: Icon(
                    state.status == TranslatorStatus.listening
                        ? Icons.stop
                        : Icons.mic,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
