import 'dart:io';
import 'dart:ui';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class TtsWordPosition {
  const TtsWordPosition({
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.normalizedBounds,
  });

  final String text;
  final int startOffset;
  final int endOffset;
  final Rect normalizedBounds;
}

class PageTextWithPositions {
  const PageTextWithPositions({required this.fullText, required this.words});

  final String fullText;
  final List<TtsWordPosition> words;
}

class PdfTextExtractionService {
  PdfTextExtractionService._();

  /// Extract text from a specific page of a PDF file.
  /// [pageIndex] is 0-based.
  static Future<String> extractTextFromPage(
    String filePath,
    int pageIndex,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      if (pageIndex < 0 || pageIndex >= document.pages.count) return '';
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
      return text.trim();
    } finally {
      document.dispose();
    }
  }

  /// Extract text from all pages of a PDF file.
  static Future<String> extractAllText(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      return text.trim();
    } finally {
      document.dispose();
    }
  }

  /// Extract text from a range of pages.
  static Future<List<String>> extractTextFromPages(
    String filePath,
    int startPage,
    int endPage,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final pages = <String>[];
      final lastPage = endPage.clamp(0, document.pages.count - 1);
      for (var i = startPage; i <= lastPage; i++) {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        pages.add(text.trim());
      }
      return pages;
    } finally {
      document.dispose();
    }
  }

  /// Extract text with per-word bounding boxes for TTS highlight.
  /// Returns [PageTextWithPositions] with normalized (0-1) bounds.
  static Future<PageTextWithPositions> extractTextWithPositions(
    String filePath,
    int pageIndex,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        return const PageTextWithPositions(fullText: '', words: []);
      }

      final page = document.pages[pageIndex];
      final pageWidth = page.size.width;
      final pageHeight = page.size.height;

      final extractor = PdfTextExtractor(document);
      final textLines = extractor.extractTextLines(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );

      final words = <TtsWordPosition>[];
      final buffer = StringBuffer();
      var offset = 0;

      for (final line in textLines) {
        for (final word in line.wordCollection) {
          final text = word.text.trim();
          if (text.isEmpty) continue;

          if (offset > 0) {
            buffer.write(' ');
            offset++;
          }

          final startOffset = offset;
          buffer.write(text);
          offset += text.length;

          words.add(TtsWordPosition(
            text: text,
            startOffset: startOffset,
            endOffset: offset,
            normalizedBounds: Rect.fromLTRB(
              word.bounds.left / pageWidth,
              word.bounds.top / pageHeight,
              word.bounds.right / pageWidth,
              word.bounds.bottom / pageHeight,
            ),
          ));
        }
      }

      return PageTextWithPositions(fullText: buffer.toString(), words: words);
    } finally {
      document.dispose();
    }
  }
}
