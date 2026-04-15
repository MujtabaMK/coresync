import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../scanner/data/translation_service.dart';
import 'tts_service.dart';

class VoiceTranslatorService {
  VoiceTranslatorService._();
  static final instance = VoiceTranslatorService._();

  final _stt = SpeechToText();
  final _translationService = TranslationService.instance;
  final _ttsService = TtsService.instance;

  bool _sttInitialized = false;
  Set<String>? _availableLocaleIds;

  /// Maps ISO 639-1 codes to STT locale identifiers.
  static const _sttLocaleMap = {
    'en': 'en_US',
    'es': 'es_ES',
    'fr': 'fr_FR',
    'de': 'de_DE',
    'it': 'it_IT',
    'pt': 'pt_BR',
    'hi': 'hi_IN',
    'ar': 'ar_SA',
    'zh-cn': 'zh_CN',
    'zh-tw': 'zh_TW',
    'ja': 'ja_JP',
    'ko': 'ko_KR',
    'ru': 'ru_RU',
    'tr': 'tr_TR',
    'nl': 'nl_NL',
    'pl': 'pl_PL',
    'sv': 'sv_SE',
    'th': 'th_TH',
    'vi': 'vi_VN',
    'id': 'id_ID',
    'ur': 'ur_PK',
  };

  /// Fallback STT locales when the primary locale isn't installed.
  /// Urdu falls back to Hindi (mutually intelligible).
  static const _sttFallbackLocales = {
    'ur_PK': ['ur_IN', 'hi_IN'],
    'ar_SA': ['ar_001', 'ar_AE', 'ar_EG'],
  };

  Future<bool> initStt() async {
    if (_sttInitialized) return true;
    _sttInitialized = await _stt.initialize();
    if (_sttInitialized) {
      final locales = await _stt.locales();
      _availableLocaleIds = locales.map((l) => l.localeId).toSet();
      debugPrint('STT: ${_availableLocaleIds!.length} locales available');
    }
    return _sttInitialized;
  }

  bool get isAvailable => _sttInitialized;

  /// Finds a supported STT locale, trying the preferred one then fallbacks.
  String _resolveLocale(String preferred) {
    if (_availableLocaleIds == null || _availableLocaleIds!.isEmpty) {
      return preferred;
    }

    // Check exact match
    if (_availableLocaleIds!.contains(preferred)) return preferred;

    // Check prefix match (e.g. ur_PK might be listed as ur-PK)
    final prefixMatch = _availableLocaleIds!.cast<String?>().firstWhere(
          (id) => id!.startsWith(preferred.split('_').first),
          orElse: () => null,
        );
    if (prefixMatch != null) return prefixMatch;

    // Check fallbacks
    final fallbacks = _sttFallbackLocales[preferred];
    if (fallbacks != null) {
      for (final fb in fallbacks) {
        if (_availableLocaleIds!.contains(fb)) {
          debugPrint('STT: $preferred unavailable, using fallback $fb');
          return fb;
        }
        // Prefix match for fallback
        final fbPrefix = _availableLocaleIds!.cast<String?>().firstWhere(
              (id) => id!.startsWith(fb.split('_').first),
              orElse: () => null,
            );
        if (fbPrefix != null) {
          debugPrint('STT: $preferred unavailable, using fallback $fbPrefix');
          return fbPrefix;
        }
      }
    }

    debugPrint('STT: No locale found for $preferred or fallbacks');
    return preferred; // Let the engine try anyway
  }

  Future<void> startListening({
    required String langCode,
    required void Function(String text) onResult,
    required void Function() onDone,
  }) async {
    if (!_sttInitialized) {
      final ok = await initStt();
      if (!ok) {
        onDone();
        return;
      }
    }

    final preferred = _sttLocaleMap[langCode] ?? 'en_US';
    final locale = _resolveLocale(preferred);
    await _stt.listen(
      localeId: locale,
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) onDone();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  /// Google Translate free API limit per request (~5000 chars).
  static const _maxCharsPerRequest = 4500;

  Future<String> translate({
    required String text,
    required String targetLanguageName,
  }) async {
    // Split long text into chunks to avoid API character limit
    if (text.length <= _maxCharsPerRequest) {
      return _translationService.translate(
        text: text,
        targetLanguage: targetLanguageName,
      );
    }

    final chunks = _splitText(text, _maxCharsPerRequest);
    final results = <String>[];
    for (final chunk in chunks) {
      final translated = await _translationService.translate(
        text: chunk,
        targetLanguage: targetLanguageName,
      );
      results.add(translated);
    }
    return results.join(' ');
  }

  /// Splits text into chunks at sentence/word boundaries.
  static List<String> _splitText(String text, int maxLen) {
    final chunks = <String>[];
    var remaining = text;
    while (remaining.length > maxLen) {
      var splitAt = remaining.lastIndexOf('. ', maxLen);
      if (splitAt <= 0) splitAt = remaining.lastIndexOf(' ', maxLen);
      if (splitAt <= 0) splitAt = maxLen;
      chunks.add(remaining.substring(0, splitAt).trim());
      remaining = remaining.substring(splitAt).trim();
    }
    if (remaining.isNotEmpty) chunks.add(remaining);
    return chunks;
  }

  Future<bool> speak(String text, String langCode) async {
    return _ttsService.speak(text, langCode);
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
  }
}
