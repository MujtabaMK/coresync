// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PdfDocumentModelAdapter extends TypeAdapter<PdfDocumentModel> {
  @override
  final int typeId = 5;

  @override
  PdfDocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfDocumentModel(
      id: fields[0] as String,
      title: fields[1] as String,
      filePath: fields[2] as String,
      pageCount: fields[3] as int,
      dateAdded: fields[4] as DateTime,
      lastOpened: fields[5] as DateTime,
      thumbnailPath: fields[6] as String?,
      lastPage: fields[7] as int,
      fileSize: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PdfDocumentModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.pageCount)
      ..writeByte(4)
      ..write(obj.dateAdded)
      ..writeByte(5)
      ..write(obj.lastOpened)
      ..writeByte(6)
      ..write(obj.thumbnailPath)
      ..writeByte(7)
      ..write(obj.lastPage)
      ..writeByte(8)
      ..write(obj.fileSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfDocumentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
