import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';
import 'screens.dart';

class OrdenesTrabajoScreen extends StatefulWidget {
  const OrdenesTrabajoScreen({super.key});

  @override
  _OrdenesTrabajoScreenState createState() => _OrdenesTrabajoScreenState();
}

class _OrdenesTrabajoScreenState extends State<OrdenesTrabajoScreen> {
  String _searchQuery = '';
  String?
      _selectedFilter; // null = mostrar todas, 'pendiente', 'en_proceso', 'terminado', 'por_entregar'

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    var ordenes = appState.ordenes.where((orden) {
      return orden.cliente.nombre
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    // Aplicar filtro por estado
    if (_selectedFilter != null) {
      switch (_selectedFilter) {
        case 'pendiente':
          ordenes = ordenes.where((o) => o.estado == 'pendiente').toList();
          break;
        case 'en_proceso':
          ordenes = ordenes.where((o) => o.estado == 'en_proceso').toList();
          break;
        case 'terminado':
          ordenes = ordenes.where((o) => o.estado == 'terminado').toList();
          break;
        case 'por_entregar':
          ordenes = ordenes
              .where((o) => o.estado == 'terminado' && o.estado != 'entregado')
              .toList();
          break;
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          children: [
            _buildStatsCards(
                appState.ordenes), // Pasamos todas las órdenes para el conteo
            if (_selectedFilter != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = null;
                      });
                    },
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: const Text('Limpiar filtros'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            FormSpacing.verticalMedium(),
            // Barra de búsqueda
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por cliente...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                fillColor: Theme.of(context).colorScheme.surface,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintStyle: UIUtils.getSubtitleStyle(context),
              ),
              style: UIUtils.getTitleStyle(context),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            FormSpacing.verticalSmall(),
            // Lista de órdenes
            if (ordenes.isEmpty)
              _buildEmptyState()
            else
              ...ordenes.map((orden) => Dismissible(
                    key: Key(orden.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar Eliminación'),
                          content: const Text(
                              '¿Estás seguro de que deseas eliminar esta orden de trabajo?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Eliminar'),
                              style: TextButton.styleFrom(
                                foregroundColor: UIUtils.getErrorColor(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      Provider.of<AppState>(context, listen: false)
                          .deleteOrden(orden.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Orden #${orden.id.substring(0, 6)} eliminada')),
                      );
                    },
                    background: Container(
                      color: UIUtils.getErrorColor(context),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(
                        Icons.delete, 
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                    child: _buildOrderCard(orden),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(List<OrdenTrabajo> ordenes) {
    final pendientes = ordenes.where((o) => o.estado == 'pendiente').length;
    final enProceso = ordenes.where((o) => o.estado == 'en_proceso').length;
    final terminadas = ordenes.where((o) => o.estado == 'terminado').length;
    final porEntregar = ordenes
        .where((o) => o.estado == 'terminado' && o.estado != 'entregado')
        .length;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final spacing = isMobile ? 4.0 : 6.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildStatCard('Pendientes', pendientes.toString(),
                    UIUtils.getWarningColor(context), 'pendiente')),
            SizedBox(width: spacing),
            Expanded(
                child: _buildStatCard('En Proceso', enProceso.toString(),
                    UIUtils.getInfoColor(context), 'en_proceso')),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(
                child: _buildStatCard('Terminadas', terminadas.toString(),
                    UIUtils.getSuccessColor(context), 'terminado')),
            SizedBox(width: spacing),
            Expanded(
                child: _buildStatCard('Por Entregar', porEntregar.toString(),
                    UIUtils.getErrorColor(context), 'por_entregar')),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, String filterKey) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSelected = _selectedFilter == filterKey;

    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = _selectedFilter == filterKey ? null : filterKey;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected ? Border.all(color: color, width: 2) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.filter_alt_rounded,
                        size: 16,
                        color: color,
                      ),
                  ],
                ),
                SizedBox(height: isMobile ? 4 : 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrdenTrabajo orden) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OrdenDetalleScreen(orden: orden)),
          );
          if (result == true) {
            setState(() {});
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orden.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(orden.estado),
                      color: _getStatusColor(orden.estado),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden #${orden.id.substring(0, isMobile ? 6 : 8)}',
                          style: UIUtils.getTitleStyle(context).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          orden.cliente.nombre,
                          style: UIUtils.getSubtitleStyle(context).copyWith(
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Botón PDF
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.picture_as_pdf, 
                      color: UIUtils.getErrorColor(context),
                    ),
                    tooltip: "Generar PDF",
                    onSelected: (String result) async {
                      await _generateOrderPDF(orden, result);
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'orden_trabajo',
                        child: Row(
                          children: [
                            Icon(Icons.work_outline, size: 16),
                            SizedBox(width: 8),
                            Text('Orden de Trabajo',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'proforma',
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Proforma', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'nota_venta',
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Nota de Venta',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orden.estado),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(orden.estado),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Información financiera - Responsive
              ResponsiveLayout(
                mobile: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: UIUtils.getSubtitleStyle(context).copyWith(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Bs ${orden.total.toStringAsFixed(2)}',
                              style: UIUtils.getPriceStyle(context).copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Saldo',
                              style: UIUtils.getSubtitleStyle(context).copyWith(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Bs ${orden.saldo.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: orden.saldo > 0
                                    ? UIUtils.getWarningColor(context)
                                    : UIUtils.getSuccessColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16, 
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Entrega: ${DateTimeUtils.formatDate(orden.fechaEntrega)}',
                          style: UIUtils.getSubtitleStyle(context).copyWith(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 16, 
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateTimeUtils.formatTime(orden.horaEntrega),
                          style: UIUtils.getSubtitleStyle(context).copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                tablet: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: UIUtils.getSubtitleStyle(context).copyWith(
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Bs ${orden.total.toStringAsFixed(2)}',
                          style: UIUtils.getPriceStyle(context).copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Saldo',
                          style: UIUtils.getSubtitleStyle(context).copyWith(
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Bs ${orden.saldo.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: orden.saldo > 0 
                                ? UIUtils.getWarningColor(context) 
                                : UIUtils.getSuccessColor(context),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Entrega',
                          style: UIUtils.getSubtitleStyle(context).copyWith(
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${orden.fechaEntrega.day}/${orden.fechaEntrega.month}',
                          style: UIUtils.getTitleStyle(context).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          orden.horaEntrega.format(context),
                          style: UIUtils.getSubtitleStyle(context).copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateOrderPDF(OrdenTrabajo orden, String type) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      Uint8List pdfBytes;
      String fileName;

      switch (type) {
        case 'orden_trabajo':
          pdfBytes = await PDFGenerator.generateOrdenTrabajo(orden);
          fileName = 'orden_trabajo_${orden.id.substring(0, 8)}.pdf';
          break;
        case 'proforma':
          pdfBytes = await PDFGenerator.generateProforma(orden);
          fileName = 'proforma_${orden.id.substring(0, 8)}.pdf';
          break;
        case 'nota_venta':
          pdfBytes = await PDFGenerator.generateNotaVenta(orden);
          fileName = 'nota_venta_${orden.id.substring(0, 8)}.pdf';
          break;
        default:
          Navigator.pop(context); // Cerrar loading
          return;
      }

      Navigator.pop(context); // Cerrar loading

      // Compartir el PDF usando la funcionalidad nativa de Android
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (e) {
      Navigator.pop(context); // Cerrar loading en caso de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            FormSpacing.verticalLarge(),
            Text(
              'No se encontraron órdenes',
              style: UIUtils.getTitleStyle(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            FormSpacing.verticalSmall(),
            Text(
              'Crea una nueva orden desde la pestaña Cotizar',
              style: UIUtils.getSubtitleStyle(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'PENDIENTE';
      case 'en_proceso':
        return 'EN PROCESO';
      case 'terminado':
        return 'TERMINADO';
      case 'entregado':
        return 'ENTREGADO';
      default:
        return estado.toUpperCase();
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.hourglass_empty_rounded;
      case 'en_proceso':
        return Icons.work_rounded;
      case 'terminado':
        return Icons.check_circle_rounded;
      case 'entregado':
        return Icons.local_shipping_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return UIUtils.getWarningColor(context);
      case 'en_proceso':
        return UIUtils.getInfoColor(context);
      case 'terminado':
        return UIUtils.getSuccessColor(context);
      case 'entregado':
        return Theme.of(context).colorScheme.onSurfaceVariant;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }
}
