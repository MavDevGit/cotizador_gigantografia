// Modelo para ítem de orden de trabajo adaptado a Supabase
class OrdenTrabajoItem {
  final int? id; // Puede ser null para nuevos ítems
  final String ordenId;
  final String trabajoNombre;
  final double trabajoPrecioM2;
  final double ancho;
  final double alto;
  final int cantidad;
  final double adicional;

  OrdenTrabajoItem({
    this.id,
    required this.ordenId,
    required this.trabajoNombre,
    required this.trabajoPrecioM2,
    required this.ancho,
    required this.alto,
    required this.cantidad,
    this.adicional = 0.0,
  });

  factory OrdenTrabajoItem.fromJson(Map<String, dynamic> json) {
    return OrdenTrabajoItem(
      id: json['id'] as int?,
      ordenId: json['orden_id'] as String,
      trabajoNombre: json['trabajo_nombre'] as String,
      trabajoPrecioM2: (json['trabajo_precio_m2'] as num).toDouble(),
      ancho: (json['ancho'] as num).toDouble(),
      alto: (json['alto'] as num).toDouble(),
      cantidad: json['cantidad'] as int,
      adicional: (json['adicional'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id != null) 'id': id,
      'orden_id': ordenId,
      'trabajo_nombre': trabajoNombre,
      'trabajo_precio_m2': trabajoPrecioM2,
      'ancho': ancho,
      'alto': alto,
      'cantidad': cantidad,
      'adicional': adicional,
    };
  }

  OrdenTrabajoItem copyWith({
    int? id,
    String? ordenId,
    String? trabajoNombre,
    double? trabajoPrecioM2,
    double? ancho,
    double? alto,
    int? cantidad,
    double? adicional,
  }) {
    return OrdenTrabajoItem(
      id: id ?? this.id,
      ordenId: ordenId ?? this.ordenId,
      trabajoNombre: trabajoNombre ?? this.trabajoNombre,
      trabajoPrecioM2: trabajoPrecioM2 ?? this.trabajoPrecioM2,
      ancho: ancho ?? this.ancho,
      alto: alto ?? this.alto,
      cantidad: cantidad ?? this.cantidad,
      adicional: adicional ?? this.adicional,
    );
  }

  double get precioFinal => (ancho * alto * trabajoPrecioM2 * cantidad) + adicional;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrdenTrabajoItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
