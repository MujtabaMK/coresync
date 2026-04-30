import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/pdf_reader_repository.dart';
import '../../domain/pdf_document_model.dart';

class PdfReaderState {
  const PdfReaderState({
    this.documents = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<PdfDocumentModel> documents;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  List<PdfDocumentModel> get filteredDocuments {
    if (searchQuery.isEmpty) return documents;
    final q = searchQuery.toLowerCase();
    return documents
        .where((d) => d.title.toLowerCase().contains(q))
        .toList();
  }

  PdfReaderState copyWith({
    List<PdfDocumentModel>? documents,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return PdfReaderState(
      documents: documents ?? this.documents,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PdfReaderCubit extends Cubit<PdfReaderState> {
  PdfReaderCubit({required PdfReaderRepository repository})
      : _repository = repository,
        super(const PdfReaderState());

  final PdfReaderRepository _repository;

  PdfReaderRepository get repository => _repository;

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

  Future<PdfDocumentModel> importPdf(String sourcePath) async {
    final doc = await _repository.importPdf(sourcePath);
    await loadDocuments();
    return doc;
  }

  Future<PdfDocumentModel> importPdfFromUrl(String url) async {
    final doc = await _repository.importPdfFromUrl(url);
    await loadDocuments();
    return doc;
  }

  Future<void> deleteDocument(String id) async {
    await _repository.deleteDocument(id);
    await loadDocuments();
  }

  Future<PdfDocumentModel> renameDocument({
    required String id,
    required String newTitle,
  }) async {
    final doc = await _repository.renamePdf(id: id, newTitle: newTitle);
    await loadDocuments();
    return doc;
  }

  Future<void> updateLastOpened(String id, {required int lastPage}) async {
    await _repository.updateLastOpened(id, lastPage: lastPage);
    await loadDocuments();
  }
}
