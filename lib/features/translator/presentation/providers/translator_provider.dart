import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../scanner/data/translation_service.dart';
import '../../data/voice_translator_service.dart';
import '../../domain/conversation_entry.dart';

enum TranslatorStatus { idle, listening, translating, speaking, error }

class TranslatorState extends Equatable {
  const TranslatorState({
    this.status = TranslatorStatus.idle,
    this.sourceLanguage = 'English',
    this.targetLanguage = 'Spanish',
    this.recognizedText = '',
    this.translatedText = '',
    this.conversationHistory = const [],
    this.isConversationMode = false,
    this.errorMessage = '',
  });

  final TranslatorStatus status;
  final String sourceLanguage;
  final String targetLanguage;
  final String recognizedText;
  final String translatedText;
  final List<ConversationEntry> conversationHistory;
  final bool isConversationMode;
  final String errorMessage;

  TranslatorState copyWith({
    TranslatorStatus? status,
    String? sourceLanguage,
    String? targetLanguage,
    String? recognizedText,
    String? translatedText,
    List<ConversationEntry>? conversationHistory,
    bool? isConversationMode,
    String? errorMessage,
  }) {
    return TranslatorState(
      status: status ?? this.status,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      recognizedText: recognizedText ?? this.recognizedText,
      translatedText: translatedText ?? this.translatedText,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      isConversationMode: isConversationMode ?? this.isConversationMode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        sourceLanguage,
        targetLanguage,
        recognizedText,
        translatedText,
        conversationHistory,
        isConversationMode,
        errorMessage,
      ];
}

class TranslatorCubit extends Cubit<TranslatorState> {
  TranslatorCubit() : super(const TranslatorState());

  final _service = VoiceTranslatorService.instance;

  static final languages = TranslationService.languages;

  void setSourceLanguage(String language) {
    emit(state.copyWith(sourceLanguage: language));
  }

  void setTargetLanguage(String language) {
    emit(state.copyWith(targetLanguage: language));
  }

  void swapLanguages() {
    emit(state.copyWith(
      sourceLanguage: state.targetLanguage,
      targetLanguage: state.sourceLanguage,
    ));
  }

  Future<void> startListening() async {
    final langCode = languages[state.sourceLanguage] ?? 'en';

    emit(state.copyWith(
      status: TranslatorStatus.listening,
      recognizedText: '',
      translatedText: '',
    ));

    try {
      await _service.startListening(
        langCode: langCode,
        onResult: (text) {
          if (!isClosed) emit(state.copyWith(recognizedText: text));
        },
        onDone: () {
          if (isClosed) return;
          if (state.recognizedText.isNotEmpty) {
            translateAndSpeak();
          } else {
            emit(state.copyWith(status: TranslatorStatus.idle));
          }
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: TranslatorStatus.error,
        errorMessage:
            'Speech recognition not available for ${state.sourceLanguage}.',
      ));
    }
  }

  Future<void> stopListening() async {
    await _service.stopListening();
  }

  Future<void> translateAndSpeak() async {
    if (state.recognizedText.isEmpty) return;

    emit(state.copyWith(status: TranslatorStatus.translating));

    try {
      final translated = await _service.translate(
        text: state.recognizedText,
        targetLanguageName: state.targetLanguage,
      );

      emit(state.copyWith(
        translatedText: translated,
        status: TranslatorStatus.speaking,
      ));

      if (state.isConversationMode) {
        final isSpeakerA = state.conversationHistory.isEmpty ||
            !state.conversationHistory.last.isFromSpeakerA;
        final entry = ConversationEntry(
          originalText: state.recognizedText,
          translatedText: translated,
          sourceLang: state.sourceLanguage,
          targetLang: state.targetLanguage,
          timestamp: DateTime.now(),
          isFromSpeakerA: isSpeakerA,
        );
        emit(state.copyWith(
          conversationHistory: [...state.conversationHistory, entry],
        ));
      }

      final targetCode = languages[state.targetLanguage] ?? 'en';
      final spoke = await _service.speak(translated, targetCode);

      if (!spoke && !isClosed) {
        emit(state.copyWith(
          status: TranslatorStatus.error,
          errorMessage:
              'Voice not available for ${state.targetLanguage} on this device. '
              'Translation is shown above.',
        ));
        return;
      }

      if (!isClosed) emit(state.copyWith(status: TranslatorStatus.idle));
    } catch (e) {
      emit(state.copyWith(
        status: TranslatorStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  Future<void> translateText(String text) async {
    if (text.isEmpty) return;

    emit(state.copyWith(
      recognizedText: text,
      status: TranslatorStatus.translating,
    ));

    try {
      final translated = await _service.translate(
        text: text,
        targetLanguageName: state.targetLanguage,
      );

      emit(state.copyWith(
        translatedText: translated,
        status: TranslatorStatus.speaking,
      ));

      final targetCode = languages[state.targetLanguage] ?? 'en';
      final spoke = await _service.speak(translated, targetCode);

      if (!spoke && !isClosed) {
        emit(state.copyWith(
          status: TranslatorStatus.error,
          errorMessage:
              'Voice not available for ${state.targetLanguage} on this device. '
              'Translation is shown above.',
        ));
        return;
      }

      if (!isClosed) emit(state.copyWith(status: TranslatorStatus.idle));
    } catch (e) {
      emit(state.copyWith(
        status: TranslatorStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  void toggleConversationMode() {
    emit(state.copyWith(isConversationMode: !state.isConversationMode));
  }

  void clearConversation() {
    emit(state.copyWith(conversationHistory: []));
  }

  Future<void> replayTts(String text, String langCode) async {
    await _service.speak(text, langCode);
  }

  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Unsupported language')) return msg;
    if (msg.contains('414') || msg.contains('URI too long')) {
      return 'Text is too long. Please use shorter text.';
    }
    if (msg.contains('SocketException') || msg.contains('ClientException')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Translation failed. Please try again.';
  }

  @override
  Future<void> close() {
    _service.stopListening();
    _service.stopSpeaking();
    return super.close();
  }
}
