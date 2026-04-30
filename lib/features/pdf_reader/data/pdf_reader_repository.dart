import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/hive_service.dart';
import '../domain/pdf_document_model.dart';

class PdfReaderRepository {
  final String uid;

  PdfReaderRepository({required this.uid});

  Box<PdfDocumentModel>? _box;
  String? _cachedBasePath;

  String get _boxName {
    if (uid.isNotEmpty) {
      return '${AppConstants.pdfDocumentsBox}_$uid';
    }
    return AppConstants.pdfDocumentsBox;
  }

  Future<Box<PdfDocumentModel>> _getBox() async {
    if (_box != null && _box!.isOpen && _box!.name == _boxName) return _box!;
    _box = await HiveService.openBox<PdfDocumentModel>(_boxName);
    return _box!;
  }

  Future<Directory> _getDocsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${appDir.path}/pdf_documents');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    _cachedBasePath = pdfDir.path;
    return pdfDir;
  }

  Future<String> _getBasePath() async {
    if (_cachedBasePath != null) return _cachedBasePath!;
    final dir = await _getDocsDir();
    return dir.path;
  }

  /// Resolve a relative path to an absolute path, handling iOS sandbox changes.
  Future<String> _resolvePath(String path) async {
    if (path.startsWith('/')) {
      if (await File(path).exists()) return path;
      // iOS sandbox path change — reconstruct from relative part
      final parts = path.split('/pdf_documents/');
      if (parts.length > 1) {
        final base = await _getBasePath();
        return '$base/${parts.last}';
      }
      return path;
    }
    final base = await _getBasePath();
    return '$base/$path';
  }

  Future<PdfDocumentModel> _resolveDocument(PdfDocumentModel doc) async {
    final resolvedFilePath = await _resolvePath(doc.filePath);
    String? resolvedThumbnail;
    if (doc.thumbnailPath != null) {
      resolvedThumbnail = await _resolvePath(doc.thumbnailPath!);
    }
    return doc.copyWith(
      filePath: resolvedFilePath,
      thumbnailPath: resolvedThumbnail,
    );
  }

  Future<List<PdfDocumentModel>> getAllDocuments() async {
    final box = await _getBox();
    final docs = <PdfDocumentModel>[];
    for (final doc in box.values) {
      docs.add(await _resolveDocument(doc));
    }
    docs.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    return docs;
  }

  Future<PdfDocumentModel?> getDocumentById(String id) async {
    final box = await _getBox();
    try {
      final doc = box.values.firstWhere((d) => d.id == id);
      return _resolveDocument(doc);
    } catch (_) {
      return null;
    }
  }

  /// Import a PDF file from [sourcePath] into the app's document storage.
  Future<PdfDocumentModel> importPdf(String sourcePath) async {
    final docsDir = await _getDocsDir();
    final docId = const Uuid().v4();
    final docDir = Directory('${docsDir.path}/$docId');
    await docDir.create(recursive: true);

    // Copy PDF to app documents
    final sourceFile = File(sourcePath);
    final fileSize = await sourceFile.length();
    final fileName = sourcePath.split('/').last;
    final destPath = '${docDir.path}/$fileName';
    await sourceFile.copy(destPath);

    // Validate PDF and extract info
    int pageCount = 0;
    String? thumbnailRelPath;
    try {
      final pdfDoc = await pdfrx.PdfDocument.openFile(destPath);
      pageCount = pdfDoc.pages.length;

      // Generate thumbnail from first page
      if (pdfDoc.pages.isNotEmpty) {
        thumbnailRelPath = await _generateThumbnail(
          pdfDoc.pages[0],
          docDir.path,
          docId,
        );
      }
      pdfDoc.dispose();
    } catch (e) {
      // File is not a valid PDF — clean up and reject
      debugPrint('PDF validation failed: $e');
      await docDir.delete(recursive: true);
      throw Exception('The file is not a valid PDF');
    }

    final title = fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final now = DateTime.now();
    final relativeFilePath = '$docId/$fileName';

    final document = PdfDocumentModel(
      id: docId,
      title: title,
      filePath: relativeFilePath,
      pageCount: pageCount,
      dateAdded: now,
      lastOpened: now,
      thumbnailPath: thumbnailRelPath,
      lastPage: 1,
      fileSize: fileSize,
    );

    final box = await _getBox();
    await box.put(docId, document);

    return _resolveDocument(document);
  }

  /// Download a PDF from [url] and import it into local storage.
  Future<PdfDocumentModel> importPdfFromUrl(String url) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Download failed (HTTP ${response.statusCode})');
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('pdf') &&
        !contentType.contains('octet-stream') &&
        !url.toLowerCase().endsWith('.pdf')) {
      throw Exception('URL does not point to a PDF file');
    }

    // Derive file name from URL path or content-disposition header
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final disposition = response.headers['content-disposition'];
    if (disposition != null) {
      final match = RegExp(r'filename[*]?="?([^";]+)"?').firstMatch(disposition);
      if (match != null) fileName = match.group(1)!;
    }
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      fileName = fileName.isEmpty ? 'download.pdf' : '$fileName.pdf';
    }
    // Sanitise
    fileName = fileName.replaceAll(RegExp(r'[^\w\s.\-]'), '_');

    // Write to a temporary file, then delegate to importPdf
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(response.bodyBytes);

    try {
      return await importPdf(tempFile.path);
    } finally {
      // Clean up temp file
      if (await tempFile.exists()) await tempFile.delete();
    }
  }

  Future<String?> _generateThumbnail(
    pdfrx.PdfPage page,
    String docDirPath,
    String docId,
  ) async {
    try {
      // Render at ~300px wide for a reasonable thumbnail
      const thumbWidth = 300.0;
      final scale = thumbWidth / page.width;
      final thumbHeight = page.height * scale;

      final rendered = await page.render(
        fullWidth: thumbWidth,
        fullHeight: thumbHeight,
      );
      if (rendered == null) return null;

      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        rendered.pixels,
        rendered.width,
        rendered.height,
        rendered.format,
        completer.complete,
      );
      final uiImage = await completer.future;
      rendered.dispose();

      final byteData = await uiImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      uiImage.dispose();

      if (byteData == null) return null;

      final thumbnailPath = '$docDirPath/thumbnail.png';
      await File(thumbnailPath).writeAsBytes(
        byteData.buffer.asUint8List(),
      );
      return '$docId/thumbnail.png';
    } catch (e) {
      debugPrint('Thumbnail generation failed: $e');
      return null;
    }
  }

  Future<void> deleteDocument(String id) async {
    final docsDir = await _getDocsDir();
    final docDir = Directory('${docsDir.path}/$id');
    if (await docDir.exists()) {
      await docDir.delete(recursive: true);
    }

    final box = await _getBox();
    await box.delete(id);

    // Clean up annotations
    try {
      final annotationsBoxName = uid.isNotEmpty
          ? '${AppConstants.pdfAnnotationsBox}_$uid'
          : AppConstants.pdfAnnotationsBox;
      final annotationsBox = await HiveService.openBox<String>(annotationsBoxName);
      final keysToDelete = annotationsBox.keys
          .where((k) => k.toString().startsWith('${id}_'))
          .toList();
      for (final key in keysToDelete) {
        await annotationsBox.delete(key);
      }
    } catch (_) {}
  }

  Future<PdfDocumentModel> updateLastOpened(
    String id, {
    required int lastPage,
  }) async {
    final box = await _getBox();
    final doc = box.values.firstWhere((d) => d.id == id);
    final updated = doc.copyWith(
      lastOpened: DateTime.now(),
      lastPage: lastPage,
    );
    await box.put(id, updated);
    return _resolveDocument(updated);
  }

  Future<PdfDocumentModel> renamePdf({
    required String id,
    required String newTitle,
  }) async {
    final box = await _getBox();
    final doc = box.values.firstWhere((d) => d.id == id);
    final updated = doc.copyWith(title: newTitle);
    await box.put(id, updated);
    return _resolveDocument(updated);
  }
}
