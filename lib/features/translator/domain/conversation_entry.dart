import 'package:equatable/equatable.dart';

class ConversationEntry extends Equatable {
  const ConversationEntry({
    required this.originalText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.timestamp,
    required this.isFromSpeakerA,
  });

  final String originalText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final DateTime timestamp;
  final bool isFromSpeakerA;

  @override
  List<Object?> get props => [
        originalText,
        translatedText,
        sourceLang,
        targetLang,
        timestamp,
        isFromSpeakerA,
      ];
}
