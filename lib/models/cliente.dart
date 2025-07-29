// Modelo para Cliente adaptado a Supabase
class Cliente {
  final String id;
  String nombre;
  String? email;
  String? celular;
  String? notas;
  final String empresaId;
  final String authUserId;
  final bool archivado;
  final DateTime createdAt;

  // Para compatibilidad con código existente
  String? get contacto => celular;
  set contacto(String? value) => celular = value;

  DateTime get creadoEn => createdAt;

  Cliente({
    required this.id,
    required this.nombre,
    this.email,
    this.celular,
    this.notas,
    required this.empresaId,
    required this.authUserId,
    this.archivado = false,
    required this.createdAt,
  });

  // Constructor alternativo para compatibilidad
  Cliente.legacy({
    required this.id,
    required this.nombre,
    this.email,
    String? contacto, // Para compatibilidad
    this.notas,
    required this.empresaId,
    required this.authUserId,
    this.archivado = false,
    required this.createdAt,
  }) : celular = contacto;

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String?,
      celular: json['celular'] as String?,
      notas: json['notas'] as String?,
      empresaId: json['empresa_id'] as String,
      authUserId: json['auth_user_id'] as String,
      archivado: json['archivado'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'celular': celular,
      'notas': notas,
      'empresa_id': empresaId,
      'auth_user_id': authUserId,
      'archivado': archivado,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Cliente copyWith({
    String? id,
    String? nombre,
    String? email,
    String? celular,
    String? notas,
    String? empresaId,
    String? authUserId,
    bool? archivado,
    DateTime? createdAt,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      celular: celular ?? this.celular,
      notas: notas ?? this.notas,
      empresaId: empresaId ?? this.empresaId,
      authUserId: authUserId ?? this.authUserId,
      archivado: archivado ?? this.archivado,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cliente && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
