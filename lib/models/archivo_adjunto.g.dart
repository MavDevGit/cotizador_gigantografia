// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archivo_adjunto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArchivoAdjuntoAdapter extends TypeAdapter<ArchivoAdjunto> {
  @override
  final int typeId = 7;

  @override
  ArchivoAdjunto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArchivoAdjunto(
      id: fields[0] as String,
      nombre: fields[1] as String,
      rutaArchivo: fields[2] as String,
      tipoMime: fields[3] as String,
      tamano: fields[4] as int,
      fechaSubida: fields[5] as DateTime,
      subidoPorUsuarioId: fields[6] as String,
      subidoPorUsuarioNombre: fields[7] as String,
      descripcion: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ArchivoAdjunto obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.rutaArchivo)
      ..writeByte(3)
      ..write(obj.tipoMime)
      ..writeByte(4)
      ..write(obj.tamano)
      ..writeByte(5)
      ..write(obj.fechaSubida)
      ..writeByte(6)
      ..write(obj.subidoPorUsuarioId)
      ..writeByte(7)
      ..write(obj.subidoPorUsuarioNombre)
      ..writeByte(8)
      ..write(obj.descripcion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArchivoAdjuntoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
