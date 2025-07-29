// Modelo de compatibilidad para OrdenHistorial
// Este es un wrapper para mantener compatibilidad con el código existente

class OrdenHistorial {
  final String id;
  final String accion;
  final String? descripcion;
  final DateTime fecha;
  final String usuarioId;

  // Para compatibilidad
  String get cambio => descripcion ?? accion;

  OrdenHistorial({
    required this.id,
    required this.accion,
    this.descripcion,
    required this.fecha,
    required this.usuarioId,
    String? cambio, // Para compatibilidad
  });

  // Constructor alternativo para compatibilidad
  OrdenHistorial.withCambio({
    required this.id,
    required String cambio,
    required this.fecha,
    required this.usuarioId,
  }) : accion = 'cambio',
       descripcion = cambio;

  factory OrdenHistorial.fromJson(Map<String, dynamic> json) {
    return OrdenHistorial(
      id: json['id'] as String,
      accion: json['accion'] as String,
      descripcion: json['descripcion'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      usuarioId: json['usuario_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accion': accion,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'usuario_id': usuarioId,
    };
  }
}
