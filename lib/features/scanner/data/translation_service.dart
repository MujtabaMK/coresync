import 'package:translator/translator.dart';

class TranslationService {
  TranslationService._();
  static final instance = TranslationService._();

  final _translator = GoogleTranslator();

  /// Language display name -> ISO 639-1 code
  static const languages = {
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Italian': 'it',
    'Portuguese': 'pt',
    'Hindi': 'hi',
    'Arabic': 'ar',
    'Chinese (Simplified)': 'zh-cn',
    'Chinese (Traditional)': 'zh-tw',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Russian': 'ru',
    'Turkish': 'tr',
    'Dutch': 'nl',
    'Polish': 'pl',
    'Swedish': 'sv',
    'Thai': 'th',
    'Vietnamese': 'vi',
    'Indonesian': 'id',
    'Urdu': 'ur',
  };

  Future<String> translate({
    required String text,
    required String targetLanguage,
  }) async {
    final code = languages[targetLanguage];
    if (code == null) throw Exception('Unsupported language: $targetLanguage');

    final result = await _translator.translate(text, to: code);
    return result.text;
  }
}
