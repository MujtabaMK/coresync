import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';

import '../domain/ocr_block.dart';

/// Builds a proper .docx Word document from OCR blocks, preserving the
/// original text layout with correct font sizes and positioning.
class DocxService {
  DocxService._();

  /// A4 usable area in points (after 1-inch margins on each side).
  static const double _pageWidthPt = 451.0; // 595 - 72*2
  static const double _pageHeightPt = 698.0; // 842 - 72*2

  /// A4 in twips.
  static const int _a4WidthTwips = 11906;
  static const int _a4HeightTwips = 16838;

  /// 1-inch margin in twips.
  static const int _marginTwips = 1440;

  /// Builds a .docx with OCR text laid out to match the original scan.
  static Uint8List build({
    required List<OcrBlock> blocks,
    required Size imageSize,
  }) {
    final archive = Archive();

    _addFile(archive, '[Content_Types].xml', _contentTypes);
    _addFile(archive, '_rels/.rels', _rels);
    _addFile(archive, 'word/_rels/document.xml.rels', _documentRels);
    _addFile(archive, 'word/document.xml',
        _documentXml(blocks, imageSize));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static String _documentXml(List<OcrBlock> blocks, Size imageSize) {
    // Scale from image pixels to page points (usable area)
    final sX = _pageWidthPt / imageSize.width;
    final sY = _pageHeightPt / imageSize.height;

    // Filter active blocks and sort top-to-bottom, then left-to-right
    final active = blocks
        .where((b) => !b.isDeleted)
        .toList()
      ..sort((a, b) {
        final dy = a.boundingBox.top - b.boundingBox.top;
        if (dy.abs() > a.boundingBox.height * 0.4) return dy < 0 ? -1 : 1;
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      });

    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.writeln('<w:document '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">');
    buf.writeln('<w:body>');

    double prevBottomPt = 0;

    for (final block in active) {
      final r = block.boundingBox;

      // Position in points on the usable page area
      final leftPt = r.left * sX;
      final topPt = r.top * sY;
      final heightPt = r.height * sY;

      // Gap from previous block bottom to this block top
      final gapPt = (topPt - prevBottomPt).clamp(0.0, 200.0);
      prevBottomPt = topPt + heightPt;

      // Convert to twips (1pt = 20 twips)
      final indentTwips = (leftPt * 20).round();
      final spaceBeforeTwips = (gapPt * 20).round();

      // Font size: derive from block height, in half-points
      // Typical line height ≈ 1.2× font size, so font ≈ height / 1.2
      final fontSizePt = (heightPt / 1.2).clamp(6.0, 72.0);
      final fontHalfPts = (fontSizePt * 2).round();

      final escaped = _xmlEscape(block.text);

      buf.writeln('<w:p>');
      buf.writeln('<w:pPr>');
      buf.writeln('<w:ind w:left="$indentTwips"/>');
      buf.writeln('<w:spacing w:before="$spaceBeforeTwips" w:after="0" w:line="240" w:lineRule="auto"/>');
      buf.writeln('</w:pPr>');
      buf.writeln('<w:r>');
      buf.writeln('<w:rPr>');
      buf.writeln('<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>');
      buf.writeln('<w:sz w:val="$fontHalfPts"/>');
      buf.writeln('<w:szCs w:val="$fontHalfPts"/>');
      buf.writeln('<w:color w:val="000000"/>');
      buf.writeln('</w:rPr>');
      buf.writeln('<w:t xml:space="preserve">$escaped</w:t>');
      buf.writeln('</w:r>');
      buf.writeln('</w:p>');
    }

    // Section properties – A4 with 1-inch margins
    buf.writeln('<w:sectPr>');
    buf.writeln('<w:pgSz w:w="$_a4WidthTwips" w:h="$_a4HeightTwips"/>');
    buf.writeln('<w:pgMar w:top="$_marginTwips" w:right="$_marginTwips" '
        'w:bottom="$_marginTwips" w:left="$_marginTwips" '
        'w:header="720" w:footer="720" w:gutter="0"/>');
    buf.writeln('</w:sectPr>');

    buf.writeln('</w:body></w:document>');
    return buf.toString();
  }

  static const _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '</Types>';

  static const _rels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';

  static const _documentRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '</Relationships>';

  static void _addFile(Archive archive, String path, String content) {
    final bytes = Uint8List.fromList(content.codeUnits);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  static String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
