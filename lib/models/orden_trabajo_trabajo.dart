// Modelo de compatibilidad para OrdenTrabajoTrabajo
// Este es un wrapper para mantener compatibilidad con el código existente

import 'trabajo.dart';
import 'orden_trabajo_item_new.dart';

class OrdenTrabajoTrabajo {
  final String id;
  final Trabajo? trabajo;
  final double ancho;
  final double alto;
  final int cantidad;
  final double precioFinal; // No nullable para evitar problemas
  final double adicional;

  OrdenTrabajoTrabajo({
    required this.id,
    this.trabajo,
    required this.ancho,
    required this.alto,
    required this.cantidad,
    double? precioFinal, // Nullable en constructor
    this.adicional = 0.0,
  }) : precioFinal = precioFinal ?? _calcularPrecio(trabajo, ancho, alto, cantidad, adicional);

  // Método estático para calcular el precio
  static double _calcularPrecio(Trabajo? trabajo, double ancho, double alto, int cantidad, double adicional) {
    if (trabajo == null) return 0.0;
    return trabajo.calcularPrecio(ancho, alto, cantidad, adicional);
  }

  // Método para convertir a OrdenTrabajoItem
  OrdenTrabajoItem toOrdenTrabajoItem(String ordenId) {
    return OrdenTrabajoItem(
      ordenId: ordenId,
      trabajoNombre: trabajo?.nombre ?? 'Trabajo sin nombre',
      trabajoPrecioM2: trabajo?.precioM2 ?? 0.0,
      ancho: ancho,
      alto: alto,
      cantidad: cantidad,
      adicional: adicional,
    );
  }

  factory OrdenTrabajoTrabajo.fromJson(Map<String, dynamic> json) {
    return OrdenTrabajoTrabajo(
      id: json['id'] as String,
      trabajo: json['trabajo'] != null 
          ? Trabajo.fromJson(json['trabajo'] as Map<String, dynamic>)
          : null,
      ancho: (json['ancho'] as num).toDouble(),
      alto: (json['alto'] as num).toDouble(),
      cantidad: json['cantidad'] as int,
      precioFinal: (json['precio_final'] as num?)?.toDouble(),
      adicional: (json['adicional'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trabajo': trabajo?.toJson(),
      'ancho': ancho,
      'alto': alto,
      'cantidad': cantidad,
      'precio_final': precioFinal,
      'adicional': adicional,
    };
  }
}
