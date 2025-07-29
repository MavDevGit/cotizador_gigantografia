// Modelo para Trabajo adaptado a Supabase
class Trabajo {
  final String id;
  String nombre;
  double precioM2;
  final String empresaId;
  final bool archivado;
  final DateTime createdAt;

  // Para compatibilidad con código existente
  DateTime get creadoEn => createdAt;
  String get negocioId => empresaId; // Alias para compatibilidad

  Trabajo({
    required this.id,
    required this.nombre,
    required this.precioM2,
    required this.empresaId,
    this.archivado = false,
    required this.createdAt,
  });

  // Constructor alternativo para compatibilidad
  Trabajo.legacy({
    required this.id,
    required this.nombre,
    required this.precioM2,
    required String negocioId, // Para compatibilidad
    this.archivado = false,
    required this.createdAt,
  }) : empresaId = negocioId;

  factory Trabajo.fromJson(Map<String, dynamic> json) {
    return Trabajo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      precioM2: (json['precio_m2'] as num).toDouble(),
      empresaId: json['empresa_id'] as String,
      archivado: json['archivado'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio_m2': precioM2,
      'empresa_id': empresaId,
      'archivado': archivado,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Trabajo copyWith({
    String? id,
    String? nombre,
    double? precioM2,
    String? empresaId,
    bool? archivado,
    DateTime? createdAt,
  }) {
    return Trabajo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precioM2: precioM2 ?? this.precioM2,
      empresaId: empresaId ?? this.empresaId,
      archivado: archivado ?? this.archivado,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double calcularPrecio(double ancho, double alto, int cantidad, double adicional) {
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
