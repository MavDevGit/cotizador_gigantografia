import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

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

  // Controllers for text fields
  late TextEditingController _anchoController;
  late TextEditingController _altoController;
  late TextEditingController _cantidadController;
  late TextEditingController _adicionalController;
  late TextEditingController _totalPersonalizadoController;
  late TextEditingController _adelantoController;
  late TextEditingController _notasController;

  DateTime _fechaEntrega = DateTime.now();
  TimeOfDay _horaEntrega = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _anchoController = TextEditingController();
    _altoController = TextEditingController();
    _cantidadController = TextEditingController(text: '1');
    _adicionalController = TextEditingController();
    _totalPersonalizadoController = TextEditingController();
    _adelantoController = TextEditingController();
    _notasController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (mounted && appState.trabajos.isNotEmpty) {
        setState(() {
          _trabajoSeleccionado = appState.trabajos.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _anchoController.dispose();
    _altoController.dispose();
    _cantidadController.dispose();
    _adicionalController.dispose();
    _totalPersonalizadoController.dispose();
    _adelantoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  double get _subtotalActual {
    if (_trabajoSeleccionado == null) return 0.0;
    final ancho = double.tryParse(_anchoController.text) ?? 0.0;
    final alto = double.tryParse(_altoController.text) ?? 0.0;
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    final adicional = double.tryParse(_adicionalController.text) ?? 0.0;
    return _trabajoSeleccionado!
        .calcularPrecio(ancho, alto, cantidad, adicional);
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

    final ancho = double.tryParse(_anchoController.text) ?? 1.0;
    final alto = double.tryParse(_altoController.text) ?? 1.0;
    final cantidad = int.tryParse(_cantidadController.text) ?? 1;
    final adicional = double.tryParse(_adicionalController.text) ?? 0.0;

    setState(() {
      _trabajosEnOrden.add(OrdenTrabajoTrabajo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        trabajo: _trabajoSeleccionado!,
        ancho: ancho,
        alto: alto,
        cantidad: cantidad,
        adicional: adicional,
      ));
      // Reset fields
      _trabajoSeleccionado = null;
      _anchoController.clear();
      _altoController.clear();
      _cantidadController.text = '1';
      _adicionalController.clear();
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Column(
            children: [
              _buildAddWorkSection(appState),
              FormSpacing.verticalLarge(),
              _buildWorkList(),
              FormSpacing.verticalLarge(),
              _buildSummaryAndClientSection(appState),
              FormSpacing.verticalExtraLarge(),
              _buildSaveButton(),
              FormSpacing.verticalExtraLarge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save_rounded),
        label: const Text('Guardar Orden de Trabajo'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _clienteSeleccionado != null && _trabajosEnOrden.isNotEmpty
            ? _guardarOrden
            : null,
      ),
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
            DropdownSearch<Trabajo>(
              items: (filter, infiniteScrollProps) => trabajosUnicos,
              selectedItem: _trabajoSeleccionado,
              itemAsString: (Trabajo trabajo) => trabajo.nombre,
              onChanged: (Trabajo? newValue) {
                setState(() {
                  _trabajoSeleccionado = newValue;
                });
              },
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Tipo de Trabajo',
                  prefixIcon: Icon(
                    Icons.work_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  hintText: 'Buscar tipo de trabajo...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  labelStyle: UIUtils.getSubtitleStyle(context),
                  hintStyle: UIUtils.getSubtitleStyle(context),
                  floatingLabelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: const TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Buscar tipo de trabajo...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                itemBuilder: (context, Trabajo trabajo, isSelected, isHighlighted) {
                  final theme = Theme.of(context);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        UIUtils.buildThemedIcon(
                          icon: Icons.work_rounded,
                          context: context,
                          isSelected: isSelected,
                        ),
                        FormSpacing.horizontalMedium(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trabajo.nombre,
                                style: UIUtils.getTitleStyle(
                                  context,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Bs ${trabajo.precioM2.toStringAsFixed(2)}/m²',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                emptyBuilder: (context, searchEntry) {
                  final theme = Theme.of(context);
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.work_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                        FormSpacing.verticalSmall(),
                        Text(
                          'No se encontraron trabajos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (searchEntry.isNotEmpty) ...[
                          FormSpacing.verticalSmall(),
                          Text(
                            'para "$searchEntry"',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              compareFn: (Trabajo trabajo1, Trabajo trabajo2) =>
                  trabajo1.id == trabajo2.id,
            ),
            FormSpacing.verticalLarge(),

            // Fila con dimensiones - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  _buildInputField(
                    controller: _anchoController,
                    label: 'Ancho (m)',
                    icon: Icons.straighten_rounded,
                    hintText: '1.0',
                    onChanged: (v) => setState(() {}),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                  ),
                  FormSpacing.verticalMedium(),
                  _buildInputField(
                    controller: _altoController,
                    label: 'Alto (m)',
                    icon: Icons.height_rounded,
                    hintText: '1.0',
                    onChanged: (v) => setState(() {}),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _anchoController,
                      label: 'Ancho (m)',
                      icon: Icons.straighten_rounded,
                      hintText: '1.0',
                      onChanged: (v) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                    ),
                  ),
                  FormSpacing.horizontalMedium(),
                  Expanded(
                    child: _buildInputField(
                      controller: _altoController,
                      label: 'Alto (m)',
                      icon: Icons.height_rounded,
                      hintText: '1.0',
                      onChanged: (v) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
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
                    controller: _cantidadController,
                    label: 'Cantidad',
                    icon: Icons.numbers_rounded,
                    hintText: '1',
                    onChanged: (v) => setState(() {}),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  FormSpacing.verticalMedium(),
                  _buildInputField(
                    controller: _adicionalController,
                    label: 'Adicional (Bs)',
                    icon: Icons.attach_money_rounded,
                    hintText: '0.0',
                    onChanged: (v) => setState(() {}),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _cantidadController,
                      label: 'Cantidad',
                      icon: Icons.numbers_rounded,
                      hintText: '1',
                      onChanged: (v) => setState(() {}),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  FormSpacing.horizontalMedium(),
                  Expanded(
                    child: _buildInputField(
                      controller: _adicionalController,
                      label: 'Adicional (Bs)',
                      icon: Icons.attach_money_rounded,
                      hintText: '0.0',
                      onChanged: (v) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                    ),
                  ),
                ],
              ),
            ),
            FormSpacing.verticalLarge(),

            // Subtotal
            UIUtils.buildInfoContainer(
              context: context,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Subtotal:",
                    style: UIUtils.getTitleStyle(context),
                  ),
                  Text(
                    "Bs ${_subtotalActual.toStringAsFixed(2)}",
                    style: UIUtils.getPriceStyle(context, isLarge: true),
                  ),
                ],
              ),
            ),
            FormSpacing.verticalLarge(),

            // Botón agregar
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir a la Orden'),
                onPressed: _trabajoSeleccionado != null &&
                        _anchoController.text.isNotEmpty &&
                        _altoController.text.isNotEmpty
                    ? _addTrabajoAOrden
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    required ValueChanged<String> onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return ThemedInputField(
      controller: controller,
      label: label,
      icon: icon,
      hintText: hintText,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      keyboardType: TextInputType.number,
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
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
              FormSpacing.verticalLarge(),
              Text(
                'Aún no hay trabajos en esta orden',
                style: UIUtils.getTitleStyle(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              FormSpacing.verticalSmall(),
              Text(
                'Agrega trabajos usando el formulario superior',
                style: UIUtils.getSubtitleStyle(context),
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
              final theme = Theme.of(context);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: UIUtils.cardDecoration(context),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.work_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    '${item.trabajo.nombre} (${item.cantidad}x)',
                    style: UIUtils.getTitleStyle(context),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormSpacing.verticalSmall(),
                      Text(
                        'Dimensiones: ${item.ancho}m x ${item.alto}m',
                        style: UIUtils.getSubtitleStyle(context),
                      ),
                      if (item.adicional > 0)
                        Text(
                          'Adicional: Bs ${item.adicional.toStringAsFixed(2)}',
                          style: UIUtils.getSubtitleStyle(context),
                        ),
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
                            style: UIUtils.getPriceStyle(context),
                          ),
                          FormSpacing.verticalSmall(),
                          Text(
                            '${item.ancho * item.alto} m²',
                            style: UIUtils.getSubtitleStyle(context),
                          ),
                        ],
                      ),
                      FormSpacing.horizontalSmall(),
                      IconButton(
                        icon: Icon(
                          Icons.delete_rounded, 
                          color: UIUtils.getErrorColor(context),
                        ),
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
              UIUtils.buildSectionDivider(context),
              UIUtils.buildInfoContainer(
                context: context, 
                child: PriceDisplay(
                  label: 'Total de Trabajos:',
                  amount: _trabajosEnOrden.fold(0.0, (sum, item) => sum + item.precioFinal),
                  isTotal: true,
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
            DropdownSearch<Cliente>(
              items: (filter, infiniteScrollProps) => clientesUnicos,
              selectedItem: _clienteSeleccionado,
              itemAsString: (Cliente cliente) => cliente.nombre,
              onChanged: (Cliente? newValue) {
                setState(() {
                  _clienteSeleccionado = newValue;
                });
              },
              validator: (value) =>
                  value == null ? 'Seleccione un cliente' : null,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Cliente',
                  prefixIcon: Icon(
                    Icons.person_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  hintText: 'Buscar cliente...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  labelStyle: UIUtils.getSubtitleStyle(context),
                  hintStyle: UIUtils.getSubtitleStyle(context),
                  floatingLabelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: const TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                itemBuilder: (context, Cliente cliente, isSelected, isHighlighted) {
                  final theme = Theme.of(context);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        UIUtils.buildThemedIcon(
                          icon: Icons.person_rounded,
                          context: context,
                          isSelected: isSelected,
                        ),
                        FormSpacing.horizontalMedium(),
                        Expanded(
                          child: Text(
                            cliente.nombre,
                            style: UIUtils.getTitleStyle(
                              context,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                emptyBuilder: (context, searchEntry) {
                  final theme = Theme.of(context);
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                        FormSpacing.verticalSmall(),
                        Text(
                          'No se encontraron clientes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (searchEntry.isNotEmpty) ...[
                          FormSpacing.verticalSmall(),
                          Text(
                            'para "$searchEntry"',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              compareFn: (Cliente cliente1, Cliente cliente2) =>
                  cliente1.id == cliente2.id,
            ),
            FormSpacing.verticalLarge(),

            // Campos financieros - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  ThemedInputField(
                    controller: _totalPersonalizadoController,
                    label: 'Total Personalizado (Bs)',
                    icon: Icons.edit_rounded,
                    hintText: 'Opcional',
                    onChanged: (v) => setState(() {}),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    keyboardType: TextInputType.number,
                  ),
                  FormSpacing.verticalMedium(),
                  ThemedInputField(
                    controller: _adelantoController,
                    label: 'Adelanto (Bs)',
                    icon: Icons.payment_rounded,
                    hintText: '0.00',
                    onChanged: (v) => setState(() {}),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: ThemedInputField(
                      controller: _totalPersonalizadoController,
                      label: 'Total Personalizado (Bs)',
                      icon: Icons.edit_rounded,
                      hintText: 'Opcional',
                      onChanged: (v) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  FormSpacing.horizontalMedium(),
                  Expanded(
                    child: ThemedInputField(
                      controller: _adelantoController,
                      label: 'Adelanto (Bs)',
                      icon: Icons.payment_rounded,
                      hintText: '0.00',
                      onChanged: (v) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
            FormSpacing.verticalLarge(),

            // Notas
            TextFormField(
              controller: _notasController,
              decoration: InputDecoration(
                labelText: 'Notas',
                prefixIcon: Icon(
                  Icons.note_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                hintText: 'Información adicional...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                labelStyle: UIUtils.getSubtitleStyle(context),
                hintStyle: UIUtils.getSubtitleStyle(context),
                floatingLabelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
              maxLines: 3,
              style: UIUtils.getTitleStyle(context),
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
                    decoration: UIUtils.cardDecoration(context),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fechaEntrega,
                          firstDate: DateTime(2020, 1, 1),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('es', 'ES'),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                datePickerTheme: DatePickerThemeData(
                                  dayOverlayColor: MaterialStateProperty.all(Colors.transparent),
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
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          FormSpacing.horizontalMedium(),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha de Entrega',
                                  style: UIUtils.getSubtitleStyle(context),
                                ),
                                Text(
                                  DateTimeUtils.formatDate(_fechaEntrega),
                                  style: UIUtils.getTitleStyle(context),
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
                          initialTime: _horaEntrega,
                        );
                        if (picked != null)
                          setState(() => _horaEntrega = picked);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          FormSpacing.horizontalMedium(),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hora de Entrega',
                                  style: UIUtils.getSubtitleStyle(context),
                                ),
                                Text(
                                  DateTimeUtils.formatTime(_horaEntrega),
                                  style: UIUtils.getTitleStyle(context),
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
                            initialDate: _fechaEntrega,
                            firstDate: DateTime(2020, 1, 1),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            locale: const Locale('es', 'ES'),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  datePickerTheme: DatePickerThemeData(
                                    dayOverlayColor: MaterialStateProperty.all(Colors.transparent),
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
                            Icon(
                              Icons.calendar_today_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            FormSpacing.horizontalMedium(),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha de Entrega',
                                    style: UIUtils.getSubtitleStyle(context),
                                  ),
                                  Text(
                                    DateTimeUtils.formatDate(_fechaEntrega),
                                    style: UIUtils.getTitleStyle(context),
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
                            initialTime: _horaEntrega,
                          );
                          if (picked != null)
                            setState(() => _horaEntrega = picked);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            FormSpacing.horizontalMedium(),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hora de Entrega',
                                    style: UIUtils.getSubtitleStyle(context),
                                  ),
                                  Text(
                                    DateTimeUtils.formatTime(_horaEntrega),
                                    style: UIUtils.getTitleStyle(context),
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
            UIUtils.buildSummaryContainer(
              context: context,
              isElevated: true,
              child: Column(
                children: [
                  PriceDisplay(
                    label: 'Total Bruto:',
                    amount: totalBruto,
                  ),
                  if (rebaja > 0) ...[
                    FormSpacing.verticalSmall(),
                    PriceDisplay(
                      label: 'Rebaja:',
                      amount: rebaja,
                      color: UIUtils.getWarningColor(context),
                    ),
                  ],
                  FormSpacing.verticalMedium(),
                  UIUtils.buildSectionDivider(context),
                  FormSpacing.verticalMedium(),
                  PriceDisplay(
                    label: 'Total Final:',
                    amount: _totalOrden,
                    isTotal: true,
                  ),
                  if (double.tryParse(_adelantoController.text) != null &&
                      double.tryParse(_adelantoController.text)! > 0) ...[
                    FormSpacing.verticalSmall(),
                    PriceDisplay(
                      label: 'Adelanto:',
                      amount: double.tryParse(_adelantoController.text) ?? 0,
                      color: UIUtils.getSuccessColor(context),
                    ),
                    FormSpacing.verticalSmall(),
                    PriceDisplay(
                      label: 'Saldo:',
                      amount: _totalOrden - (double.tryParse(_adelantoController.text) ?? 0),
                      color: UIUtils.getInfoColor(context),
                    ),
                  ],
                ],
              ),
            ),
            FormSpacing.verticalExtraLarge(),
          ],
        ),
      ),
    );
  }
}
