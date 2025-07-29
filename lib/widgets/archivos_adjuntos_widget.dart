
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';
import 'widgets.dart';

class ArchivosAdjuntosWidget extends StatefulWidget {
  final OrdenTrabajo orden;
  final bool isReadOnly;

  const ArchivosAdjuntosWidget({
    super.key,
    required this.orden,
    this.isReadOnly = false,
  });

  @override
  State<ArchivosAdjuntosWidget> createState() => _ArchivosAdjuntosWidgetState();
}

class _ArchivosAdjuntosWidgetState extends State<ArchivosAdjuntosWidget> {
  bool _isLoading = false;

  Future<void> _adjuntarArchivos() async {
    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = appState.currentUser!;

      final archivos = await ArchivoService.seleccionarArchivos(
        user.id,
        user.nombre,
      );

      if (archivos.isNotEmpty) {
        await appState.addArchivosAOrden(widget.orden.id, archivos);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Se agregaron ${archivos.length} archivo(s) adjunto(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al adjuntar archivos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminarArchivo(ArchivoAdjunto archivo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content:
            Text('¿Está seguro de que desea eliminar el archivo "${archivo.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.removeArchivoDeOrden(widget.orden.id, archivo);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Archivo eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar archivo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _abrirArchivo(ArchivoAdjunto archivo) async {
    try {
      final tipoMime = archivo.tipoMime ?? '';
      if (tipoMime.startsWith('image/')) {
        // Para imágenes, abrir el visor de galería
        final imagenes = widget.orden.archivos
            .where((a) => (a.tipoMime ?? '').startsWith('image/'))
            .cast<ArchivoAdjunto>()
            .toList();
        final initialIndex = imagenes.indexOf(archivo);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ImageViewer(
                imagenes: imagenes,
                initialIndex: initialIndex >= 0 ? initialIndex : 0,
              ),
            ),
          );
        }
      } else {
        // Para otros tipos de archivos, abrir con aplicación externa
        final success = await ArchivoService.abrirArchivo(archivo);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el archivo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDetallesArchivo(ArchivoAdjunto archivo) async {
    final existeArchivo = await archivo.exists();
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(_getFileIcon(archivo), size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  archivo.nombre,
                  style: TextStyle(fontSize: isMobile ? 16 : 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetalleRow('Tipo:', archivo.tipoArchivo ?? 'No especificado'),
                _buildDetalleRow('Tamaño:', archivo.tamanoFormateado),
                _buildDetalleRow('Fecha:',
                    DateFormat('dd/MM/yyyy HH:mm').format(archivo.fechaSubida)),
                _buildDetalleRow('Subido por:', archivo.subidoPorUsuarioNombre),
                _buildDetalleRow(
                    'Estado:', existeArchivo ? 'Disponible' : 'Archivo no encontrado'),
                if (archivo.descripcion != null &&
                    archivo.descripcion!.isNotEmpty)
                  _buildDetalleRow('Descripción:', archivo.descripcion!),
              ],
            ),
          ),
          actions: [
            if (existeArchivo)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _abrirArchivo(archivo);
                },
                icon: Icon(Icons.open_in_new, size: isMobile ? 16 : 20),
                label: Text(
                  'Abrir',
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getFileTypeColor(String tipoMime) {
    if (tipoMime.startsWith('image/')) {
      return Colors.purple;
    } else if (tipoMime.startsWith('video/')) {
      return Colors.red;
    } else if (tipoMime.startsWith('audio/')) {
      return Colors.orange;
    } else if (tipoMime.contains('pdf')) {
      return Colors.red.shade700;
    } else if (tipoMime.contains('word') || tipoMime.contains('document')) {
      return Colors.blue;
    } else if (tipoMime.contains('excel') ||
        tipoMime.contains('spreadsheet')) {
      return Colors.green;
    } else if (tipoMime.contains('presentation')) {
      return Colors.orange.shade700;
    } else if (tipoMime.startsWith('text/')) {
      return Colors.grey.shade700;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildDetalleRow(String label, String value) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 6.0 : 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 80 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Archivos Adjuntos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 18 : null,
                        ),
                  ),
                ),
                if (!widget.isReadOnly)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _adjuntarArchivos,
                    icon: _isLoading
                        ? SizedBox(
                            width: isMobile ? 14 : 16,
                            height: isMobile ? 14 : 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.attach_file_rounded,
                            size: isMobile ? 16 : 20),
                    label: Text(isMobile ? 'Adjuntar' : 'Adjuntar'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 8,
                      ),
                      textStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            if (widget.orden.archivos.isEmpty)
              Container(
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: isMobile ? 48 : 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'No hay archivos adjuntos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: isMobile ? 14 : null,
                          ),
                    ),
                    if (!widget.isReadOnly) ...[
                      SizedBox(height: isMobile ? 6 : 8),
                      Text(
                        'Haga clic en "Adjuntar" para agregar archivos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 12 : null,
                            ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Column(
                children: widget.orden.archivos.map((archivo) {
                  return Container(
                    margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: isMobile ? 4 : 8,
                      ),
                      leading: archivo.tipoMime.startsWith('image/')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: isMobile ? 40 : 50,
                                height: isMobile ? 40 : 50,
                                child: Image.file(
                                  File(archivo.rutaArchivo),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      child: Icon(
                                        archivo.icono,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: isMobile ? 18 : 24,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                          : CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              radius: isMobile ? 20 : 25,
                              child: Icon(
                                archivo.icono,
                                color: Theme.of(context).colorScheme.primary,
                                size: isMobile ? 18 : 24,
                              ),
                            ),
                      title: Text(
                        archivo.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 13 : 14,
                        ),
                        maxLines: isMobile ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isMobile ? 2 : 4),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 6 : 8,
                                  vertical: isMobile ? 1 : 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getFileTypeColor(archivo.tipoMime)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  archivo.tipoArchivo,
                                  style: TextStyle(
                                    color: _getFileTypeColor(archivo.tipoMime),
                                    fontSize: isMobile ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: isMobile ? 4 : 8),
                              Text(
                                archivo.tamanoFormateado,
                                style: TextStyle(fontSize: isMobile ? 11 : 12),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 1 : 2),
                          Text(
                            'Subido por ${archivo.subidoPorUsuarioNombre} • ${DateFormat('dd/MM/yyyy HH:mm').format(archivo.fechaSubida)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: isMobile
                          ? PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, size: 18),
                              onSelected: (value) {
                                switch (value) {
                                  case 'open':
                                    _abrirArchivo(archivo);
                                    break;
                                  case 'info':
                                    _mostrarDetallesArchivo(archivo);
                                    break;
                                  case 'delete':
                                    if (!widget.isReadOnly) {
                                      _eliminarArchivo(archivo);
                                    }
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'open',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility_rounded, size: 16),
                                      SizedBox(width: 8),
                                      Text('Abrir'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'info',
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded,
                                          size: 16),
                                      SizedBox(width: 8),
                                      Text('Detalles'),
                                    ],
                                  ),
                                ),
                                if (!widget.isReadOnly)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_rounded,
                                            size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Eliminar',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_rounded),
                                  onPressed: () => _abrirArchivo(archivo),
                                  tooltip: 'Abrir archivo',
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.info_outline_rounded),
                                  onPressed: () =>
                                      _mostrarDetallesArchivo(archivo),
                                  tooltip: 'Ver detalles',
                                ),
                                if (!widget.isReadOnly)
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded,
                                        color: Colors.red),
                                    onPressed: () => _eliminarArchivo(archivo),
                                    tooltip: 'Eliminar',
                                  ),
                              ],
                            ),
                      onTap: () => _abrirArchivo(archivo),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(ArchivoAdjunto archivo) {
    final tipoMime = archivo.tipoMime ?? '';
    if (tipoMime.startsWith('image/')) {
      return Icons.image;
    } else if (tipoMime.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (tipoMime.contains('word') || tipoMime.contains('document')) {
      return Icons.description;
    } else if (tipoMime.contains('excel') || tipoMime.contains('spreadsheet')) {
      return Icons.table_chart;
    } else {
      return Icons.insert_drive_file;
    }
  }
}
