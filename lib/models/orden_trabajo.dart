
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'archivo_adjunto.dart';
import 'cliente.dart';
import 'orden_historial.dart';
import 'orden_trabajo_trabajo.dart';

part 'orden_trabajo.g.dart';

@HiveType(typeId: 6)
class OrdenTrabajo extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  Cliente cliente;
  @HiveField(2)
  List<OrdenTrabajoTrabajo> trabajos;
  @HiveField(3)
  List<OrdenHistorial> historial;
  @HiveField(4)
  double adelanto;
  @HiveField(5)
  double? totalPersonalizado;
  @HiveField(6)
  String? notas;
  @HiveField(7)
  String estado;
  @HiveField(8)
  DateTime fechaEntrega;
  @HiveField(9)
  TimeOfDay horaEntrega;
  @HiveField(10)
  DateTime creadoEn;
  @HiveField(11)
  String creadoPorUsuarioId;
  @HiveField(12)
  List<ArchivoAdjunto> archivos;

  double get totalBruto =>
      trabajos.fold(0.0, (prev, item) => prev + item.precioFinal);

  double get rebaja {
    if (totalPersonalizado != null && totalPersonalizado! < totalBruto) {
      return totalBruto - totalPersonalizado!;
    }
    return 0.0;
  }

  double get total {
    if (totalPersonalizado != null) {
      return totalPersonalizado!;
    }
    return totalBruto;
  }

  double get saldo => total - adelanto;

  OrdenTrabajo({
    required this.id,
    required this.cliente,
    required this.trabajos,
    required this.historial,
    this.adelanto = 0.0,
    this.totalPersonalizado,
    this.notas,
    this.estado = 'pendiente',
    required this.fechaEntrega,
    required this.horaEntrega,
    required this.creadoEn,
    required this.creadoPorUsuarioId,
    List<ArchivoAdjunto>? archivos,
  }) : archivos = archivos ?? [];
}
