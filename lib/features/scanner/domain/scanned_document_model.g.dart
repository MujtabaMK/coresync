// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanned_document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScannedDocumentModelAdapter extends TypeAdapter<ScannedDocumentModel> {
  @override
  final int typeId = 3;

  @override
  ScannedDocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScannedDocumentModel(
      id: fields[0] as String,
      title: fields[1] as String,
      pageImagePaths: (fields[2] as List).cast<String>(),
      pdfPath: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ScannedDocumentModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.pageImagePaths)
      ..writeByte(3)
      ..write(obj.pdfPath)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedDocumentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
