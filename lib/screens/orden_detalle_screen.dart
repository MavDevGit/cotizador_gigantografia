import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

class OrdenDetalleScreen extends StatefulWidget {
  final OrdenTrabajo orden;
  const OrdenDetalleScreen({super.key, required this.orden});

  @override
  _OrdenDetalleScreenState createState() => _OrdenDetalleScreenState();
}

class _OrdenDetalleScreenState extends State<OrdenDetalleScreen> {
  late OrdenTrabajo _ordenEditable;
  final List<String> _estados = [
    'pendiente',
    'en_proceso',
    'terminado',
    'entregado'
  ];
  final _formKey = GlobalKey<FormState>();

  // Controllers to update TextFields when state changes
  late TextEditingController _totalPersonalizadoController;
  late TextEditingController _adelantoController;

  @override
  void initState() {
    super.initState();
    // Clone the order for local editing to avoid modifying the original object directly
    // NOTE: NO clonamos archivos porque se manejan directamente por el widget ArchivosAdjuntosWidget
    _ordenEditable = OrdenTrabajo(
      id: widget.orden.id,
      cliente: widget.orden.cliente,
      trabajos: List<OrdenTrabajoTrabajo>.from(widget.orden.trabajos.map((t) =>
          OrdenTrabajoTrabajo(
              id: t.id,
              trabajo: t.trabajo,
              ancho: t.ancho,
              alto: t.alto,
              cantidad: t.cantidad,
              adicional: t.adicional))),
      historial: List<OrdenHistorial>.from(widget.orden.historial),
      adelanto: widget.orden.adelanto,
      totalPersonalizado: widget.orden.totalPersonalizado,
      notas: widget.orden.notas,
      estado: widget.orden.estado,
      fechaEntrega: widget.orden.fechaEntrega,
      horaEntrega: widget.orden.horaEntrega,
      creadoEn: widget.orden.creadoEn,
      creadoPorUsuarioId: widget.orden.creadoPorUsuarioId,
      archivos: widget.orden.archivos, // Referencia directa, no copia
    );

    _totalPersonalizadoController =
        TextEditingController(text: _ordenEditable.totalPersonalizado?.toString() ?? '');
    _adelantoController =
        TextEditingController(text: _ordenEditable.adelanto.toString());
  }

  @override
  void dispose() {
    _totalPersonalizadoController.dispose();
    _adelantoController.dispose();
    super.dispose();
  }

  void _guardarCambios() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // NO modificar widget.orden directamente.
      // Enviar la copia editable al AppState para que se encargue de la lógica.
      Provider.of<AppState>(context, listen: false)
          .updateOrden(_ordenEditable, "Orden actualizada.");
      Navigator.pop(context, true); // Return true to indicate changes were made
    }
  }

  Future<void> _generatePDF(String type) async {
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
          pdfBytes = await PDFGenerator.generateOrdenTrabajo(_ordenEditable);
          fileName = 'orden_trabajo_${_ordenEditable.id.substring(0, 8)}.pdf';
          break;
        case 'proforma':
          pdfBytes = await PDFGenerator.generateProforma(_ordenEditable);
          fileName = 'proforma_${_ordenEditable.id.substring(0, 8)}.pdf';
          break;
        case 'nota_venta':
          pdfBytes = await PDFGenerator.generateNotaVenta(_ordenEditable);
          fileName = 'nota_venta_${_ordenEditable.id.substring(0, 8)}.pdf';
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

  void _showEditTrabajoDialog(OrdenTrabajoTrabajo trabajo, int index) {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
        context: context,
        builder: (_) => TrabajoFormDialog(
              trabajoEnOrden: trabajo,
              availableTrabajos: appState.trabajos,
              onSave: (editedTrabajo) {
                setState(() {
                  _ordenEditable.trabajos[index] = editedTrabajo;
                  _ordenEditable.totalPersonalizado = null;
                  _totalPersonalizadoController.clear();
                });
              },
            ));
  }

  void _showAddTrabajoDialog() {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
        context: context,
        builder: (_) => TrabajoFormDialog(
              onSave: (nuevoTrabajo) {
                setState(() {
                  _ordenEditable.trabajos.add(nuevoTrabajo);
                  _ordenEditable.totalPersonalizado = null;
                  _totalPersonalizadoController.clear();
                });
              },
              availableTrabajos: appState.trabajos,
            ));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detalle Orden #${_ordenEditable.id.substring(0, 4)}'),
          actions: [
            // Menú de PDF
            PopupMenuButton<String>(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: "Generar PDF",
              onSelected: (String result) async {
                await _generatePDF(result);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'orden_trabajo',
                  child: Row(
                    children: [
                      Icon(Icons.work_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Orden de Trabajo'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'proforma',
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Proforma'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'nota_venta',
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Nota de Venta'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: "Eliminar Orden",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar Eliminación'),
                    content: const Text(
                        '¿Estás seguro de que deseas eliminar esta orden de trabajo? Esta acción no se puede deshacer.'),
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

                if (confirm == true) {
                  await Provider.of<AppState>(context, listen: false)
                      .deleteOrden(_ordenEditable.id);
                  Navigator.of(context).pop(true); // Indicar que se eliminó
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarCambios,
              tooltip: "Guardar Cambios",
            )
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.edit_document), text: "Detalles"),
              Tab(icon: Icon(Icons.history), text: "Historial"),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            children: [
              _buildDetallesTab(appState),
              _buildHistorialTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetallesTab(AppState appState) {
    // Filtrar clientes únicos manualmente
    final uniqueClientes = <String, Cliente>{};
    for (var cliente in appState.clientes) {
      uniqueClientes[cliente.id] = cliente;
    }
    final clientesUnicos = uniqueClientes.values.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- CLIENT AND STATUS SECTION ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<Cliente>(
                  value: clientesUnicos.firstWhere(
                      (c) => c.id == _ordenEditable.cliente.id,
                      orElse: () => _ordenEditable.cliente),
                  decoration: const InputDecoration(
                      labelText: 'Cliente', border: OutlineInputBorder()),
                  items: clientesUnicos.asMap().entries.map((entry) {
                    int index = entry.key;
                    Cliente c = entry.value;
                    return DropdownMenuItem(
                        key: Key(
                            'cliente_edit_${c.id}_$index'), // Key único con índice
                        value: c,
                        child: Text(c.nombre));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null)
                      setState(() => _ordenEditable.cliente = val);
                  },
                ),
                FormSpacing.verticalMedium(),
                DropdownButtonFormField<String>(
                  value: _ordenEditable.estado,
                  decoration: const InputDecoration(
                      labelText: 'Estado de la Orden',
                      border: OutlineInputBorder()),
                  items: _estados.asMap().entries.map((entry) {
                    int index = entry.key;
                    String e = entry.value;
                    return DropdownMenuItem(
                        key: Key('estado_${e}_$index'), // Key único con índice
                        value: e,
                        child: Text(e.toUpperCase()));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _ordenEditable.estado = val);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // --- JOBS SECTION ---
        Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    Text('Trabajos', style: Theme.of(context).textTheme.titleLarge),
              ),
              ..._ordenEditable.trabajos.map((trabajo) {
                int index = _ordenEditable.trabajos.indexOf(trabajo);
                return ListTile(
                  title: Text(trabajo.trabajo.nombre),
                  subtitle: Text(
                      '${trabajo.ancho}x${trabajo.alto}m - ${trabajo.cantidad} uni.'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Bs ${trabajo.precioFinal.toStringAsFixed(2)}'),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: UIUtils.getErrorColor(context),
                        ),
                        onPressed: () {
                          setState(() {
                            _ordenEditable.trabajos.removeAt(index);
                            _ordenEditable.totalPersonalizado = null;
                            _totalPersonalizadoController.clear();
                          });
                        },
                      )
                    ],
                  ),
                  onTap: () => _showEditTrabajoDialog(trabajo, index),
                );
              }).toList(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("Añadir Trabajo"),
                  onPressed: _showAddTrabajoDialog,
                ),
              )
            ],
          ),
        )),
        const SizedBox(height: 16),
        // --- FINANCIAL SECTION ---
        _buildFinancialDetails(),
        const SizedBox(height: 16),
        // --- DELIVERY DATE AND TIME SECTION ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha y Hora de Entrega',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                // Fecha y hora de entrega - Responsive
                ResponsiveLayout(
                  mobile: Column(
                    children: [
                      // Fecha en móvil
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: UIUtils.cardDecoration(context),
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _ordenEditable.fechaEntrega,
                              firstDate: DateTime(
                                  2020, 1, 1), // Permite fechas desde 2020
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                              locale: const Locale('es', 'ES'), // Español
                              // Configurar el primer día de la semana como lunes
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    datePickerTheme: DatePickerThemeData(
                                      // Configurar que la semana inicie con lunes
                                      dayOverlayColor:
                                          MaterialStateProperty.all(
                                              Colors.transparent),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(
                                  () => _ordenEditable.fechaEntrega = picked);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color:
                                      Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha de Entrega',
                                      style: UIUtils.getSubtitleStyle(context),
                                    ),
                                    Text(
                                      DateTimeUtils.formatDate(_ordenEditable.fechaEntrega),
                                      style: UIUtils.getTitleStyle(context).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      FormSpacing.verticalMedium(),
                      // Hora en móvil
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: UIUtils.cardDecoration(context),
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _ordenEditable.horaEntrega,
                            );
                            if (picked != null) {
                              setState(
                                  () => _ordenEditable.horaEntrega = picked);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  color:
                                      Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hora de Entrega',
                                      style: UIUtils.getSubtitleStyle(context),
                                    ),
                                    Text(
                                      DateTimeUtils.formatTime(_ordenEditable.horaEntrega),
                                      style: UIUtils.getTitleStyle(context).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  tablet: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: UIUtils.cardDecoration(context),
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _ordenEditable.fechaEntrega,
                                firstDate: DateTime(
                                    2020, 1, 1), // Permite fechas desde 2020
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                                locale: const Locale('es', 'ES'), // Español
                                // Configurar el primer día de la semana como lunes
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      datePickerTheme: DatePickerThemeData(
                                        // Configurar que la semana inicie con lunes
                                        dayOverlayColor:
                                            MaterialStateProperty.all(
                                                Colors.transparent),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() =>
                                    _ordenEditable.fechaEntrega = picked);
                              }
                            },
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fecha de Entrega',
                                        style: UIUtils.getSubtitleStyle(context),
                                      ),
                                      Text(
                                        DateFormat(
                                                'EEEE, d \'de\' MMMM \'de\' yyyy',
                                                'es_ES')
                                            .format(
                                                _ordenEditable.fechaEntrega),
                                        style: UIUtils.getTitleStyle(context).copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      FormSpacing.horizontalMedium(),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: UIUtils.cardDecoration(context),
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _ordenEditable.horaEntrega,
                              );
                              if (picked != null) {
                                setState(() =>
                                    _ordenEditable.horaEntrega = picked);
                              }
                            },
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hora de Entrega',
                                        style: UIUtils.getSubtitleStyle(context),
                                      ),
                                      Text(
                                        DateTimeUtils.formatTime(_ordenEditable.horaEntrega),
                                        style: UIUtils.getTitleStyle(context).copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // --- NOTES SECTION ---
        TextFormField(
          initialValue: _ordenEditable.notas,
          decoration: const InputDecoration(
              labelText: 'Notas', border: OutlineInputBorder()),
          maxLines: 3,
          onSaved: (value) => _ordenEditable.notas = value,
        ),
        FormSpacing.verticalLarge(),

        // --- ARCHIVOS ADJUNTOS SECTION ---
        ArchivosAdjuntosWidget(orden: widget.orden),
        FormSpacing.verticalLarge(),

        // --- SAVE BUTTON ---
        ElevatedButton.icon(
          icon: const Icon(Icons.save_rounded),
          label: const Text('Guardar Cambios'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          onPressed: _guardarCambios,
        ),
        FormSpacing.verticalMedium(),
      ],
    );
  }

  Widget _buildHistorialTab() {
    if (_ordenEditable.historial.isEmpty) {
      return Center(child: Text("No hay historial para esta orden."));
    }
    return ListView.builder(
      itemCount: _ordenEditable.historial.length,
      itemBuilder: (context, index) {
        final evento =
            _ordenEditable.historial.reversed.toList()[index]; // Show newest first
        return ListTile(
          leading: Icon(Icons.info_outline),
          title: Text(evento.cambio),
          subtitle: Text('Por: ${evento.usuarioNombre}'),
          // Formatear fecha y hora en español
          trailing: Text(
              DateTimeUtils.formatDateTime(evento.timestamp.toLocal())),
        );
      },
    );
  }

  Card _buildFinancialDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _financialRow(
                'Total Bruto:', '\$${_ordenEditable.totalBruto.toStringAsFixed(2)}'),
            FormSpacing.verticalMedium(),
            TextFormField(
              controller: _totalPersonalizadoController,
              decoration:
                  const InputDecoration(labelText: 'Total Personalizado (Bs)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              onChanged: (value) {
                setState(() {
                  _ordenEditable.totalPersonalizado = double.tryParse(value);
                });
              },
              onSaved: (value) {
                _ordenEditable.totalPersonalizado = double.tryParse(value ?? '');
              },
            ),
            FormSpacing.verticalSmall(),
            _financialRow('Rebaja:',
                '\$${_ordenEditable.rebaja > 0 ? _ordenEditable.rebaja.toStringAsFixed(2) : '0.00'}'),
            const Divider(height: 24),
            _financialRow(
                'Total Final:', '\$${_ordenEditable.total.toStringAsFixed(2)}',
                isTotal: true),
            FormSpacing.verticalMedium(),
            TextFormField(
              controller: _adelantoController,
              decoration: const InputDecoration(labelText: 'Adelanto (Bs)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              onChanged: (value) {
                setState(() {
                  _ordenEditable.adelanto = double.tryParse(value) ?? 0.0;
                });
              },
              onSaved: (value) {
                _ordenEditable.adelanto = double.tryParse(value!) ?? 0.0;
              },
            ),
            FormSpacing.verticalSmall(),
            _financialRow('Saldo Pendiente:',
                '\$${_ordenEditable.saldo.toStringAsFixed(2)}',
                isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _financialRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: isTotal 
                ? UIUtils.getTitleStyle(context).copyWith(fontWeight: FontWeight.bold)
                : UIUtils.getTitleStyle(context),
          ),
          Text(
            value, 
            style: isTotal 
                ? UIUtils.getPriceStyle(context, isLarge: true)
                : UIUtils.getPriceStyle(context),
          ),
        ],
      ),
    );
  }
}
