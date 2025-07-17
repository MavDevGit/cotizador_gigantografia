
import 'package:hive/hive.dart';

import 'trabajo.dart';

part 'cliente.g.dart';

@HiveType(typeId: 2)
class Cliente extends HiveObject implements SoftDeletable {
  @HiveField(0)
  String id;
  @HiveField(1)
  String nombre;
  @HiveField(2)
  String contacto;
  @HiveField(3)
  String negocioId;
  @HiveField(4)
  DateTime creadoEn;
  @HiveField(5)
  @override
  DateTime? eliminadoEn;

  Cliente({
    required this.id,
    required this.nombre,
    required this.contacto,
    required this.negocioId,
    required this.creadoEn,
    this.eliminadoEn,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cliente && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
