// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

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

class ClienteAdapter extends TypeAdapter<Cliente> {
  @override
  final int typeId = 2;

  @override
  Cliente read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cliente(
      id: fields[0] as String,
      nombre: fields[1] as String,
      contacto: fields[2] as String,
      negocioId: fields[3] as String,
      creadoEn: fields[4] as DateTime,
      eliminadoEn: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Cliente obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.contacto)
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
      other is ClienteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UsuarioAdapter extends TypeAdapter<Usuario> {
  @override
  final int typeId = 3;

  @override
  Usuario read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Usuario(
      id: fields[0] as String,
      email: fields[1] as String,
      nombre: fields[2] as String,
      rol: fields[3] as String,
      negocioId: fields[4] as String,
      creadoEn: fields[5] as DateTime,
      password: fields[7] as String,
      eliminadoEn: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Usuario obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.nombre)
      ..writeByte(3)
      ..write(obj.rol)
      ..writeByte(4)
      ..write(obj.negocioId)
      ..writeByte(5)
      ..write(obj.creadoEn)
      ..writeByte(6)
      ..write(obj.eliminadoEn)
      ..writeByte(7)
      ..write(obj.password);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
    );
  }

  @override
  void write(BinaryWriter writer, OrdenTrabajo obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.creadoPorUsuarioId);
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

class TimeOfDayAdapterAdapter extends TypeAdapter<TimeOfDayAdapter> {
  @override
  final int typeId = 100;

  @override
  TimeOfDayAdapter read(BinaryReader reader) {
    return TimeOfDayAdapter();
  }

  @override
  void write(BinaryWriter writer, TimeOfDayAdapter obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDayAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
