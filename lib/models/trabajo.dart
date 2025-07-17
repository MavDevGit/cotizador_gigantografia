
import 'package:hive/hive.dart';

part 'trabajo.g.dart';

// Interface for items that can be soft-deleted.
abstract class SoftDeletable {
  DateTime? eliminadoEn;
}

@HiveType(typeId: 1)
class Trabajo extends HiveObject implements SoftDeletable {
  @HiveField(0)
  String id;
  @HiveField(1)
  String nombre;
  @HiveField(2)
  double precioM2;
  @HiveField(3)
  String negocioId;
  @HiveField(4)
  DateTime creadoEn;
  @HiveField(5)
  @override
  DateTime? eliminadoEn;

  Trabajo({
    required this.id,
    required this.nombre,
    required this.precioM2,
    required this.negocioId,
    required this.creadoEn,
    this.eliminadoEn,
  });

  double calcularPrecio(
      double ancho, double alto, int cantidad, double adicional) {
    final area = ancho * alto;
    final precioBase = area * precioM2 * cantidad;
    return precioBase + adicional;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trabajo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
