import 'package:flutter/material.dart';
import 'cliente.dart';
import 'orden_trabajo_item_new.dart';

// Modelo para Orden de Trabajo adaptado a Supabase
class OrdenTrabajo {
  final String id;
  Cliente cliente;
  final String empresaId;
  final String authUserId;
  double adelanto;
  double? totalPersonalizado;
  String? notas;
  String estado;
  DateTime fechaEntrega;
  TimeOfDay horaEntrega;
  final DateTime createdAt;
  final List<OrdenTrabajoItem> items;

  // Para compatibilidad con código existente
  List<dynamic> get trabajos => items;
  set trabajos(List<dynamic> value) {
    // Convertir si es necesario - implementar según sea necesario
  }

  List<dynamic> get historial => []; // Implementar según sea necesario
  set historial(List<dynamic> value) {
    // Implementar según sea necesario
  }

  DateTime get creadoEn => createdAt;
  set creadoEn(DateTime value) {
    // No se puede cambiar porque createdAt es final
  }

  String get creadoPorUsuarioId => authUserId;
  set creadoPorUsuarioId(String value) {
    // No se puede cambiar porque authUserId es final
  }

  List<dynamic> get archivos => []; // Implementar según sea necesario
  set archivos(List<dynamic> value) {
    // Implementar según sea necesario
  }

  OrdenTrabajo({
    required this.id,
    required this.cliente,
    required this.empresaId,
    required this.authUserId,
    this.adelanto = 0.0,
    this.totalPersonalizado,
    this.notas,
    this.estado = 'pendiente',
    required this.fechaEntrega,
    required this.horaEntrega,
    required this.createdAt,
    this.items = const [],
  });

  // Constructor alternativo para compatibilidad
  OrdenTrabajo.legacy({
    required this.id,
    required this.cliente,
    required this.empresaId,
    required this.authUserId,
    this.adelanto = 0.0,
    this.totalPersonalizado,
    this.notas,
    this.estado = 'pendiente',
    required this.fechaEntrega,
    required this.horaEntrega,
    required this.createdAt,
    List<dynamic>? trabajos, // Para compatibilidad
    List<dynamic>? historial, // Para compatibilidad
    DateTime? creadoEn, // Para compatibilidad
    String? creadoPorUsuarioId, // Para compatibilidad
    List<dynamic>? archivos, // Para compatibilidad
  }) : items = trabajos?.cast<OrdenTrabajoItem>() ?? [];

  factory OrdenTrabajo.fromJson(Map<String, dynamic> json) {
    // Convertir string de hora a TimeOfDay
    final horaString = json['hora_entrega'] as String;
    final horaParts = horaString.split(':');
    final hora = TimeOfDay(
      hour: int.parse(horaParts[0]),
      minute: int.parse(horaParts[1]),
    );

    return OrdenTrabajo(
      id: json['id'] as String,
      cliente: Cliente.fromJson(json['cliente'] as Map<String, dynamic>),
      empresaId: json['empresa_id'] as String,
      authUserId: json['auth_user_id'] as String,
      adelanto: (json['adelanto'] as num?)?.toDouble() ?? 0.0,
      totalPersonalizado: (json['total_personalizado'] as num?)?.toDouble(),
      notas: json['notas'] as String?,
      estado: json['estado'] as String? ?? 'pendiente',
      fechaEntrega: DateTime.parse(json['fecha_entrega'] as String),
      horaEntrega: hora,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrdenTrabajoItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    // Convertir TimeOfDay a string
    final horaString = '${horaEntrega.hour.toString().padLeft(2, '0')}:${horaEntrega.minute.toString().padLeft(2, '0')}:00';

    return {
      'id': id,
      'cliente_id': cliente.id,
      'empresa_id': empresaId,
      'auth_user_id': authUserId,
      'adelanto': adelanto,
      'total_personalizado': totalPersonalizado,
      'notas': notas,
      'estado': estado,
      'fecha_entrega': fechaEntrega.toIso8601String().split('T')[0], // Solo fecha
      'hora_entrega': horaString,
      'created_at': createdAt.toIso8601String(),
    };
  }

  OrdenTrabajo copyWith({
    String? id,
    Cliente? cliente,
    String? empresaId,
    String? authUserId,
    double? adelanto,
    double? totalPersonalizado,
    String? notas,
    String? estado,
    DateTime? fechaEntrega,
    TimeOfDay? horaEntrega,
    DateTime? createdAt,
    List<OrdenTrabajoItem>? items,
  }) {
    return OrdenTrabajo(
      id: id ?? this.id,
      cliente: cliente ?? this.cliente,
      empresaId: empresaId ?? this.empresaId,
      authUserId: authUserId ?? this.authUserId,
      adelanto: adelanto ?? this.adelanto,
      totalPersonalizado: totalPersonalizado ?? this.totalPersonalizado,
      notas: notas ?? this.notas,
      estado: estado ?? this.estado,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      horaEntrega: horaEntrega ?? this.horaEntrega,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  double get totalBruto => items.fold(0.0, (prev, item) => prev + item.precioFinal);

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrdenTrabajo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
