import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/hive_service.dart';
import '../domain/scanned_document_model.dart';

class ScannerRepository {
  final String uid;

  ScannerRepository({required this.uid});

  Box<ScannedDocumentModel>? _box;
  String? _cachedBasePath;

  String get _boxName {
    if (uid.isNotEmpty) {
      return '${AppConstants.scannedDocumentsBox}_$uid';
    }
    return AppConstants.scannedDocumentsBox;
  }

  Future<Box<ScannedDocumentModel>> _getBox() async {
    if (_box != null && _box!.isOpen && _box!.name == _boxName) return _box!;
    _box = await HiveService.openBox<ScannedDocumentModel>(_boxName);
    return _box!;
  }

  Future<Directory> _getDocsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final scanDir = Directory('${appDir.path}/scanned_documents');
    if (!await scanDir.exists()) {
      await scanDir.create(recursive: true);
    }
    _cachedBasePath = scanDir.path;
    return scanDir;
  }

  /// Get the base path for scanned documents.
  Future<String> _getBasePath() async {
    if (_cachedBasePath != null) return _cachedBasePath!;
    final dir = await _getDocsDir();
    return dir.path;
  }

  /// Convert an absolute path to a relative path (relative to scanned_documents dir).
  Future<String> _toRelativePath(String absolutePath) async {
    final base = await _getBasePath();
    if (absolutePath.startsWith(base)) {
      return absolutePath.substring(base.length + 1); // +1 for the /
    }
    return absolutePath;
  }

  /// Resolve all page paths in a document to absolute paths.
  Future<ScannedDocumentModel> _resolveDocument(
      ScannedDocumentModel doc) async {
    final base = await _getBasePath();
    final resolvedPaths = <String>[];
    for (final path in doc.pageImagePaths) {
      if (path.startsWith('/')) {
        // Already absolute — but might be stale (iOS sandbox path change).
        // Check if the file exists; if not, try to reconstruct from relative part.
        if (await File(path).exists()) {
          resolvedPaths.add(path);
        } else {
          // Extract the relative part: {docId}/page_X.ext
          final parts = path.split('/scanned_documents/');
          if (parts.length > 1) {
            final reconstructed = '$base/${parts.last}';
            resolvedPaths.add(reconstructed);
          } else {
            resolvedPaths.add(path);
          }
        }
      } else {
        resolvedPaths.add('$base/$path');
      }
    }

    String? resolvedPdf;
    if (doc.pdfPath != null) {
      if (doc.pdfPath!.startsWith('/')) {
        if (await File(doc.pdfPath!).exists()) {
          resolvedPdf = doc.pdfPath;
        } else {
          final parts = doc.pdfPath!.split('/scanned_documents/');
          if (parts.length > 1) {
            resolvedPdf = '$base/${parts.last}';
          }
        }
      } else {
        resolvedPdf = '$base/${doc.pdfPath}';
      }
    }

    return doc.copyWith(
      pageImagePaths: resolvedPaths,
      pdfPath: resolvedPdf,
    );
  }

  Future<List<ScannedDocumentModel>> getAllDocuments() async {
    final box = await _getBox();
    final docs = <ScannedDocumentModel>[];
    for (final doc in box.values) {
      docs.add(await _resolveDocument(doc));
    }
    docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return docs;
  }

  Future<ScannedDocumentModel?> getDocumentById(String id) async {
    final box = await _getBox();
    try {
      final doc = box.values.firstWhere((doc) => doc.id == id);
      return _resolveDocument(doc);
    } catch (_) {
      return null;
    }
  }

  /// Copies images to app documents dir and creates a new document.
  Future<ScannedDocumentModel> createDocument({
    required String title,
    required List<String> sourceImagePaths,
  }) async {
    final docsDir = await _getDocsDir();
    final docId = const Uuid().v4();
    final docDir = Directory('${docsDir.path}/$docId');
    await docDir.create(recursive: true);

    final copiedPaths = <String>[];
    for (var i = 0; i < sourceImagePaths.length; i++) {
      final source = File(sourceImagePaths[i]);
      final ext = source.path.split('.').last;
      final dest = '${docDir.path}/page_$i.$ext';
      await source.copy(dest);
      // Store relative path: {docId}/page_X.ext
      copiedPaths.add('$docId/page_$i.$ext');
    }

    final now = DateTime.now();
    final document = ScannedDocumentModel(
      id: docId,
      title: title,
      pageImagePaths: copiedPaths,
      createdAt: now,
      updatedAt: now,
    );

    final box = await _getBox();
    await box.put(docId, document);

    // Return with resolved absolute paths for immediate use
    return _resolveDocument(document);
  }

  Future<void> updateDocument(ScannedDocumentModel document) async {
    // Convert any absolute paths back to relative before saving
    final relativePaths = <String>[];
    for (final path in document.pageImagePaths) {
      relativePaths.add(await _toRelativePath(path));
    }

    String? relativePdf;
    if (document.pdfPath != null) {
      relativePdf = await _toRelativePath(document.pdfPath!);
    }

    final toSave = document.copyWith(
      pageImagePaths: relativePaths,
      pdfPath: relativePdf,
    );

    final box = await _getBox();
    await box.put(toSave.id, toSave);
  }

  Future<void> deleteDocument(String id) async {
    final doc = await getDocumentById(id);
    if (doc == null) return;

    // Delete image files (resolved paths)
    for (final path in doc.pageImagePaths) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }

    // Delete PDF if exists
    if (doc.pdfPath != null) {
      final pdfFile = File(doc.pdfPath!);
      if (await pdfFile.exists()) await pdfFile.delete();
    }

    // Delete document directory
    final docsDir = await _getDocsDir();
    final docDir = Directory('${docsDir.path}/$id');
    if (await docDir.exists()) {
      await docDir.delete(recursive: true);
    }

    final box = await _getBox();
    await box.delete(id);
  }

  /// Add pages to an existing document.
  Future<ScannedDocumentModel> addPages({
    required String documentId,
    required List<String> sourceImagePaths,
  }) async {
    final doc = await getDocumentById(documentId);
    if (doc == null) throw Exception('Document not found');

    final docsDir = await _getDocsDir();
    final docDir = Directory('${docsDir.path}/$documentId');
    if (!await docDir.exists()) {
      await docDir.create(recursive: true);
    }

    // Find the next page index by counting existing files
    final existingFiles = await docDir.list().toList();
    var startIndex = existingFiles
        .whereType<File>()
        .where((f) => f.path.contains('page_'))
        .length;

    final newRelativePaths = <String>[];
    for (var i = 0; i < sourceImagePaths.length; i++) {
      final source = File(sourceImagePaths[i]);
      final ext = source.path.split('.').last;
      final dest = '${docDir.path}/page_${startIndex + i}.$ext';
      await source.copy(dest);
      newRelativePaths.add('$documentId/page_${startIndex + i}.$ext');
    }

    // Get current relative paths from storage
    final box = await _getBox();
    final storedDoc = box.values.firstWhere((d) => d.id == documentId);
    final allRelativePaths = [
      ...storedDoc.pageImagePaths,
      ...newRelativePaths,
    ];

    final updated = storedDoc.copyWith(
      pageImagePaths: allRelativePaths,
      updatedAt: DateTime.now(),
    );
    await box.put(documentId, updated);
    return _resolveDocument(updated);
  }

  Future<ScannedDocumentModel> renameDocument({
    required String documentId,
    required String newTitle,
  }) async {
    final box = await _getBox();
    final doc = box.values.firstWhere((d) => d.id == documentId);

    final updated = doc.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
    await box.put(documentId, updated);
    return _resolveDocument(updated);
  }

  /// Combines multiple documents into a single new document.
  Future<ScannedDocumentModel> combineDocuments({
    required List<String> documentIds,
    required String newTitle,
  }) async {
    // Get resolved (absolute) paths from all documents
    final allImagePaths = <String>[];
    for (final id in documentIds) {
      final doc = await getDocumentById(id);
      if (doc != null) {
        allImagePaths.addAll(doc.pageImagePaths);
      }
    }
    if (allImagePaths.isEmpty) throw Exception('No pages to combine');

    return createDocument(
      title: newTitle,
      sourceImagePaths: allImagePaths,
    );
  }

  /// Extracts selected pages from a document into a new document.
  Future<ScannedDocumentModel> extractPages({
    required String documentId,
    required List<int> pageIndices,
    required String newTitle,
  }) async {
    final doc = await getDocumentById(documentId);
    if (doc == null) throw Exception('Document not found');

    final selectedPaths = <String>[];
    for (final index in pageIndices) {
      if (index >= 0 && index < doc.pageImagePaths.length) {
        selectedPaths.add(doc.pageImagePaths[index]);
      }
    }
    if (selectedPaths.isEmpty) throw Exception('No valid pages selected');

    return createDocument(
      title: newTitle,
      sourceImagePaths: selectedPaths,
    );
  }
}
