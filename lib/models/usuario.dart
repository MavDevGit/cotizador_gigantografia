
import 'package:hive/hive.dart';

import 'trabajo.dart';

part 'usuario.g.dart';

@HiveType(typeId: 3)
class Usuario extends HiveObject implements SoftDeletable {
  @HiveField(0)
  String id;
  @HiveField(1)
  String email;
  @HiveField(2)
  String nombre;
  @HiveField(3)
  String rol; // 'admin' or 'empleado'
  @HiveField(4)
  String negocioId;
  @HiveField(5)
  DateTime creadoEn;
  @HiveField(6)
  @override
  DateTime? eliminadoEn;
  @HiveField(7)
  String password; // For local auth

  Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.negocioId,
    required this.creadoEn,
    required this.password,
    this.eliminadoEn,
  });
}
