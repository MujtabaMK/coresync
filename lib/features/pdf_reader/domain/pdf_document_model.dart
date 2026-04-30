import 'package:hive/hive.dart';

part 'pdf_document_model.g.dart';

@HiveType(typeId: 5)
class PdfDocumentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  /// Relative path to the PDF file within the pdf_documents directory.
  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final int pageCount;

  @HiveField(4)
  final DateTime dateAdded;

  @HiveField(5)
  final DateTime lastOpened;

  /// Relative path to the thumbnail image.
  @HiveField(6)
  final String? thumbnailPath;

  /// Last viewed page (1-based).
  @HiveField(7)
  final int lastPage;

  /// File size in bytes.
  @HiveField(8)
  final int fileSize;

  PdfDocumentModel({
    required this.id,
    required this.title,
    required this.filePath,
    required this.pageCount,
    required this.dateAdded,
    required this.lastOpened,
    this.thumbnailPath,
    this.lastPage = 1,
    this.fileSize = 0,
  });

  PdfDocumentModel copyWith({
    String? id,
    String? title,
    String? filePath,
    int? pageCount,
    DateTime? dateAdded,
    DateTime? lastOpened,
    String? thumbnailPath,
    int? lastPage,
    int? fileSize,
  }) {
    return PdfDocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      pageCount: pageCount ?? this.pageCount,
      dateAdded: dateAdded ?? this.dateAdded,
      lastOpened: lastOpened ?? this.lastOpened,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      lastPage: lastPage ?? this.lastPage,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
