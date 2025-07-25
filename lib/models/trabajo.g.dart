// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trabajo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrabajoAdapter extends TypeAdapter<Trabajo> {
  @override
  final int typeId = 1;

  @override
  Trabajo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Trabajo(
      id: fields[0] as String,
      nombre: fields[1] as String,
      precioM2: fields[2] as double,
      negocioId: fields[3] as String,
      creadoEn: fields[4] as DateTime,
      eliminadoEn: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Trabajo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.precioM2)
      ..writeByte(3)
      ..write(obj.negocioId)
      ..writeByte(4)
      ..write(obj.creadoEn)
      ..writeByte(5)
      ..write(obj.eliminadoEn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrabajoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
