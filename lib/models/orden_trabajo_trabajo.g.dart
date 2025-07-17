// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orden_trabajo_trabajo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrdenTrabajoTrabajoAdapter extends TypeAdapter<OrdenTrabajoTrabajo> {
  @override
  final int typeId = 4;

  @override
  OrdenTrabajoTrabajo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrdenTrabajoTrabajo(
      id: fields[0] as String,
      trabajo: fields[1] as Trabajo,
      ancho: fields[2] as double,
      alto: fields[3] as double,
      cantidad: fields[4] as int,
      adicional: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, OrdenTrabajoTrabajo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.trabajo)
      ..writeByte(2)
      ..write(obj.ancho)
      ..writeByte(3)
      ..write(obj.alto)
      ..writeByte(4)
      ..write(obj.cantidad)
      ..writeByte(5)
      ..write(obj.adicional);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrdenTrabajoTrabajoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
