
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'archivo_adjunto.g.dart';

@HiveType(typeId: 7)
class ArchivoAdjunto extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String nombre;
  @HiveField(2)
  String rutaArchivo;
  @HiveField(3)
  String tipoMime;
  @HiveField(4)
  int tamano;
  @HiveField(5)
  DateTime fechaSubida;
  @HiveField(6)
  String subidoPorUsuarioId;
  @HiveField(7)
  String subidoPorUsuarioNombre;
  @HiveField(8)
  String? descripcion;

  ArchivoAdjunto({
    required this.id,
    required this.nombre,
    required this.rutaArchivo,
    required this.tipoMime,
    required this.tamano,
    required this.fechaSubida,
    required this.subidoPorUsuarioId,
    required this.subidoPorUsuarioNombre,
    this.descripcion,
  });

  // Método para obtener el tamaño formateado
  String get tamanoFormateado {
    if (tamano < 1024) {
      return '$tamano B';
    } else if (tamano < 1024 * 1024) {
      return '${(tamano / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(tamano / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Método para obtener el tipo de archivo
  String get tipoArchivo {
    if (tipoMime.startsWith('image/')) {
      return 'Imagen';
    } else if (tipoMime.startsWith('video/')) {
      return 'Video';
    } else if (tipoMime.startsWith('audio/')) {
      return 'Audio';
    } else if (tipoMime.contains('pdf')) {
      return 'PDF';
    } else if (tipoMime.contains('word') || tipoMime.contains('document')) {
      return 'Documento';
    } else if (tipoMime.contains('excel') ||
        tipoMime.contains('spreadsheet')) {
      return 'Hoja de cálculo';
    } else if (tipoMime.contains('presentation')) {
      return 'Presentación';
    } else if (tipoMime.startsWith('text/')) {
      return 'Texto';
    } else {
      return 'Archivo';
    }
  }

  // Método para obtener el icono según el tipo
  IconData get icono {
    if (tipoMime.startsWith('image/')) {
      return Icons.image_rounded;
    } else if (tipoMime.startsWith('video/')) {
      return Icons.video_file_rounded;
    } else if (tipoMime.startsWith('audio/')) {
      return Icons.audio_file_rounded;
    } else if (tipoMime.contains('pdf')) {
      return Icons.picture_as_pdf_rounded;
    } else if (tipoMime.contains('word') || tipoMime.contains('document')) {
      return Icons.description_rounded;
    } else if (tipoMime.contains('excel') ||
        tipoMime.contains('spreadsheet')) {
      return Icons.table_chart_rounded;
    } else if (tipoMime.contains('presentation')) {
      return Icons.present_to_all_rounded;
    } else if (tipoMime.startsWith('text/')) {
      return Icons.text_snippet_rounded;
    } else {
      return Icons.attach_file_rounded;
    }
  }

  // Método para verificar si el archivo existe
  Future<bool> exists() async {
    return await File(rutaArchivo).exists();
  }
}
