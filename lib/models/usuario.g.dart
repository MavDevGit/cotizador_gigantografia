// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
