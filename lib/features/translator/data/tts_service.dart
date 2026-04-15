import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final instance = TtsService._();

  final _tts = FlutterTts();
  bool _initialized = false;

  /// Maps ISO 639-1 codes to TTS locale identifiers.
  static const _localeMap = {
    'en': 'en-US',
    'es': 'es-ES',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'it': 'it-IT',
    'pt': 'pt-BR',
    'hi': 'hi-IN',
    'ar': 'ar-SA',
    'zh-cn': 'zh-CN',
    'zh-tw': 'zh-TW',
    'ja': 'ja-JP',
    'ko': 'ko-KR',
    'ru': 'ru-RU',
    'tr': 'tr-TR',
    'nl': 'nl-NL',
    'pl': 'pl-PL',
    'sv': 'sv-SE',
    'th': 'th-TH',
    'vi': 'vi-VN',
    'id': 'id-ID',
    'ur': 'ur-PK',
  };

  /// Fallback locale variants to try when the primary locale isn't available.
  /// Urdu has no TTS voice on most devices, so fall back to Hindi
  /// (mutually intelligible spoken language).
  /// Arabic may need different regional variants depending on the device.
  static const _fallbackLocales = {
    'ur-PK': ['ur-IN', 'hi-IN'],
    'ar-SA': ['ar-001', 'ar-AE', 'ar-EG', 'ar-XA'],
  };

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // Wait for speech to finish before returning from speak()
    await _tts.awaitSpeakCompletion(true);
    if (Platform.isIOS) {
      // Use playback category so TTS works after STT releases the mic.
      // defaultToSpeaker ensures audio plays through the speaker.
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ],
      );
    }
    _initialized = true;
  }

  /// Try to set a TTS language, returning true if the voice is available.
  Future<bool> _trySetLanguage(String locale) async {
    final result = await _tts.setLanguage(locale);
    // flutter_tts returns 1 on success, 0 on failure
    return result == 1;
  }

  /// Speaks [text] in the given language. Returns `true` if a suitable voice
  /// was found, `false` if no voice was available for the language.
  Future<bool> speak(String text, String langCode) async {
    await _ensureInitialized();
    final primaryLocale = _localeMap[langCode] ?? 'en-US';

    // Try primary locale first
    if (await _trySetLanguage(primaryLocale)) {
      await _tts.speak(text);
      return true;
    }

    // Try fallback locales
    final fallbacks = _fallbackLocales[primaryLocale];
    if (fallbacks != null) {
      for (final fallback in fallbacks) {
        if (await _trySetLanguage(fallback)) {
          debugPrint('TTS: $primaryLocale unavailable, using fallback $fallback');
          await _tts.speak(text);
          return true;
        }
      }
    }

    // No compatible voice found – don't attempt to speak non-Latin script
    // with an English voice as it produces silence / gibberish.
    debugPrint('TTS: No voice found for $primaryLocale or fallbacks, '
        'skipping speech');
    return false;
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
