import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:uuid/uuid.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../core/design_system/design_tokens.dart';
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
  late TextEditingController _fechaEntregaController;
  late TextEditingController _horaEntregaController;

  DateTime _fechaEntrega = DateTime.now();
  TimeOfDay _horaEntrega = TimeOfDay.now();

  // Memoizar el Future para evitar reconstrucciones
  late Future<List<dynamic>> _dataFuture;

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
    _fechaEntregaController = TextEditingController();
    _horaEntregaController = TextEditingController();

    // Los controllers se actualizarán en el primer build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDateTimeControllers();
    });

    // Inicializar el Future memoizado
    final appState = Provider.of<AppState>(context, listen: false);
    _dataFuture = Future.wait([appState.trabajos, appState.clientes]);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final trabajos = await appState.trabajos;
      if (mounted && trabajos.isNotEmpty) {
        setState(() {
          _trabajoSeleccionado = trabajos.first;
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
    _fechaEntregaController.dispose();
    _horaEntregaController.dispose();
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

  // Métodos de cálculo para el resumen
  double _calcularSubtotal() {
    return _trabajosEnOrden.fold(0.0, (sum, trabajo) => sum + trabajo.precioFinal);
  }

  double _calcularImpuestos() {
    return 0.0; // Sin impuestos
  }

  double _calcularDescuento() {
    return 0.0; // Sin descuentos
  }

  double _calcularTotal() {
    final totalPersonalizadoValue = double.tryParse(_totalPersonalizadoController.text);
    if (totalPersonalizadoValue != null) {
      return totalPersonalizadoValue;
    }
    return _calcularSubtotal();
  }

  void _updateDateTimeControllers() {
    _fechaEntregaController.text = '${_fechaEntrega.day}/${_fechaEntrega.month}/${_fechaEntrega.year}';
    _horaEntregaController.text = _horaEntrega.format(context);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _fechaEntrega) {
      setState(() {
        _fechaEntrega = picked;
        _updateDateTimeControllers();
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaEntrega,
    );
    if (picked != null && picked != _horaEntrega) {
      setState(() {
        _horaEntrega = picked;
        _updateDateTimeControllers();
      });
    }
  }

  void _addTrabajoAOrden() {
    if (_trabajoSeleccionado == null) return;

    final ancho = double.tryParse(_anchoController.text) ?? 1.0;
    final alto = double.tryParse(_altoController.text) ?? 1.0;
    final cantidad = int.tryParse(_cantidadController.text) ?? 1;
    final adicional = double.tryParse(_adicionalController.text) ?? 0.0;

    // Validaciones
    if (ancho <= 0 || alto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las dimensiones deben ser mayores a 0')),
      );
      return;
    }

    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad debe ser mayor a 0')),
      );
      return;
    }

    setState(() {
      _trabajosEnOrden.add(OrdenTrabajoTrabajo(
        id: const Uuid().v4(),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trabajo agregado a la orden')),
    );
  }

  void _editTrabajoEnOrden(int index, List<Trabajo> trabajosDisponibles) {
    showDialog(
      context: context,
      builder: (_) => TrabajoFormDialog(
        trabajoEnOrden: _trabajosEnOrden[index],
        availableTrabajos: trabajosDisponibles,
        onSave: (editedTrabajo) {
          setState(() {
            _trabajosEnOrden[index] = editedTrabajo;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trabajo actualizado')),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar trabajo'),
        content: const Text('¿Estás seguro de que deseas eliminar este trabajo de la orden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _trabajosEnOrden.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trabajo eliminado de la orden')),
      );
    }
  }

  // Método para mostrar el diálogo de crear cliente
  void _showCreateClientDialog() async {
    final result = await showDialog<Cliente>(
      context: context,
      builder: (context) => _CreateClientDialogWrapper(
        onClientCreated: (newClient) => Navigator.of(context).pop(newClient),
      ),
    );

    if (result != null) {
      // Refrescar los datos para incluir el nuevo cliente
      final appState = Provider.of<AppState>(context, listen: false);
      setState(() {
        // Reinicializar el Future para cargar los datos actualizados
        _dataFuture = Future.wait([appState.trabajos, appState.clientes]);
        // Seleccionar automáticamente el nuevo cliente
        _clienteSeleccionado = result;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente "${result.nombre}" creado y seleccionado'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _guardarOrden() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un cliente para continuar')),
      );
      return;
    }

    if (_trabajosEnOrden.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un trabajo a la orden para continuar')),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: AppSpacing.md),
            Text('Guardando orden...'),
          ],
        ),
      ),
    );

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      final totalPersonalizadoValue =
          double.tryParse(_totalPersonalizadoController.text);
      final adelantoValue = double.tryParse(_adelantoController.text) ?? 0.0;
      final notasValue = _notasController.text;

      final ordenId = const Uuid().v4();

      // Convertir OrdenTrabajoTrabajo a OrdenTrabajoItem
      final items = _trabajosEnOrden.map((trabajo) => trabajo.toOrdenTrabajoItem(ordenId)).toList();

      final newOrden = OrdenTrabajo(
        id: ordenId,
        cliente: _clienteSeleccionado!,
        empresaId: appState.currentUser!.empresaId,
        authUserId: appState.currentUser!.id,
        items: items,
        adelanto: adelantoValue,
        totalPersonalizado: totalPersonalizadoValue,
        notas: notasValue.isNotEmpty ? notasValue : null,
        fechaEntrega: _fechaEntrega,
        horaEntrega: _horaEntrega,
        createdAt: DateTime.now(),
      );

      // Simular un pequeño delay para mostrar el loading
      await Future.delayed(const Duration(milliseconds: 800));

      print('🔄 Guardando orden: ${newOrden.id}');
      print('🔄 Cliente: ${newOrden.cliente.nombre}');
      print('🔄 Items: ${newOrden.items.length}');
      
      await appState.addOrden(newOrden);
      print('✅ Orden guardada exitosamente');

      if (mounted) {
        // Ocultar loading
        Navigator.of(context).pop();
        
        // Mostrar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Orden guardada exitosamente'),
            action: SnackBarAction(
              label: 'Ver órdenes',
              onPressed: () => Navigator.of(context).pushNamed('/ordenes'),
            ),
          ),
        );

        // Reset the entire screen
        setState(() {
          _trabajosEnOrden = [];
          _clienteSeleccionado = null;
          _trabajoSeleccionado = null;

          // Clear controllers to update UI
          _totalPersonalizadoController.clear();
          _adelantoController.clear();
          _notasController.clear();

          _formKey.currentState?.reset();
        });
      }
    } catch (e) {
      print('❌ Error al guardar orden: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Ocultar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la orden: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, 
                  size: AppDimensions.iconXXL, 
                  color: Theme.of(context).colorScheme.error),
                AppSpacing.verticalMD,
                Text('Error al cargar datos: ${snapshot.error}'),
                AppSpacing.verticalMD,
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final trabajosDisponibles = (snapshot.data?[0] as List<Trabajo>?) ?? [];
        final clientesDisponibles = (snapshot.data?[1] as List<Cliente>?) ?? [];

        return _buildSinglePageView(trabajosDisponibles, clientesDisponibles);
      },
    );
  }

  // Vista de una sola columna
  Widget _buildSinglePageView(List<Trabajo> trabajosDisponibles, List<Cliente> clientesDisponibles) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Formulario de agregar trabajo
            _buildWorkForm(trabajosDisponibles),
            AppSpacing.verticalLG,
            
            // 2. Lista de trabajos agregados (si hay)
            if (_trabajosEnOrden.isNotEmpty) ...[
              _buildWorksList(),
              AppSpacing.verticalLG,
            ],
            
            // 3. Selección de cliente
            _buildClientSection(clientesDisponibles),
            AppSpacing.verticalLG,
            
            // 4. Detalles adicionales
            _buildDetailsSection(),
            AppSpacing.verticalLG,
            
            // 5. Resumen y totales
            _buildSummarySection(),
            AppSpacing.verticalLG,
            
            // 6. Botón para crear orden
            _buildCreateOrderButton(),
            AppSpacing.verticalXL,
          ],
        ),
      ),
    );
  }

  // Formulario para trabajos
  Widget _buildWorkForm(List<Trabajo> trabajosDisponibles) {
    final uniqueTrabajos = <String, Trabajo>{};
    for (var trabajo in trabajosDisponibles) {
      uniqueTrabajos[trabajo.id] = trabajo;
    }
    final trabajosUnicos = uniqueTrabajos.values.toList();

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: AppColors.getPrimary(context),
                  size: AppDimensions.iconLG,
                ),
                AppSpacing.horizontalSM,
                Text(
                  'Agregar Trabajo',
                  style: AppTypography.headline6.copyWith(
                    fontWeight: AppTypography.medium,
                    color: AppColors.getPrimary(context),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMD,
            
            // Dropdown trabajo
            DropdownSearch<Trabajo>(
              items: (filter, infiniteScrollProps) => trabajosUnicos,
              selectedItem: _trabajoSeleccionado,
              itemAsString: (Trabajo trabajo) => trabajo.nombre,
              compareFn: (Trabajo item1, Trabajo item2) => item1.id == item2.id,
              onChanged: (Trabajo? newValue) => setState(() => _trabajoSeleccionado = newValue),
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Seleccionar tipo de trabajo',
                  prefixIcon: Icon(Icons.work_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Buscar trabajo...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            AppSpacing.verticalMD,

            // Primera fila: Ancho y Alto
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anchoController,
                    decoration: const InputDecoration(
                      labelText: 'Ancho (m)',
                      prefixIcon: Icon(Icons.straighten),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: TextFormField(
                    controller: _altoController,
                    decoration: const InputDecoration(
                      labelText: 'Alto (m)',
                      prefixIcon: Icon(Icons.height),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    onChanged: (v) => setState(() {}),
                  ),
                ),
              ],
            ),
            
            AppSpacing.verticalMD,
            
            // Segunda fila: Cantidad y Costo adicional
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      prefixIcon: Icon(Icons.format_list_numbered),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: TextFormField(
                    controller: _adicionalController,
                    decoration: const InputDecoration(
                      labelText: 'Costo adicional (Bs)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      helperText: 'Instalación, traslado, etc.',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    onChanged: (v) => setState(() {}),
                  ),
                ),
              ],
            ),

            AppSpacing.verticalLG,
            
            // Subtotal y botón
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_subtotalActual > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subtotal del trabajo:',
                        style: AppTypography.caption,
                      ),
                      Text(
                        'Bs ${_subtotalActual.toStringAsFixed(0)}',
                        style: AppTypography.headline6.copyWith(
                          color: AppColors.getPrimary(context),
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                SizedBox(
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: _trabajoSeleccionado != null &&
                            _anchoController.text.isNotEmpty &&
                            _altoController.text.isNotEmpty
                        ? _addTrabajoAOrden
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir trabajo'),
                    style: ElevatedButton.styleFrom(
                      padding: AppSpacing.paddingLG,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Lista de trabajos agregados
  Widget _buildWorksList() {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: AppColors.getPrimary(context),
                  size: AppDimensions.iconLG,
                ),
                AppSpacing.horizontalSM,
                Text(
                  'Trabajos en la Orden',
                  style: AppTypography.headline6.copyWith(
                    fontWeight: AppTypography.medium,
                    color: AppColors.getPrimary(context),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_trabajosEnOrden.length} trabajo${_trabajosEnOrden.length != 1 ? 's' : ''}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.getPrimary(context),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMD,
            
            ...List.generate(_trabajosEnOrden.length, (index) {
              final trabajo = _trabajosEnOrden[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.getPrimary(context).withOpacity(0.2),
                  ),
                  borderRadius: AppBorders.borderRadiusMD,
                ),
                child: Row(
                  children: [
                    Container(
                      width: AppDimensions.dividerWidth,
                      height: AppDimensions.cardHeight,
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(context),
                        borderRadius: AppBorders.borderRadiusXS,
                      ),
                    ),
                    AppSpacing.horizontalMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trabajo.trabajo?.nombre ?? 'Sin nombre',
                            style: AppTypography.bodyText1.copyWith(
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                          AppSpacing.verticalXS,
                          Text(
                            'Dimensiones: ${trabajo.ancho}m × ${trabajo.alto}m',
                            style: AppTypography.bodyText2,
                          ),
                          Text(
                            'Cantidad: ${trabajo.cantidad} unidad${trabajo.cantidad != 1 ? 'es' : ''}',
                            style: AppTypography.bodyText2,
                          ),
                          if (trabajo.adicional > 0) ...[
                            Text(
                              'Costo adicional: Bs ${trabajo.adicional.toStringAsFixed(0)}',
                              style: AppTypography.bodyText2.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Bs ${trabajo.precioFinal.toStringAsFixed(0)}',
                          style: AppTypography.headline6.copyWith(
                            fontWeight: AppTypography.bold,
                            color: AppColors.getPrimary(context),
                          ),
                        ),
                        AppSpacing.verticalSM,
                        IconButton(
                          onPressed: () => _showDeleteConfirmation(index),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Sección de cliente
  Widget _buildClientSection(List<Cliente> clientesDisponibles) {
    final uniqueClientes = <String, Cliente>{};
    for (var cliente in clientesDisponibles) {
      uniqueClientes[cliente.id] = cliente;
    }
    final clientesUnicos = uniqueClientes.values.toList();

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppColors.getPrimary(context),
                  size: AppDimensions.iconLG,
                ),
                AppSpacing.horizontalSM,
                Text(
                  'Cliente',
                  style: AppTypography.headline6.copyWith(
                    fontWeight: AppTypography.medium,
                    color: AppColors.getPrimary(context),
                  ),
                ),
                const Spacer(),
                // Botón para agregar nuevo cliente
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(context).withOpacity(0.1),
                    borderRadius: AppBorders.borderRadiusSM,
                  ),
                  child: IconButton(
                    onPressed: _showCreateClientDialog,
                    icon: Icon(
                      Icons.add,
                      color: AppColors.getPrimary(context),
                    ),
                    tooltip: 'Crear nuevo cliente',
                    iconSize: AppDimensions.iconMD,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMD,
            
            Row(
              children: [
                Expanded(
                  child: DropdownSearch<Cliente>(
                    items: (filter, infiniteScrollProps) => clientesUnicos,
                    selectedItem: _clienteSeleccionado,
                    itemAsString: (Cliente cliente) => cliente.nombre,
                    compareFn: (Cliente item1, Cliente item2) => item1.id == item2.id,
                    onChanged: (Cliente? newValue) => setState(() => _clienteSeleccionado = newValue),
                    validator: (value) => value == null ? 'Selecciona un cliente' : null,
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'Seleccionar Cliente',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Buscar cliente...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Sección de detalles
  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.getPrimary(context),
                  size: AppDimensions.iconLG,
                ),
                AppSpacing.horizontalSM,
                Text(
                  'Detalles Adicionales',
                  style: AppTypography.headline6.copyWith(
                    fontWeight: AppTypography.medium,
                    color: AppColors.getPrimary(context),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMD,
            
            // Fecha y hora de entrega
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fechaEntregaController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de entrega',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: TextFormField(
                    controller: _horaEntregaController,
                    decoration: const InputDecoration(
                      labelText: 'Hora de entrega',
                      prefixIcon: Icon(Icons.access_time_outlined),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(context),
                  ),
                ),
              ],
            ),
            
            AppSpacing.verticalMD,
            
            // Adelanto
            TextFormField(
              controller: _adelantoController,
              decoration: const InputDecoration(
                labelText: 'Adelanto (Bs)',
                prefixIcon: Icon(Icons.attach_money_outlined),
                border: OutlineInputBorder(),
                helperText: 'Monto recibido como adelanto del cliente',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (value) => setState(() {}), // Actualizar resumen en tiempo real
            ),
            
            AppSpacing.verticalMD,
            
            // Total personalizado
            TextFormField(
              controller: _totalPersonalizadoController,
              decoration: const InputDecoration(
                labelText: 'Total personalizado (Bs)',
                prefixIcon: Icon(Icons.edit_outlined),
                border: OutlineInputBorder(),
                helperText: 'Anular cálculo automático y usar este total',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (value) => setState(() {}), // Actualizar resumen en tiempo real
            ),
            
            AppSpacing.verticalMD,
            
            // Notas
            TextFormField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: 'Notas adicionales',
                prefixIcon: Icon(Icons.note_outlined),
                border: OutlineInputBorder(),
                helperText: 'Instrucciones especiales, comentarios, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // Sección de resumen
  Widget _buildSummarySection() {
    final subtotal = _calcularSubtotal();
    final total = _calcularTotal();
    final totalPersonalizado = double.tryParse(_totalPersonalizadoController.text);
    
    // Debug
    print('DEBUG - Subtotal: $subtotal, Total: $total, Personalizado: $totalPersonalizado');
    
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.getPrimary(context),
                  size: AppDimensions.iconLG,
                ),
                AppSpacing.horizontalSM,
                Text(
                  'Resumen de la Orden',
                  style: AppTypography.headline6.copyWith(
                    fontWeight: AppTypography.medium,
                    color: AppColors.getPrimary(context),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMD,
            
            // Detalles del cálculo
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: AppBorders.borderRadiusMD,
                border: Border.all(
                  color: AppColors.getPrimary(context).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal:',
                        style: AppTypography.bodyText1,
                      ),
                      Text(
                        'Bs ${subtotal.toStringAsFixed(0)}',
                        style: AppTypography.bodyText1.copyWith(
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                    ],
                  ),
                  
                  // Mostrar ajuste personalizado si existe
                  if (totalPersonalizado != null && totalPersonalizado > 0) ...[
                    AppSpacing.verticalSM,
                    const Divider(height: 1),
                    AppSpacing.verticalSM,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ajuste personalizado:',
                          style: AppTypography.bodyText2.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                        Text(
                          '${totalPersonalizado > subtotal ? '+' : ''}Bs ${(totalPersonalizado - subtotal).toStringAsFixed(0)}',
                          style: AppTypography.bodyText2.copyWith(
                            color: AppColors.warning,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  AppSpacing.verticalMD,
                  const Divider(height: 1),
                  AppSpacing.verticalMD,
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: AppTypography.headline6.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      Text(
                        'Bs ${total.toStringAsFixed(0)}',
                        style: AppTypography.headline5.copyWith(
                          fontWeight: AppTypography.bold,
                          color: AppColors.getPrimary(context),
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
    );
  }

  // Botón para crear orden
  Widget _buildCreateOrderButton() {
    final isEnabled = _clienteSeleccionado != null && _trabajosEnOrden.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _guardarOrden : null,
        icon: Icon(Icons.save_rounded, size: AppDimensions.iconLG),
        label: Text(
          'Crear Orden de Trabajo',
          style: AppTypography.button,
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(0, AppDimensions.buttonHeight),
          padding: AppSpacing.paddingLG,
        ),
      ),
    );
  }
}

// Widget wrapper para manejar la creación de cliente
class _CreateClientDialogWrapper extends StatefulWidget {
  final Function(Cliente) onClientCreated;
  
  const _CreateClientDialogWrapper({
    required this.onClientCreated,
  });

  @override
  _CreateClientDialogWrapperState createState() => _CreateClientDialogWrapperState();
}

class _CreateClientDialogWrapperState extends State<_CreateClientDialogWrapper> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  String _contacto = '';

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: AppSpacing.md),
              Text('Creando cliente...'),
            ],
          ),
        ),
      );

      try {
        final appState = Provider.of<AppState>(context, listen: false);
        
        // Crear nuevo cliente
        final newCliente = Cliente.legacy(
          id: const Uuid().v4(),
          nombre: _nombre,
          contacto: _contacto,
          empresaId: appState.currentUser!.empresaId,
          authUserId: appState.currentUser!.authUserId, // Usar authUserId (UUID de Supabase Auth)
          createdAt: DateTime.now(),
        );

        await appState.addCliente(newCliente);
        
        if (mounted) {
          // Cerrar loading
          Navigator.of(context).pop();
          // Devolver el cliente creado
          widget.onClientCreated(newCliente);
        }
      } catch (e) {
        if (mounted) {
          // Cerrar loading
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear cliente: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        children: [
          Icon(
            Icons.person_add,
            color: AppColors.getPrimary(context),
            size: AppDimensions.iconLG,
          ),
          AppSpacing.horizontalSM,
          Text(
            'Nuevo Cliente',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Nombre del Cliente',
                labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'Campo requerido' : null,
              onSaved: (v) => _nombre = v ?? '',
              autofocus: true,
            ),
            AppSpacing.verticalMD,
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Contacto (Teléfono, Email, etc.)',
                labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.phone_outlined),
                border: const OutlineInputBorder(),
                helperText: 'Opcional - Información de contacto',
              ),
              onSaved: (v) => _contacto = v ?? '',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.getPrimary(context),
            foregroundColor: AppColors.white,
          ),
          onPressed: _submit,
          icon: Icon(Icons.add, size: AppDimensions.iconSM),
          label: const Text('Crear Cliente'),
        ),
      ],
    );
  }
}
