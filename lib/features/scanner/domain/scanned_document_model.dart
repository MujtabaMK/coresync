import 'package:hive/hive.dart';

part 'scanned_document_model.g.dart';

@HiveType(typeId: 3)
class ScannedDocumentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<String> pageImagePaths;

  @HiveField(3)
  final String? pdfPath;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  int get pageCount => pageImagePaths.length;

  ScannedDocumentModel({
    required this.id,
    required this.title,
    required this.pageImagePaths,
    this.pdfPath,
    required this.createdAt,
    required this.updatedAt,
  });

  ScannedDocumentModel copyWith({
    String? id,
    String? title,
    List<String>? pageImagePaths,
    String? pdfPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScannedDocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      pageImagePaths: pageImagePaths ?? this.pageImagePaths,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
