// Modelo para Usuario adaptado a Supabase
class Usuario {
  final String id;
  final String authUserId;
  final String empresaId;
  final String email;
  final String nombre;
  final String rol; // 'admin' o 'empleado'
  final bool archivado;
  final DateTime createdAt;

  Usuario({
    required this.id,
    required this.authUserId,
    required this.empresaId,
    required this.email,
    required this.nombre,
    required this.rol,
    this.archivado = false,
    required this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String,
      empresaId: json['empresa_id'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      rol: json['rol'] as String,
      archivado: json['archivado'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'empresa_id': empresaId,
      'email': email,
      'nombre': nombre,
      'rol': rol,
      'archivado': archivado,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Usuario copyWith({
    String? id,
    String? authUserId,
    String? empresaId,
    String? email,
    String? nombre,
    String? rol,
    bool? archivado,
    DateTime? createdAt,
  }) {
    return Usuario(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      empresaId: empresaId ?? this.empresaId,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      archivado: archivado ?? this.archivado,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Para compatibilidad con código existente
  String get negocioId => empresaId;
}
