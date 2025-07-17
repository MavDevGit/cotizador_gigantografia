// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orden_historial.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrdenHistorialAdapter extends TypeAdapter<OrdenHistorial> {
  @override
  final int typeId = 5;

  @override
  OrdenHistorial read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrdenHistorial(
      id: fields[0] as String,
      cambio: fields[1] as String,
      usuarioId: fields[2] as String,
      usuarioNombre: fields[3] as String,
      timestamp: fields[4] as DateTime,
      dispositivo: fields[5] as String?,
      ip: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrdenHistorial obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cambio)
      ..writeByte(2)
      ..write(obj.usuarioId)
      ..writeByte(3)
      ..write(obj.usuarioNombre)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.dispositivo)
      ..writeByte(6)
      ..write(obj.ip);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrdenHistorialAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
