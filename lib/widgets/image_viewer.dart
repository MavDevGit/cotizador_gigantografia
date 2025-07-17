
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';

class ImageViewer extends StatefulWidget {
  final List<ArchivoAdjunto> imagenes;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.imagenes,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} de ${widget.imagenes.length}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.open_in_new,
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
            onPressed: () => _abrirEnAplicacionExterna(),
            tooltip: 'Abrir con app externa',
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
            onPressed: () => _mostrarInfo(),
            tooltip: 'Información',
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.imagenes.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider:
                    FileImage(File(widget.imagenes[index].rutaArchivo)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * (isMobile ? 2.5 : 3),
                heroAttributes:
                    PhotoViewHeroAttributes(tag: widget.imagenes[index].id),
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: isMobile ? 48 : 64,
                            color: Colors.white54,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          Text(
                            'Error al cargar la imagen',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) {
              if (event == null) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: isMobile ? 2 : 4,
                  ),
                );
              }
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: isMobile ? 2 : 4,
                  value: event.expectedTotalBytes != null
                      ? event.cumulativeBytesLoaded / event.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
          // Controles de navegación
          if (widget.imagenes.length > 1)
            Positioned(
              bottom: isMobile ? 60 : 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: isMobile ? 18 : 24,
                          ),
                          onPressed: _currentIndex > 0
                              ? () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                        Text(
                          '${_currentIndex + 1} / ${widget.imagenes.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: isMobile ? 18 : 24,
                          ),
                          onPressed: _currentIndex < widget.imagenes.length - 1
                              ? () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 6.0 : 8.0,
          horizontal: isMobile ? 12.0 : 16.0,
        ),
        child: SafeArea(
          child: Text(
            widget.imagenes[_currentIndex].nombre,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 14 : 16,
            ),
            textAlign: TextAlign.center,
            maxLines: isMobile ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _abrirEnAplicacionExterna() async {
    try {
      await ArchivoService.abrirArchivo(widget.imagenes[_currentIndex]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir archivo: $e')),
      );
    }
  }

  void _mostrarInfo() {
    final archivo = widget.imagenes[_currentIndex];
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Información del archivo',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Nombre:', archivo.nombre),
              _buildInfoRow('Tipo:', archivo.tipoArchivo),
              _buildInfoRow('Tamaño:', archivo.tamanoFormateado),
              _buildInfoRow('Subido por:', archivo.subidoPorUsuarioNombre),
              _buildInfoRow('Fecha:',
                  DateFormat('dd/MM/yyyy HH:mm').format(archivo.fechaSubida)),
              if (archivo.descripcion != null)
                _buildInfoRow('Descripción:', archivo.descripcion!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
}
