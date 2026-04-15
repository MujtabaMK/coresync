import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../data/ocr_service.dart';
import '../../data/pdf_service.dart';
import '../../data/scanner_repository.dart';
import '../../domain/scanned_document_model.dart';

class ScannerState {
  const ScannerState({
    this.documents = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<ScannedDocumentModel> documents;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  List<ScannedDocumentModel> get filteredDocuments {
    if (searchQuery.isEmpty) return documents;
    final q = searchQuery.toLowerCase();
    return documents
        .where((d) => d.title.toLowerCase().contains(q))
        .toList();
  }

  ScannerState copyWith({
    List<ScannedDocumentModel>? documents,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return ScannerState(
      documents: documents ?? this.documents,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ScannerCubit extends Cubit<ScannerState> {
  ScannerCubit({required ScannerRepository repository})
      : _repository = repository,
        super(const ScannerState());

  final ScannerRepository _repository;

  ScannerRepository get repository => _repository;

  Future<void> loadDocuments() async {
    emit(state.copyWith(isLoading: true));
    try {
      final documents = await _repository.getAllDocuments();
      emit(state.copyWith(documents: documents, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<ScannedDocumentModel?> getDocumentById(String id) async {
    return _repository.getDocumentById(id);
  }

  Future<ScannedDocumentModel> createDocument({
    required String title,
    required List<String> sourceImagePaths,
  }) async {
    final doc = await _repository.createDocument(
      title: title,
      sourceImagePaths: sourceImagePaths,
    );
    await loadDocuments();
    return doc;
  }

  Future<void> deleteDocument(String id) async {
    await _repository.deleteDocument(id);
    await loadDocuments();
  }

  Future<ScannedDocumentModel> addPages({
    required String documentId,
    required List<String> sourceImagePaths,
  }) async {
    final doc = await _repository.addPages(
      documentId: documentId,
      sourceImagePaths: sourceImagePaths,
    );
    await loadDocuments();
    return doc;
  }

  Future<void> reorderPages({
    required String documentId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final doc = await _repository.getDocumentById(documentId);
    if (doc == null) return;

    final pages = List<String>.from(doc.pageImagePaths);
    final item = pages.removeAt(oldIndex);
    pages.insert(newIndex, item);

    final updated = doc.copyWith(
      pageImagePaths: pages,
      updatedAt: DateTime.now(),
    );
    await _repository.updateDocument(updated);
    await loadDocuments();
  }

  Future<void> removePage({
    required String documentId,
    required int pageIndex,
  }) async {
    final doc = await _repository.getDocumentById(documentId);
    if (doc == null) return;

    final pages = List<String>.from(doc.pageImagePaths);
    if (pageIndex < 0 || pageIndex >= pages.length) return;
    pages.removeAt(pageIndex);

    final updated = doc.copyWith(
      pageImagePaths: pages,
      updatedAt: DateTime.now(),
    );
    await _repository.updateDocument(updated);
    await loadDocuments();
  }

  Future<ScannedDocumentModel> renameDocument({
    required String documentId,
    required String newTitle,
  }) async {
    final doc = await _repository.renameDocument(
      documentId: documentId,
      newTitle: newTitle,
    );
    await loadDocuments();
    return doc;
  }

  String _safePdfPath(ScannedDocumentModel doc) {
    final safeTitle = doc.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return doc.pageImagePaths.first
        .replaceAll(RegExp(r'/page_\d+\.\w+$'), '/$safeTitle.pdf');
  }

  Future<String> generatePdf(String documentId) async {
    final doc = await _repository.getDocumentById(documentId);
    if (doc == null) throw Exception('Document not found');

    final outputPath = _safePdfPath(doc);
    await PdfService.generatePdf(
      imagePaths: doc.pageImagePaths,
      outputPath: outputPath,
    );

    final updated = doc.copyWith(
      pdfPath: outputPath,
      updatedAt: DateTime.now(),
    );
    await _repository.updateDocument(updated);
    await loadDocuments();
    return outputPath;
  }

  /// Combine multiple documents into one.
  Future<ScannedDocumentModel> combineDocuments({
    required List<String> documentIds,
    required String newTitle,
  }) async {
    final doc = await _repository.combineDocuments(
      documentIds: documentIds,
      newTitle: newTitle,
    );
    await loadDocuments();
    return doc;
  }

  /// Extract selected pages into a new document.
  Future<ScannedDocumentModel> extractPages({
    required String documentId,
    required List<int> pageIndices,
    required String newTitle,
  }) async {
    final doc = await _repository.extractPages(
      documentId: documentId,
      pageIndices: pageIndices,
      newTitle: newTitle,
    );
    await loadDocuments();
    return doc;
  }

  /// Generate a compressed PDF.
  Future<String> generateCompressedPdf(
    String documentId, {
    int quality = 50,
  }) async {
    final doc = await _repository.getDocumentById(documentId);
    if (doc == null) throw Exception('Document not found');

    final safeTitle = doc.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final outputPath = doc.pageImagePaths.first.replaceAll(
      RegExp(r'/page_\d+\.\w+$'),
      '/${safeTitle}_compressed.pdf',
    );

    await PdfService.generateCompressedPdf(
      imagePaths: doc.pageImagePaths,
      outputPath: outputPath,
      quality: quality,
    );
    return outputPath;
  }

  /// Generate a password-protected PDF.
  Future<String> generateProtectedPdf(
    String documentId,
    String password,
  ) async {
    final doc = await _repository.getDocumentById(documentId);
    if (doc == null) throw Exception('Document not found');

    final safeTitle = doc.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final outputPath = doc.pageImagePaths.first.replaceAll(
      RegExp(r'/page_\d+\.\w+$'),
      '/${safeTitle}_protected.pdf',
    );

    await PdfService.generateProtectedPdf(
      imagePaths: doc.pageImagePaths,
      outputPath: outputPath,
      password: password,
    );
    return outputPath;
  }

  /// Print the document.
  Future<void> printDocument(String documentId) async {
    final doc = await _repository.getDocumentById(documentId);
    if (doc == null) throw Exception('Document not found');

    final pdfPath = await generatePdf(documentId);
    final pdfBytes = await File(pdfPath).readAsBytes();
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  /// Recognize text from document using OCR.
  Future<String> recognizeText(String documentId) async {
    final doc = await _repository.getDocumentById(documentId);
    if (doc == null) throw Exception('Document not found');

    return OcrService.recognizeTextFromPages(doc.pageImagePaths);
  }

  /// Export OCR text to a .txt file and return the path.
  Future<String> exportAsText(String documentId) async {
    final doc = await _repository.getDocumentById(documentId);
    if (doc == null) throw Exception('Document not found');

    final text = await recognizeText(documentId);
    final dir = await getApplicationDocumentsDirectory();
    final safeTitle = doc.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final file = File('${dir.path}/$safeTitle.txt');
    await file.writeAsString(text);
    return file.path;
  }
}
