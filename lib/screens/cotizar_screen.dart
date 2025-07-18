
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import 'screens.dart';

class CotizarScreen extends StatefulWidget {
  const CotizarScreen({super.key});

  @override
  _CotizarScreenState createState() => _CotizarScreenState();
}

class _CotizarScreenState extends State<CotizarScreen> {
  final _formKey = GlobalKey<FormState>();
  List<OrdenTrabajoTrabajo> _trabajosEnOrden = [];
  Trabajo? _trabajoSeleccionado;
  Cliente? _clienteSeleccionado;
  double _ancho = 1.0;
  double _alto = 1.0;
  int _cantidad = 1;
  double _adicional = 0.0;

  // Controllers are the single source of truth for TextFields
  late TextEditingController _totalPersonalizadoController;
  late TextEditingController _adelantoController;
  late TextEditingController _notasController;

  DateTime _fechaEntrega = DateTime.now();
  TimeOfDay _horaEntrega = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _totalPersonalizadoController = TextEditingController();
    _adelantoController = TextEditingController();
    _notasController = TextEditingController();
  }

  @override
  void dispose() {
    _totalPersonalizadoController.dispose();
    _adelantoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  double get _subtotalActual {
    if (_trabajoSeleccionado == null) return 0.0;
    return _trabajoSeleccionado!
        .calcularPrecio(_ancho, _alto, _cantidad, _adicional);
  }

  double get _totalOrden {
    final totalPersonalizadoValue =
        double.tryParse(_totalPersonalizadoController.text);
    if (totalPersonalizadoValue != null) {
      return totalPersonalizadoValue;
    }
    return _trabajosEnOrden.fold(0.0, (p, e) => p + e.precioFinal);
  }

  void _addTrabajoAOrden() {
    if (_trabajoSeleccionado == null) return;

    setState(() {
      _trabajosEnOrden.add(OrdenTrabajoTrabajo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        trabajo: _trabajoSeleccionado!,
        ancho: _ancho,
        alto: _alto,
        cantidad: _cantidad,
        adicional: _adicional,
      ));
      // Reset fields
      _trabajoSeleccionado = null;
      _ancho = 1.0;
      _alto = 1.0;
      _cantidad = 1;
      _adicional = 0.0;
    });
  }

  void _editTrabajoEnOrden(int index) {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => TrabajoFormDialog(
        trabajoEnOrden: _trabajosEnOrden[index],
        availableTrabajos: appState.trabajos,
        onSave: (editedTrabajo) {
          setState(() {
            _trabajosEnOrden[index] = editedTrabajo;
          });
        },
      ),
    );
  }

  void _guardarOrden() {
    if (_formKey.currentState!.validate()) {
      if (_clienteSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, seleccione un cliente')),
        );
        return;
      }
      if (_trabajosEnOrden.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, añada al menos un trabajo a la orden')),
        );
        return;
      }

      final appState = Provider.of<AppState>(context, listen: false);

      final totalPersonalizadoValue =
          double.tryParse(_totalPersonalizadoController.text);
      final adelantoValue = double.tryParse(_adelantoController.text) ?? 0.0;
      final notasValue = _notasController.text;

      final newOrden = OrdenTrabajo(
        id: Random().nextDouble().toString(),
        cliente: _clienteSeleccionado!,
        trabajos: _trabajosEnOrden,
        historial: [
          OrdenHistorial(
              id: Random().nextDouble().toString(),
              cambio: 'Creación de la orden.',
              usuarioId: appState.currentUser!.id,
              usuarioNombre: appState.currentUser!.nombre,
              timestamp: DateTime.now())
        ],
        adelanto: adelantoValue,
        totalPersonalizado: totalPersonalizadoValue,
        notas: notasValue.isNotEmpty ? notasValue : null,
        fechaEntrega: _fechaEntrega,
        horaEntrega: _horaEntrega,
        creadoEn: DateTime.now(),
        creadoPorUsuarioId: appState.currentUser!.id,
      );

      appState.addOrden(newOrden);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orden guardada con éxito')),
      );

      // Reset the entire screen
      setState(() {
        _trabajosEnOrden = [];
        _clienteSeleccionado = null;
        _trabajoSeleccionado = null; // Resetear también el trabajo seleccionado

        // Clear controllers to update UI
        _totalPersonalizadoController.clear();
        _adelantoController.clear();
        _notasController.clear();

        _formKey.currentState?.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Column(
            children: [
              _buildAddWorkSection(appState),
              const SizedBox(height: 16),
              _buildWorkList(),
              const SizedBox(height: 16),
              _buildSummaryAndClientSection(appState),
              const SizedBox(height: 20),
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.save_rounded),
      label: const Text('Guardar Orden de Trabajo'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
      onPressed: _guardarOrden,
    );
  }

  Card _buildAddWorkSection(AppState appState) {
    // Filtrar trabajos únicos manualmente
    final uniqueTrabajos = <String, Trabajo>{};
    for (var trabajo in appState.trabajos) {
      uniqueTrabajos[trabajo.id] = trabajo;
    }
    final trabajosUnicos = uniqueTrabajos.values.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown para tipo de trabajo
            DropdownButtonFormField<Trabajo>(
              value: _trabajoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Tipo de Trabajo',
                prefixIcon: Icon(Icons.work_rounded),
              ),
              items: trabajosUnicos.asMap().entries.map((entry) {
                int index = entry.key;
                Trabajo trabajo = entry.value;
                return DropdownMenuItem<Trabajo>(
                  key: Key('trabajo_${trabajo.id}_$index'), // Key único con índice
                  value: trabajo,
                  child: Text(trabajo.nombre),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _trabajoSeleccionado = newValue;
                });
              },
            ),
            FormSpacing.verticalLarge(),

            // Fila con dimensiones - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  _buildInputField(
                    label: 'Ancho (m)',
                    icon: Icons.straighten_rounded,
                    initialValue: _ancho.toString(),
                    onChanged: (v) =>
                        setState(() => _ancho = double.tryParse(v) ?? 1.0),
                  ),
                  FormSpacing.verticalMedium(),
                  _buildInputField(
                    label: 'Alto (m)',
                    icon: Icons.height_rounded,
                    initialValue: _alto.toString(),
                    onChanged: (v) =>
                        setState(() => _alto = double.tryParse(v) ?? 1.0),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Ancho (m)',
                      icon: Icons.straighten_rounded,
                      initialValue: _ancho.toString(),
                      onChanged: (v) =>
                          setState(() => _ancho = double.tryParse(v) ?? 1.0),
                    ),
                  ),
                  FormSpacing.horizontalMedium(),
                  Expanded(
                    child: _buildInputField(
                      label: 'Alto (m)',
                      icon: Icons.height_rounded,
                      initialValue: _alto.toString(),
                      onChanged: (v) =>
                          setState(() => _alto = double.tryParse(v) ?? 1.0),
                    ),
                  ),
                ],
              ),
            ),
            FormSpacing.verticalLarge(),

            // Fila con cantidad y adicional - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  _buildInputField(
                    label: 'Cantidad',
                    icon: Icons.numbers_rounded,
                    initialValue: _cantidad.toString(),
                    onChanged: (v) =>
                        setState(() => _cantidad = int.tryParse(v) ?? 1),
                  ),
                  FormSpacing.verticalMedium(),
                  _buildInputField(
                    label: 'Adicional (Bs)',
                    icon: Icons.attach_money_rounded,
                    initialValue: _adicional.toString(),
                    onChanged: (v) =>
                        setState(() => _adicional = double.tryParse(v) ?? 0.0),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Cantidad',
                      icon: Icons.numbers_rounded,
                      initialValue: _cantidad.toString(),
                      onChanged: (v) =>
                          setState(() => _cantidad = int.tryParse(v) ?? 1),
                    ),
                  ),
                  FormSpacing.horizontalMedium(),
                  Expanded(
                    child: _buildInputField(
                      label: 'Adicional (Bs)',
                      icon: Icons.attach_money_rounded,
                      initialValue: _adicional.toString(),
                      onChanged: (v) => setState(
                          () => _adicional = double.tryParse(v) ?? 0.0),
                    ),
                  ),
                ],
              ),
            ),
            FormSpacing.verticalLarge(),

            // Subtotal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE0F2FE),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Subtotal:",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1D29),
                        ),
                  ),
                  Text(
                    "Bs ${_subtotalActual.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF98CA3F),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botón agregar
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir a la Orden'),
                onPressed:
                    _trabajoSeleccionado != null ? _addTrabajoAOrden : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _buildWorkList() {
    if (_trabajosEnOrden.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.work_off_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aún no hay trabajos en esta orden',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[400],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega trabajos usando el formulario superior',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lista de trabajos
            ...List.generate(_trabajosEnOrden.length, (index) {
              final item = _trabajosEnOrden[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.work_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    '${item.trabajo.nombre} (${item.cantidad}x)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Dimensiones: ${item.ancho}m x ${item.alto}m'),
                      if (item.adicional > 0)
                        Text(
                            'Adicional: Bs ${item.adicional.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Bs ${item.precioFinal.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.ancho * item.alto} m²',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_rounded, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _trabajosEnOrden.removeAt(index);
                          });
                        },
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                  onTap: () => _editTrabajoEnOrden(index),
                ),
              );
            }),

            // Total de trabajos
            if (_trabajosEnOrden.isNotEmpty) ...[
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total de Trabajos:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Bs ${_trabajosEnOrden.fold(0.0, (sum, item) => sum + item.precioFinal).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryAndClientSection(AppState appState) {
    double totalBruto =
        _trabajosEnOrden.fold(0.0, (p, e) => p + e.precioFinal);
    final totalPersonalizado =
        double.tryParse(_totalPersonalizadoController.text);
    double rebaja = 0.0;
    if (totalPersonalizado != null && totalPersonalizado < totalBruto) {
      rebaja = totalBruto - totalPersonalizado;
    }

    // Filtrar clientes únicos manualmente
    final uniqueClientes = <String, Cliente>{};
    for (var cliente in appState.clientes) {
      uniqueClientes[cliente.id] = cliente;
    }
    final clientesUnicos = uniqueClientes.values.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selección de cliente
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<Cliente>(
                value: _clienteSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  prefixIcon: Icon(Icons.person_rounded),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: clientesUnicos.asMap().entries.map((entry) {
                  int index = entry.key;
                  Cliente cliente = entry.value;
                  return DropdownMenuItem<Cliente>(
                    key: Key(
                        'cliente_${cliente.id}_$index'), // Key único con índice
                    value: cliente,
                    child: Text(cliente.nombre),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _clienteSeleccionado = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Seleccione un cliente' : null,
              ),
            ),
            FormSpacing.verticalLarge(),

            // Campos financieros - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _totalPersonalizadoController,
                      decoration: const InputDecoration(
                        labelText: 'Total Personalizado (Bs)',
                        prefixIcon: Icon(Icons.edit_rounded),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintText: 'Opcional',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  FormSpacing.verticalMedium(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _adelantoController,
                      decoration: const InputDecoration(
                        labelText: 'Adelanto (Bs)',
                        prefixIcon: Icon(Icons.payment_rounded),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintText: '0.00',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _totalPersonalizadoController,
                        decoration: const InputDecoration(
                          labelText: 'Total Personalizado (Bs)',
                          prefixIcon: Icon(Icons.edit_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          hintText: 'Opcional',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                  ),
                  FormSpacing.horizontalMedium(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _adelantoController,
                        decoration: const InputDecoration(
                          labelText: 'Adelanto (Bs)',
                          prefixIcon: Icon(Icons.payment_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          hintText: '0.00',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FormSpacing.verticalLarge(),

            // Notas
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _notasController,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  prefixIcon: Icon(Icons.note_rounded),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: 'Información adicional...',
                ),
                maxLines: 3,
              ),
            ),
            FormSpacing.verticalLarge(),

            // Fecha y hora de entrega - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  // Fecha en móvil
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fechaEntrega,
                          firstDate: DateTime(
                              2020, 1, 1), // Permite fechas desde 2020
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
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
                        if (picked != null)
                          setState(() => _fechaEntrega = picked);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha de Entrega',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                Text(
                                  DateTimeUtils.formatDate(_fechaEntrega),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
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
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _horaEntrega,
                        );
                        if (picked != null)
                          setState(() => _horaEntrega = picked);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hora de Entrega',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                Text(
                                  DateTimeUtils.formatTime(_horaEntrega),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaEntrega,
                            firstDate: DateTime(
                                2020, 1, 1), // Permite fechas desde 2020
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
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
                          if (picked != null)
                            setState(() => _fechaEntrega = picked);
                        },
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha de Entrega',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  Text(
                                    DateTimeUtils.formatDate(_fechaEntrega),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _horaEntrega,
                          );
                          if (picked != null)
                            setState(() => _horaEntrega = picked);
                        },
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hora de Entrega',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  Text(
                                    DateTimeUtils.formatTime(_horaEntrega),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
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
            FormSpacing.verticalLarge(),

            // Resumen financiero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                      'Total Bruto:', 'Bs ${totalBruto.toStringAsFixed(2)}'),
                  if (rebaja > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                        'Rebaja:', '-Bs ${rebaja.toStringAsFixed(2)}',
                        color: Colors.orange),
                  ],
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                      'Total Final:', 'Bs ${_totalOrden.toStringAsFixed(2)}',
                      isTotal: true),
                  if (double.tryParse(_adelantoController.text) != null &&
                      double.tryParse(_adelantoController.text)! > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                        'Adelanto:', 'Bs ${_adelantoController.text}',
                        color: Colors.green),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                        'Saldo:',
                        'Bs ${(_totalOrden - (double.tryParse(_adelantoController.text) ?? 0)).toStringAsFixed(2)}',
                        color: Colors.blue),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Widget de archivos adjuntos para nueva orden
            if (_trabajosEnOrden.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Archivos Adjuntos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.attach_file_rounded),
                        label: const Text("Adjuntar Archivos"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Los archivos se pueden adjuntar después de guardar la orden. "
                                "Podrá acceder a esta funcionalidad desde la pantalla de detalle de la orden.",
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color ??
                      (isTotal ? Theme.of(context).colorScheme.primary : null),
                  fontSize: isTotal ? 18 : null,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
