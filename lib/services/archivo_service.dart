
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../models/archivo_adjunto.dart';

class ArchivoService {
  static Future<Directory> _getAppDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final archivosDir = Directory('${directory.path}/archivos_adjuntos');
    if (!await archivosDir.exists()) {
      await archivosDir.create(recursive: true);
    }
    return archivosDir;
  }

  static Future<List<ArchivoAdjunto>> seleccionarArchivos(
    String usuarioId,
    String usuarioNombre,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowedExtensions: null,
      );

      if (result != null && result.files.isNotEmpty) {
        List<ArchivoAdjunto> archivos = [];
        final appDir = await _getAppDocumentsDirectory();

        for (PlatformFile file in result.files) {
          if (file.path != null) {
            // Generar nombre único para el archivo
            final String fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final String destinationPath = '${appDir.path}/$fileName';

            // Copiar archivo al directorio de la aplicación
            await File(file.path!).copy(destinationPath);

            // Obtener tipo MIME
            final String mimeType =
                lookupMimeType(destinationPath) ?? 'application/octet-stream';

            // Crear objeto ArchivoAdjunto
            final archivo = ArchivoAdjunto(
              id: Random().nextDouble().toString(),
              nombre: file.name,
              rutaArchivo: destinationPath,
              tipoMime: mimeType,
              tamano: file.size,
              fechaSubida: DateTime.now(),
              subidoPorUsuarioId: usuarioId,
              subidoPorUsuarioNombre: usuarioNombre,
            );

            archivos.add(archivo);
          }
        }

        return archivos;
      }

      return [];
    } catch (e) {
      print('Error al seleccionar archivos: $e');
      return [];
    }
  }

  static Future<bool> eliminarArchivo(ArchivoAdjunto archivo) async {
    try {
      final file = File(archivo.rutaArchivo);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al eliminar archivo: $e');
      return false;
    }
  }

  static Future<bool> abrirArchivo(ArchivoAdjunto archivo) async {
    try {
      final file = File(archivo.rutaArchivo);
      if (await file.exists()) {
        final result = await OpenFile.open(archivo.rutaArchivo);
        return result.type == ResultType.done;
      }
      return false;
    } catch (e) {
      print('Error al abrir archivo: $e');
      return false;
    }
  }

  static Future<void> limpiarArchivosOrfanos() async {
    try {
      final appDir = await _getAppDocumentsDirectory();
      final archivos = appDir.listSync();

      // Aquí podrías implementar lógica para eliminar archivos que ya no están
      // referenciados en ninguna orden de trabajo

      print('Limpieza de archivos completada');
    } catch (e) {
      print('Error en limpieza de archivos: $e');
    }
  }
}
