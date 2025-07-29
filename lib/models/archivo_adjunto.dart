// Modelo de compatibilidad para ArchivoAdjunto
// Este es un wrapper para mantener compatibilidad con el código existente

class ArchivoAdjunto {
  final String id;
  final String nombre;
  final String? ruta;
  final String? rutaArchivo; // Alias para compatibilidad
  final String? url;
  final int? tamano; // Cambiado de tamaño
  final String? tipo;
  final DateTime fechaSubida;

  // Getters para compatibilidad
  String? get tipoArchivo => tipo;
  String? get tipoMime => tipo;
  String get tamanoFormateado => tamano != null ? '${(tamano! / 1024).toStringAsFixed(1)} KB' : 'N/A';
  String get subidoPorUsuarioNombre => 'Usuario'; // Implementar según sea necesario
  String? get descripcion => null; // Implementar según sea necesario
  bool get icono => true; // Implementar según sea necesario

  Future<bool> exists() async {
    // Implementar verificación de existencia del archivo
    return true;
  }

  ArchivoAdjunto({
    required this.id,
    required this.nombre,
    this.ruta,
    this.url,
    this.tamano,
    this.tipo,
    required this.fechaSubida,
  }) : rutaArchivo = ruta;

  factory ArchivoAdjunto.fromJson(Map<String, dynamic> json) {
    return ArchivoAdjunto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      ruta: json['ruta'] as String?,
      url: json['url'] as String?,
      tamano: json['tamano'] as int?,
      tipo: json['tipo'] as String?,
      fechaSubida: DateTime.parse(json['fecha_subida'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ruta': ruta,
      'url': url,
      'tamano': tamano,
      'tipo': tipo,
      'fecha_subida': fechaSubida.toIso8601String(),
    };
  }
}
