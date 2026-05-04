import 'dart:convert';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/hive_service.dart';
import '../../../scanner/domain/annotation_model.dart';
import '../../data/pdf_text_extraction_service.dart';

enum PdfTtsStatus { idle, playing, paused }

/// Supported TTS languages (matches TtsService._localeMap keys).
const kTtsLanguages = <String, String>{
  'en': 'English',
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'it': 'Italian',
  'pt': 'Portuguese',
  'hi': 'Hindi',
  'ar': 'Arabic',
  'zh-cn': 'Chinese (Simplified)',
  'zh-tw': 'Chinese (Traditional)',
  'ja': 'Japanese',
  'ko': 'Korean',
  'ru': 'Russian',
  'tr': 'Turkish',
  'nl': 'Dutch',
  'pl': 'Polish',
  'sv': 'Swedish',
  'th': 'Thai',
  'vi': 'Vietnamese',
  'id': 'Indonesian',
  'ur': 'Urdu',
};

class PdfViewerState {
  const PdfViewerState({
    this.currentPage = 1,
    this.pageCount = 0,
    this.ttsStatus = PdfTtsStatus.idle,
    this.ttsPageText = '',
    this.ttsLastStoppedPage,
    this.ttsLastStoppedOffset = 0,
    this.ttsLanguage = 'en',
    this.isAnnotating = false,
    this.annotationTool = AnnotationTool.pen,
    this.annotationColor = const Color(0xFFFF0000),
    this.annotations = const {},
    this.isLoading = false,
    this.ttsWordPositions = const [],
    this.ttsHighlightIndex,
    this.ttsActivePage = 0,
  });

  final int currentPage;
  final int pageCount;
  final PdfTtsStatus ttsStatus;
  final String ttsPageText;

  /// The page (1-based) where TTS was last stopped, or null if never started.
  final int? ttsLastStoppedPage;

  /// Character offset within the stopped page text where TTS was paused.
  final int ttsLastStoppedOffset;

  /// ISO 639-1 language code for TTS (auto-detected or manually set).
  final String ttsLanguage;
  final bool isAnnotating;
  final AnnotationTool annotationTool;
  final Color annotationColor;
  /// Page annotations keyed by 0-based page index.
  final Map<int, List<Annotation>> annotations;
  final bool isLoading;

  /// Word positions for TTS highlighting on current page.
  final List<TtsWordPosition> ttsWordPositions;

  /// Index into [ttsWordPositions] of the currently spoken word.
  final int? ttsHighlightIndex;

  /// The page (1-based) that [ttsWordPositions] belong to. Highlight only
  /// renders on this page — prevents stale highlights on a different page
  /// after the user turns pages while TTS is playing.
  final int ttsActivePage;

  /// Whether the user has a previous TTS position to resume from.
  bool get hasTtsResumePoint => ttsLastStoppedPage != null;

  List<Annotation> annotationsForPage(int pageIndex) {
    return annotations[pageIndex] ?? [];
  }

  PdfViewerState copyWith({
    int? currentPage,
    int? pageCount,
    PdfTtsStatus? ttsStatus,
    String? ttsPageText,
    int? ttsLastStoppedPage,
    bool clearTtsLastStoppedPage = false,
    int? ttsLastStoppedOffset,
    String? ttsLanguage,
    bool? isAnnotating,
    AnnotationTool? annotationTool,
    Color? annotationColor,
    Map<int, List<Annotation>>? annotations,
    bool? isLoading,
    List<TtsWordPosition>? ttsWordPositions,
    int? ttsHighlightIndex,
    bool clearTtsHighlightIndex = false,
    int? ttsActivePage,
  }) {
    return PdfViewerState(
      currentPage: currentPage ?? this.currentPage,
      pageCount: pageCount ?? this.pageCount,
      ttsStatus: ttsStatus ?? this.ttsStatus,
      ttsPageText: ttsPageText ?? this.ttsPageText,
      ttsLastStoppedPage: clearTtsLastStoppedPage
          ? null
          : (ttsLastStoppedPage ?? this.ttsLastStoppedPage),
      ttsLastStoppedOffset: ttsLastStoppedOffset ?? this.ttsLastStoppedOffset,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      isAnnotating: isAnnotating ?? this.isAnnotating,
      annotationTool: annotationTool ?? this.annotationTool,
      annotationColor: annotationColor ?? this.annotationColor,
      annotations: annotations ?? this.annotations,
      isLoading: isLoading ?? this.isLoading,
      ttsWordPositions: ttsWordPositions ?? this.ttsWordPositions,
      ttsHighlightIndex: clearTtsHighlightIndex
          ? null
          : (ttsHighlightIndex ?? this.ttsHighlightIndex),
      ttsActivePage: ttsActivePage ?? this.ttsActivePage,
    );
  }
}

class PdfViewerCubit extends Cubit<PdfViewerState> {
  PdfViewerCubit({
    required this.documentId,
    required this.filePath,
    required this.uid,
    int initialPage = 1,
    int pageCount = 0,
  }) : super(PdfViewerState(currentPage: initialPage, pageCount: pageCount));

  final String documentId;
  final String filePath;
  final String uid;

  void setCurrentPage(int page) {
    if (page == state.currentPage) return;
    // If TTS is paused and page changes, stop TTS (resume state is stale)
    if (state.ttsStatus == PdfTtsStatus.paused) {
      emit(state.copyWith(
        currentPage: page,
        ttsStatus: PdfTtsStatus.idle,
        ttsWordPositions: const [],
        clearTtsHighlightIndex: true,
      ));
    } else {
      emit(state.copyWith(currentPage: page));
    }
  }

  void setPageCount(int count) {
    emit(state.copyWith(pageCount: count));
  }

  // --- TTS ---

  bool _languageAutoDetected = false;

  Future<String> extractCurrentPageText() async {
    emit(state.copyWith(isLoading: true));
    try {
      final text = await PdfTextExtractionService.extractTextFromPage(
        filePath,
        state.currentPage - 1, // 0-based
      );

      // Auto-detect language on first extraction if not previously saved
      if (!_languageAutoDetected) {
        _languageAutoDetected = true;
        final detected = detectLanguage(text);
        if (state.ttsLanguage == 'en' && detected != 'en') {
          emit(state.copyWith(ttsPageText: text, ttsLanguage: detected, isLoading: false));
          _saveTtsLanguage(detected);
          return text;
        }
      }

      emit(state.copyWith(ttsPageText: text, isLoading: false));
      return text;
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      return '';
    }
  }

  /// Extract text with word positions for TTS highlighting.
  /// If [page] is provided (1-based), extracts from that page and updates
  /// [currentPage]; otherwise uses the current page from state.
  Future<PageTextWithPositions> extractCurrentPageTextWithPositions({
    int? page,
  }) async {
    final targetPage = page ?? state.currentPage;
    if (page != null && page != state.currentPage) {
      emit(state.copyWith(currentPage: page, isLoading: true));
    } else {
      emit(state.copyWith(isLoading: true));
    }
    final pageIndex = targetPage - 1;
    try {
      final result = await PdfTextExtractionService.extractTextWithPositions(
        filePath,
        pageIndex,
      );

      // Auto-detect language on first extraction
      if (!_languageAutoDetected) {
        _languageAutoDetected = true;
        final detected = detectLanguage(result.fullText);
        if (state.ttsLanguage == 'en' && detected != 'en') {
          emit(state.copyWith(
            ttsPageText: result.fullText,
            ttsWordPositions: result.words,
            ttsActivePage: targetPage,
            ttsLanguage: detected,
            isLoading: false,
          ));
          _saveTtsLanguage(detected);
          return result;
        }
      }

      emit(state.copyWith(
        ttsPageText: result.fullText,
        ttsWordPositions: result.words,
        ttsActivePage: targetPage,
        isLoading: false,
      ));
      return result;
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      return const PageTextWithPositions(fullText: '', words: []);
    }
  }

  DateTime? _lastTtsSaveTime;

  void setTtsHighlightFromOffset(int charOffset) {
    final words = state.ttsWordPositions;
    for (var i = 0; i < words.length; i++) {
      if (charOffset >= words[i].startOffset && charOffset < words[i].endOffset) {
        if (state.ttsHighlightIndex != i) {
          emit(state.copyWith(ttsHighlightIndex: i));
        }
        // Periodically persist position so it survives app kill
        final now = DateTime.now();
        if (_lastTtsSaveTime == null ||
            now.difference(_lastTtsSaveTime!).inSeconds >= 1) {
          _lastTtsSaveTime = now;
          _saveTtsPosition(state.currentPage, charOffset);
        }
        return;
      }
    }
  }

  void clearTtsHighlight() {
    emit(state.copyWith(
      ttsWordPositions: const [],
      clearTtsHighlightIndex: true,
    ));
  }

  void setTtsStatus(PdfTtsStatus status) {
    if (status == PdfTtsStatus.idle) _lastTtsSaveTime = null;
    emit(state.copyWith(ttsStatus: status));
  }

  void setTtsLanguage(String langCode) {
    emit(state.copyWith(ttsLanguage: langCode));
    _saveTtsLanguage(langCode);
  }

  /// Auto-detect the language from extracted text using Unicode script analysis.
  String detectLanguage(String text) {
    if (text.isEmpty) return 'en';

    final counts = <String, int>{};
    for (final c in text.runes) {
      final script = _scriptFromCodePoint(c);
      if (script != null) {
        counts[script] = (counts[script] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 'en';

    // Find dominant script
    final dominant = counts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    // For Latin script, try to distinguish by common words
    if (dominant.key == 'latin') {
      return _detectLatinLanguage(text);
    }

    // Arabic and Urdu share the same base Unicode block – distinguish by
    // checking for Urdu-specific characters.
    if (dominant.key == 'ar' && _hasUrduCharacters(text)) {
      return 'ur';
    }

    return dominant.key;
  }

  String? _scriptFromCodePoint(int c) {
    if (c >= 0x0600 && c <= 0x06FF) return 'ar'; // Arabic
    if (c >= 0x0750 && c <= 0x077F) return 'ar'; // Arabic Supplement
    if (c >= 0x0900 && c <= 0x097F) return 'hi'; // Devanagari
    if (c >= 0xAC00 && c <= 0xD7AF) return 'ko'; // Hangul syllables
    if (c >= 0x1100 && c <= 0x11FF) return 'ko'; // Hangul Jamo
    if (c >= 0x3040 && c <= 0x309F) return 'ja'; // Hiragana
    if (c >= 0x30A0 && c <= 0x30FF) return 'ja'; // Katakana
    if (c >= 0x4E00 && c <= 0x9FFF) return 'zh-cn'; // CJK Unified
    if (c >= 0x0E00 && c <= 0x0E7F) return 'th'; // Thai
    if (c >= 0x0400 && c <= 0x04FF) return 'ru'; // Cyrillic
    if (c >= 0x0041 && c <= 0x024F) return 'latin'; // Latin
    if (c >= 0x0980 && c <= 0x09FF) return 'hi'; // Bengali → Hindi TTS
    if (c >= 0x0A00 && c <= 0x0A7F) return 'hi'; // Gurmukhi → Hindi TTS
    if (c >= 0x0A80 && c <= 0x0AFF) return 'hi'; // Gujarati → Hindi TTS
    if (c >= 0x0B80 && c <= 0x0BFF) return 'hi'; // Tamil → Hindi TTS
    if (c >= 0x0C00 && c <= 0x0C7F) return 'hi'; // Telugu → Hindi TTS
    if (c >= 0x0C80 && c <= 0x0CFF) return 'hi'; // Kannada → Hindi TTS
    if (c >= 0x0D00 && c <= 0x0D7F) return 'hi'; // Malayalam → Hindi TTS
    if (c >= 0xFB50 && c <= 0xFDFF) return 'ur'; // Arabic Presentation Forms-A (common in Urdu)
    return null;
  }

  /// Returns true if the text contains Urdu-specific characters that are
  /// absent from standard Arabic, indicating the text is Urdu rather than
  /// Arabic despite sharing the same Unicode block.
  bool _hasUrduCharacters(String text) {
    const urduSpecific = {
      0x0679, // ٹ TTEH
      0x0688, // ڈ DDAL
      0x0691, // ڑ RREH
      0x06BA, // ں NOON GHUNNA
      0x06BE, // ھ HEH DOACHASHMEE
      0x06C1, // ہ HEH GOAL
      0x06D2, // ے YEH BARREE
    };
    var count = 0;
    for (final c in text.runes) {
      if (urduSpecific.contains(c)) count++;
      if (count >= 3) return true;
    }
    return false;
  }

  String _detectLatinLanguage(String text) {
    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));
    final wordSet = words.toSet();

    // Common words per language (high-frequency function words)
    const patterns = <String, List<String>>{
      'en': ['the', 'and', 'is', 'in', 'to', 'of', 'that', 'it', 'for', 'was'],
      'es': ['el', 'la', 'de', 'en', 'los', 'del', 'las', 'por', 'con', 'una'],
      'fr': ['le', 'la', 'les', 'des', 'est', 'dans', 'une', 'que', 'pour', 'pas'],
      'de': ['der', 'die', 'und', 'den', 'das', 'ist', 'ein', 'eine', 'auf', 'nicht'],
      'it': ['il', 'di', 'che', 'la', 'del', 'della', 'nel', 'dei', 'gli', 'una'],
      'pt': ['de', 'que', 'os', 'do', 'da', 'em', 'uma', 'para', 'com', 'pelo'],
      'nl': ['de', 'het', 'een', 'van', 'dat', 'niet', 'zijn', 'voor', 'ook', 'aan'],
      'pl': ['nie', 'jest', 'sie', 'jak', 'ale', 'tak', 'ich', 'przy', 'dla', 'tego'],
      'sv': ['och', 'att', 'det', 'som', 'har', 'med', 'den', 'inte', 'ett', 'kan'],
      'tr': ['bir', 'olan', 'ile', 'icin', 'olan', 'ama', 'gibi', 'daha', 'kadar', 'sonra'],
      'vi': ['cua', 'trong', 'nhung', 'mot', 'cho', 'nhu', 'khi', 'duoc', 'theo', 'con'],
      'id': ['yang', 'dan', 'dari', 'ini', 'untuk', 'pada', 'dengan', 'tidak', 'juga', 'akan'],
    };

    var bestLang = 'en';
    var bestScore = 0;
    for (final entry in patterns.entries) {
      final score = entry.value.where(wordSet.contains).length;
      if (score > bestScore) {
        bestScore = score;
        bestLang = entry.key;
      }
    }
    return bestLang;
  }

  /// Preprocesses text so standalone numbers (e.g. "9028") are read
  /// digit-by-digit ("9 0 2 8"), while numbers preceded by a currency
  /// symbol or abbreviation (e.g. "$9028", "Rs 9028") are left intact
  /// for natural reading ("nine thousand twenty eight").
  static String preprocessNumbersForTts(String text) {
    final re = RegExp(
      r'([\$£€¥₹]\s*|(?:Rs\.?|PKR|USD|GBP|EUR|INR)\s+)?(\d[\d,]*(?:\.\d+)?)',
      caseSensitive: false,
    );
    return text.replaceAllMapped(re, (m) {
      final prefix = m.group(1);
      final number = m.group(2)!;
      if (prefix != null && prefix.isNotEmpty) {
        return m.group(0)!; // currency amount – keep for natural reading
      }
      // Standalone number – space out digits for digit-by-digit reading
      final clean = number.replaceAll(',', '');
      return clean
          .split('')
          .map((c) => c == '.' ? 'point' : c)
          .join(' ');
    });
  }

  /// Record the page + offset where TTS was stopped so we can resume later.
  void stopTtsAndRememberPage() {
    final offset = _currentTtsCharOffset();
    emit(state.copyWith(
      ttsStatus: PdfTtsStatus.idle,
      ttsLastStoppedPage: state.currentPage,
      ttsLastStoppedOffset: offset,
    ));
    _saveTtsPosition(state.currentPage, offset);
  }

  /// Save TTS position from the current in-memory state (called on dispose).
  void saveTtsPositionIfActive() {
    if (state.ttsStatus == PdfTtsStatus.idle) return;
    final offset = _currentTtsCharOffset();
    _saveTtsPosition(state.currentPage, offset);
  }

  /// Clear the TTS resume point (only when user explicitly stops).
  void clearTtsResumePoint() {
    _lastTtsSaveTime = null;
    emit(state.copyWith(
      clearTtsLastStoppedPage: true,
      ttsLastStoppedOffset: 0,
    ));
    _clearTtsPosition();
  }

  /// Compute the character offset of the currently highlighted word.
  int _currentTtsCharOffset() {
    final hi = state.ttsHighlightIndex;
    if (hi == null || hi >= state.ttsWordPositions.length) return 0;
    return state.ttsWordPositions[hi].startOffset;
  }

  // --- Annotations ---

  void toggleAnnotationMode() {
    emit(state.copyWith(isAnnotating: !state.isAnnotating));
  }

  void setAnnotationTool(AnnotationTool tool) {
    emit(state.copyWith(annotationTool: tool));
  }

  void setAnnotationColor(Color color) {
    emit(state.copyWith(annotationColor: color));
  }

  void addAnnotation(int pageIndex, Annotation annotation) {
    final updated = Map<int, List<Annotation>>.from(state.annotations);
    updated[pageIndex] = [...(updated[pageIndex] ?? []), annotation];
    emit(state.copyWith(annotations: updated));
    _saveAnnotations(pageIndex, updated[pageIndex]!);
  }

  void undoAnnotation(int pageIndex) {
    final pageAnnotations = state.annotations[pageIndex];
    if (pageAnnotations == null || pageAnnotations.isEmpty) return;

    final updated = Map<int, List<Annotation>>.from(state.annotations);
    final newList = List<Annotation>.from(pageAnnotations)..removeLast();
    updated[pageIndex] = newList;
    emit(state.copyWith(annotations: updated));
    _saveAnnotations(pageIndex, newList);
  }

  void clearAnnotations(int pageIndex) {
    final updated = Map<int, List<Annotation>>.from(state.annotations);
    updated[pageIndex] = [];
    emit(state.copyWith(annotations: updated));
    _saveAnnotations(pageIndex, []);
  }

  /// Load annotations and saved language from Hive.
  Future<void> loadAnnotations() async {
    try {
      final boxName = uid.isNotEmpty
          ? '${AppConstants.pdfAnnotationsBox}_$uid'
          : AppConstants.pdfAnnotationsBox;
      final box = await HiveService.openBox<String>(boxName);
      final loaded = <int, List<Annotation>>{};

      for (final key in box.keys) {
        final k = key.toString();
        if (!k.startsWith('${documentId}_page_')) continue;
        final pageIdx = int.tryParse(k.split('_page_').last);
        if (pageIdx == null) continue;
        final json = box.get(key);
        if (json == null || json.isEmpty) continue;
        final list = (jsonDecode(json) as List)
            .map((m) => _annotationFromJson(m as Map<String, dynamic>))
            .whereType<Annotation>()
            .toList();
        if (list.isNotEmpty) loaded[pageIdx] = list;
      }

      // Load saved TTS language
      final savedLang = box.get('${documentId}_tts_language');

      // Load saved TTS position (page:offset)
      int? savedPage;
      var savedOffset = 0;
      final posStr = box.get('${documentId}_tts_position');
      if (posStr != null) {
        final parts = posStr.split(':');
        if (parts.length == 2) {
          savedPage = int.tryParse(parts[0]);
          savedOffset = int.tryParse(parts[1]) ?? 0;
        }
      }

      emit(state.copyWith(
        annotations: loaded,
        ttsLanguage: savedLang,
        ttsLastStoppedPage: savedPage,
        ttsLastStoppedOffset: savedOffset,
      ));
    } catch (_) {}
  }

  Future<void> _saveAnnotations(int pageIndex, List<Annotation> annotations) async {
    try {
      final boxName = uid.isNotEmpty
          ? '${AppConstants.pdfAnnotationsBox}_$uid'
          : AppConstants.pdfAnnotationsBox;
      final box = await HiveService.openBox<String>(boxName);
      final key = '${documentId}_page_$pageIndex';
      if (annotations.isEmpty) {
        await box.delete(key);
      } else {
        final json = jsonEncode(annotations.map(_annotationToJson).toList());
        await box.put(key, json);
      }
    } catch (_) {}
  }

  Future<void> _saveTtsLanguage(String langCode) async {
    try {
      final boxName = uid.isNotEmpty
          ? '${AppConstants.pdfAnnotationsBox}_$uid'
          : AppConstants.pdfAnnotationsBox;
      final box = await HiveService.openBox<String>(boxName);
      await box.put('${documentId}_tts_language', langCode);
    } catch (_) {}
  }

  Future<void> _saveTtsPosition(int page, int charOffset) async {
    try {
      final boxName = uid.isNotEmpty
          ? '${AppConstants.pdfAnnotationsBox}_$uid'
          : AppConstants.pdfAnnotationsBox;
      final box = await HiveService.openBox<String>(boxName);
      await box.put('${documentId}_tts_position', '$page:$charOffset');
    } catch (_) {}
  }

  Future<void> _clearTtsPosition() async {
    try {
      final boxName = uid.isNotEmpty
          ? '${AppConstants.pdfAnnotationsBox}_$uid'
          : AppConstants.pdfAnnotationsBox;
      final box = await HiveService.openBox<String>(boxName);
      await box.delete('${documentId}_tts_position');
    } catch (_) {}
  }

  // --- Annotation JSON serialization ---

  Map<String, dynamic> _annotationToJson(Annotation a) {
    if (a is StrokeAnnotation) {
      return {
        'type': 'stroke',
        'id': a.id,
        'color': a.color.toARGB32(),
        'strokeWidth': a.strokeWidth,
        'points': a.points.map((p) => [p.dx, p.dy]).toList(),
      };
    } else if (a is TextAnnotation) {
      return {
        'type': 'text',
        'id': a.id,
        'color': a.color.toARGB32(),
        'position': [a.position.dx, a.position.dy],
        'text': a.text,
        'fontSize': a.fontSize,
      };
    } else if (a is RectAnnotation) {
      return {
        'type': 'rect',
        'id': a.id,
        'color': a.color.toARGB32(),
        'topLeft': [a.topLeft.dx, a.topLeft.dy],
        'bottomRight': [a.bottomRight.dx, a.bottomRight.dy],
        'strokeWidth': a.strokeWidth,
      };
    } else if (a is LineAnnotation) {
      return {
        'type': 'line',
        'id': a.id,
        'color': a.color.toARGB32(),
        'start': [a.start.dx, a.start.dy],
        'end': [a.end.dx, a.end.dy],
        'strokeWidth': a.strokeWidth,
      };
    }
    return {'type': 'unknown'};
  }

  Annotation? _annotationFromJson(Map<String, dynamic> m) {
    final type = m['type'] as String?;
    final colorValue = m['color'] as int;
    final color = Color.fromARGB(
      (colorValue >> 24) & 0xFF,
      (colorValue >> 16) & 0xFF,
      (colorValue >> 8) & 0xFF,
      colorValue & 0xFF,
    );
    final id = m['id'] as String?;

    switch (type) {
      case 'stroke':
        final points = (m['points'] as List)
            .map((p) => Offset((p as List)[0] as double, p[1] as double))
            .toList();
        return StrokeAnnotation(
          points: points,
          color: color,
          strokeWidth: (m['strokeWidth'] as num).toDouble(),
          id: id,
        );
      case 'text':
        final pos = m['position'] as List;
        return TextAnnotation(
          position: Offset((pos[0] as num).toDouble(), (pos[1] as num).toDouble()),
          text: m['text'] as String,
          color: color,
          fontSize: (m['fontSize'] as num).toDouble(),
          id: id,
        );
      case 'rect':
        final tl = m['topLeft'] as List;
        final br = m['bottomRight'] as List;
        return RectAnnotation(
          topLeft: Offset((tl[0] as num).toDouble(), (tl[1] as num).toDouble()),
          bottomRight: Offset((br[0] as num).toDouble(), (br[1] as num).toDouble()),
          color: color,
          strokeWidth: (m['strokeWidth'] as num).toDouble(),
          id: id,
        );
      case 'line':
        final s = m['start'] as List;
        final e = m['end'] as List;
        return LineAnnotation(
          start: Offset((s[0] as num).toDouble(), (s[1] as num).toDouble()),
          end: Offset((e[0] as num).toDouble(), (e[1] as num).toDouble()),
          color: color,
          strokeWidth: (m['strokeWidth'] as num).toDouble(),
          id: id,
        );
      default:
        return null;
    }
  }
}
