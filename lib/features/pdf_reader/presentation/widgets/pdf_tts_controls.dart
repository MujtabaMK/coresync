import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../translator/data/tts_service.dart';
import '../../data/tts_number_preprocessor.dart';
import '../providers/pdf_viewer_provider.dart' show PdfTtsStatus, PdfViewerCubit, PdfViewerState, kTtsLanguages;

class PdfTtsControls extends StatelessWidget {
  const PdfTtsControls({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<PdfViewerCubit, PdfViewerState>(
      listenWhen: (prev, curr) => prev.ttsStatus != curr.ttsStatus,
      listener: (context, state) {
        if (state.ttsStatus == PdfTtsStatus.idle) {
          TtsService.instance.stop();
        }
      },
      builder: (context, state) {
        if (state.ttsStatus == PdfTtsStatus.idle) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Icon(
                  Icons.volume_up,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reading page ${state.currentPage} · ${kTtsLanguages[state.ttsLanguage] ?? state.ttsLanguage}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (state.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(
                      state.ttsStatus == PdfTtsStatus.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    iconSize: 20,
                    onPressed: () => _togglePlayPause(context, state),
                  ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  iconSize: 20,
                  onPressed: () {
                    final cubit = context.read<PdfViewerCubit>();
                    // Save position before stopping — same as pause
                    cubit.stopTtsAndRememberPage();
                    TtsService.instance.stop();
                    TtsService.instance.setProgressHandler(null);
                    cubit.clearTtsHighlight();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _togglePlayPause(BuildContext context, PdfViewerState state) async {
    final cubit = context.read<PdfViewerCubit>();

    if (state.ttsStatus == PdfTtsStatus.playing) {
      // ── PAUSE — set paused & save BEFORE stopping TTS ──
      // This keeps highlight data intact for the save and prevents
      // the speak-completion code from clearing state (it checks
      // for playing status before cleanup).
      cubit.setTtsStatus(PdfTtsStatus.paused);
      cubit.saveTtsPositionIfActive();
      await TtsService.instance.stop();
      TtsService.instance.setProgressHandler(null);
      return;
    }

    // ── RESUME from paused position, or fresh start ──
    cubit.setTtsStatus(PdfTtsStatus.playing);

    // Figure out where to resume
    final resumeOffset = _resumeOffset(state);

    String originalText;
    if (resumeOffset > 0 && state.ttsPageText.length > resumeOffset) {
      // Resume — use the already-extracted text, skip to paused position
      originalText = state.ttsPageText.substring(resumeOffset);
    } else {
      // Fresh start — extract text with positions
      final result = await cubit.extractCurrentPageTextWithPositions();
      originalText = result.fullText;
    }

    if (originalText.isEmpty) {
      cubit.clearTtsHighlight();
      cubit.setTtsStatus(PdfTtsStatus.idle);
      return;
    }

    // Preprocess: plain numbers → digit-by-digit, currency numbers → natural
    final preprocessed = preprocessTtsNumbers(originalText);

    final lang = cubit.state.ttsLanguage;

    // Progress handler — map preprocessed offsets back to original text
    TtsService.instance.setProgressHandler((text, start, end, word) {
      final originalOffset = preprocessed.toOriginalOffset(start);
      cubit.setTtsHighlightFromOffset(originalOffset + resumeOffset);
    });

    await TtsService.instance.speak(preprocessed.text, lang);
    TtsService.instance.setProgressHandler(null);
    // Only clean up if still playing — if user paused, keep positions for resume
    if (cubit.state.ttsStatus == PdfTtsStatus.playing) {
      cubit.clearTtsHighlight();
      cubit.setTtsStatus(PdfTtsStatus.idle);
    }
  }

  /// Character offset of the word where TTS was paused.
  int _resumeOffset(PdfViewerState state) {
    final hi = state.ttsHighlightIndex;
    if (hi == null || hi >= state.ttsWordPositions.length) return 0;
    return state.ttsWordPositions[hi].startOffset;
  }
}
