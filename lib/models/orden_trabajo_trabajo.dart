
import 'package:hive/hive.dart';

import 'trabajo.dart';

part 'orden_trabajo_trabajo.g.dart';

@HiveType(typeId: 4)
class OrdenTrabajoTrabajo extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  Trabajo trabajo;
  @HiveField(2)
  double ancho;
  @HiveField(3)
  double alto;
  @HiveField(4)
  int cantidad;
  @HiveField(5)
  double adicional;

  double get precioFinal =>
      (ancho * alto * trabajo.precioM2 * cantidad) + adicional;

  OrdenTrabajoTrabajo({
    required this.id,
    required this.trabajo,
    this.ancho = 1.0,
    this.alto = 1.0,
    this.cantidad = 1,
    this.adicional = 0.0,
  });
}
