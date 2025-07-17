
import 'package:hive/hive.dart';

part 'orden_historial.g.dart';

@HiveType(typeId: 5)
class OrdenHistorial extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String cambio;
  @HiveField(2)
  final String usuarioId;
  @HiveField(3)
  final String usuarioNombre;
  @HiveField(4)
  final DateTime timestamp;
  @HiveField(5)
  final String? dispositivo;
  @HiveField(6)
  final String? ip;

  OrdenHistorial({
    required this.id,
    required this.cambio,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.timestamp,
    this.dispositivo,
    this.ip,
  });
}
