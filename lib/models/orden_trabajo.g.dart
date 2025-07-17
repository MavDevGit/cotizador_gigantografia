// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orden_trabajo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrdenTrabajoAdapter extends TypeAdapter<OrdenTrabajo> {
  @override
  final int typeId = 6;

  @override
  OrdenTrabajo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrdenTrabajo(
      id: fields[0] as String,
      cliente: fields[1] as Cliente,
      trabajos: (fields[2] as List).cast<OrdenTrabajoTrabajo>(),
      historial: (fields[3] as List).cast<OrdenHistorial>(),
      adelanto: fields[4] as double,
      totalPersonalizado: fields[5] as double?,
      notas: fields[6] as String?,
      estado: fields[7] as String,
      fechaEntrega: fields[8] as DateTime,
      horaEntrega: fields[9] as TimeOfDay,
      creadoEn: fields[10] as DateTime,
      creadoPorUsuarioId: fields[11] as String,
      archivos: (fields[12] as List?)?.cast<ArchivoAdjunto>(),
    );
  }

  @override
  void write(BinaryWriter writer, OrdenTrabajo obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cliente)
      ..writeByte(2)
      ..write(obj.trabajos)
      ..writeByte(3)
      ..write(obj.historial)
      ..writeByte(4)
      ..write(obj.adelanto)
      ..writeByte(5)
      ..write(obj.totalPersonalizado)
      ..writeByte(6)
      ..write(obj.notas)
      ..writeByte(7)
      ..write(obj.estado)
      ..writeByte(8)
      ..write(obj.fechaEntrega)
      ..writeByte(9)
      ..write(obj.horaEntrega)
      ..writeByte(10)
      ..write(obj.creadoEn)
      ..writeByte(11)
      ..write(obj.creadoPorUsuarioId)
      ..writeByte(12)
      ..write(obj.archivos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrdenTrabajoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
