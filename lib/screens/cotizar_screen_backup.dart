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

  // Control de pasos
  bool _isCreatingOrder = false; // false = Paso 1 (Cotizar), true = Paso 2 (Finalizar)

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
    final subtotal = _calcularSubtotal();
    return subtotal * 0.0; // Sin impuestos por ahora
  }

  double _calcularDescuento() {
    return 0.0; // Sin descuentos por ahora
  }

  double _calcularTotal() {
    final totalPersonalizadoValue = double.tryParse(_totalPersonalizadoController.text);
    if (totalPersonalizadoValue != null) {
      return totalPersonalizadoValue;
    }
    return _calcularSubtotal() + _calcularImpuestos() - _calcularDescuento();
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: AppSpacing.md),
                  Text('Error al cargar datos: ${snapshot.error}'),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final trabajosDisponibles = (snapshot.data?[0] as List<Trabajo>?) ?? [];
        final clientesDisponibles = (snapshot.data?[1] as List<Cliente>?) ?? [];

        return Scaffold(
          body: Column(
            children: [
              // Indicador de paso
              _buildStepIndicator(),
              
              // Contenido principal con transición
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
                      ),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _isCreatingOrder
                    ? _buildOrderCreationView(clientesDisponibles, key: const ValueKey('order_creation'))
                    : _buildQuoteView(trabajosDisponibles, key: const ValueKey('quote_view')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Indicador de paso superior
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Step 1
            _buildStepItem(
              stepNumber: 1,
              title: 'Cotizar',
              isActive: !_isCreatingOrder,
              isCompleted: _isCreatingOrder,
            ),
            
            // Connector
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _isCreatingOrder 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppBorders.radiusSM),
                ),
              ),
            ),
            
            // Step 2
            _buildStepItem(
              stepNumber: 2,
              title: 'Finalizar',
              isActive: _isCreatingOrder,
              isCompleted: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    
    if (isCompleted) {
      backgroundColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
      borderColor = colorScheme.primary;
    } else if (isActive) {
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      borderColor = colorScheme.primary;
    } else {
      backgroundColor = colorScheme.surface;
      textColor = colorScheme.onSurfaceVariant;
      borderColor = colorScheme.outline.withOpacity(0.5);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: isCompleted
              ? Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: textColor,
                )
              : Text(
                  '$stepNumber',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive || isCompleted ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Vista del Paso 1: Cotización
  Widget _buildQuoteView(List<Trabajo> trabajosDisponibles, {Key? key}) {
    return Container(
      key: key,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // Header con título y descripción
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calculate_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Crear Cotización',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Añade trabajos y calcula el costo total de tu proyecto. Una vez que tengas todo listo, podrás asignar cliente y crear la orden.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Sección añadir trabajo
            _buildAddWorkSection(trabajosDisponibles),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Lista de trabajos
            _buildWorkList(trabajosDisponibles),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Resumen de precios
            _buildPriceSummary(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Botón para continuar al paso 2
            _buildContinueButton(),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // Resumen de precios simplificado para paso 1
  Widget _buildPriceSummary() {
    if (_trabajosEnOrden.isEmpty) {
      return const SizedBox.shrink();
    }

    final subtotal = _calcularSubtotal();
    final impuestos = _calcularImpuestos();
    final descuento = _calcularDescuento();
    final total = _calcularTotal();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Resumen de Precios',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            _buildPriceRow('Subtotal', subtotal, false),
            if (descuento > 0) _buildPriceRow('Descuento', -descuento, false),
            _buildPriceRow('Impuestos', impuestos, false),
            
            const Divider(height: AppSpacing.lg),
            
            _buildPriceRow('Total', total, true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, bool isTotal, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal 
              ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: isTotal 
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color ?? Theme.of(context).colorScheme.primary,
                )
              : Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  // Botón para continuar al paso 2
  Widget _buildContinueButton() {
    final hasWorks = _trabajosEnOrden.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasWorks ? () {
          setState(() {
            _isCreatingOrder = true;
          });
        } : null,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Continuar a Finalizar'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
    );
  }

  // Vista del Paso 2: Finalizar Orden
  Widget _buildOrderCreationView(List<Cliente> clientesDisponibles, {Key? key}) {
    return Container(
      key: key,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // Header con botón de regreso
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isCreatingOrder = false;
                      });
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Finalizar Orden',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Asigna cliente y completa la información',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Resumen de trabajos
            _buildWorksSummaryCard(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Selección de cliente
            _buildClientSelection(clientesDisponibles),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Información adicional (fecha, hora, adelanto, etc.)
            _buildOrderDetailsSection(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Botones de acción
            _buildFinalActionButtons(),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildWorksSummaryCard() {
    final total = _calcularTotal();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen de Trabajos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_trabajosEnOrden.length} trabajo${_trabajosEnOrden.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Lista compacta de trabajos
            ...List.generate(_trabajosEnOrden.length, (index) {
              final trabajo = _trabajosEnOrden[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppBorders.radiusSM),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${trabajo.trabajo?.nombre} - ${trabajo.cantidad}x',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '\$${trabajo.precioFinal.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(height: AppSpacing.lg),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSelection(List<Cliente> clientesDisponibles) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Cliente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            DropdownButtonFormField<Cliente>(
              value: _clienteSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Cliente',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              items: clientesDisponibles.map((cliente) {
                return DropdownMenuItem<Cliente>(
                  value: cliente,
                  child: Text(cliente.nombre),
                );
              }).toList(),
              onChanged: (Cliente? newValue) {
                setState(() {
                  _clienteSeleccionado = newValue;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor, selecciona un cliente';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsSection() {
    return Column(
      children: [
        // Fecha y hora de entrega
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha y Hora de Entrega',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                
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
                    const SizedBox(width: AppSpacing.md),
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
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Adelanto y precio personalizado
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información Financiera',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adelantoController,
                        decoration: const InputDecoration(
                          labelText: 'Adelanto',
                          prefixIcon: Icon(Icons.attach_money_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _totalPersonalizadoController,
                        decoration: const InputDecoration(
                          labelText: 'Precio personalizado',
                          prefixIcon: Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                TextFormField(
                  controller: _notasController,
                  decoration: const InputDecoration(
                    labelText: 'Notas adicionales',
                    prefixIcon: Icon(Icons.note_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalActionButtons() {
    final isEnabled = _clienteSeleccionado != null && _trabajosEnOrden.isNotEmpty;
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isCreatingOrder = false;
              });
            },
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Volver a Cotizar'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isEnabled ? _guardarOrden : null,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Crear Orden de Trabajo'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 52),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final isEnabled = _clienteSeleccionado != null && _trabajosEnOrden.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _guardarOrden : null,
        icon: const Icon(Icons.save_rounded),
        label: const Text('Guardar Orden de Trabajo'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
        ),
      ),
    );
  }

  Widget _buildAddWorkSection(List<Trabajo> trabajosDisponibles) {
    // Filtrar trabajos únicos manualmente
    final uniqueTrabajos = <String, Trabajo>{};
    for (var trabajo in trabajosDisponibles) {
      uniqueTrabajos[trabajo.id] = trabajo;
    }
    final trabajosUnicos = uniqueTrabajos.values.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar Trabajo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AppSpacing.verticalMD,
            
            // Dropdown para tipo de trabajo
            DropdownSearch<Trabajo>(
              items: (filter, infiniteScrollProps) => trabajosUnicos,
              selectedItem: _trabajoSeleccionado,
              itemAsString: (Trabajo trabajo) => trabajo.nombre,
              compareFn: (Trabajo trabajo1, Trabajo trabajo2) => trabajo1.id == trabajo2.id,
              onChanged: (Trabajo? newValue) {
                setState(() {
                  _trabajoSeleccionado = newValue;
                });
              },
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Tipo de Trabajo',
                  prefixIcon: Icon(Icons.work_rounded),
                  hintText: 'Buscar tipo de trabajo...',
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Buscar tipo de trabajo...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            AppSpacing.verticalMD,

            // Fila con dimensiones
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anchoController,
                    decoration: const InputDecoration(
                      labelText: 'Ancho (m)',
                      prefixIcon: Icon(Icons.straighten_rounded),
                      hintText: '1.0',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: TextFormField(
                    controller: _altoController,
                    decoration: const InputDecoration(
                      labelText: 'Alto (m)',
                      prefixIcon: Icon(Icons.height_rounded),
                      hintText: '1.0',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    onChanged: (v) => setState(() {}),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMD,

            // Fila con cantidad y adicional
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      prefixIcon: Icon(Icons.numbers_rounded),
                      hintText: '1',
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
                      labelText: 'Adicional (Bs)',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                      hintText: '0.0',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    onChanged: (v) => setState(() {}),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMD,

            // Subtotal
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: AppBorders.borderRadiusSM,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Subtotal:",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    "Bs ${_subtotalActual.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalMD,

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

  Widget _buildWorkList(List<Trabajo> trabajosDisponibles) {
    if (_trabajosEnOrden.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(
                Icons.work_off_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              AppSpacing.verticalMD,
              Text(
                'Aún no hay trabajos en esta orden',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSM,
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
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trabajos en la Orden',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AppSpacing.verticalMD,
            
            // Lista de trabajos
            ...List.generate(_trabajosEnOrden.length, (index) {
              final item = _trabajosEnOrden[index];
              
              return Card(
                margin: EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: AppBorders.borderRadiusSM,
                    ),
                    child: Icon(
                      Icons.work_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text('${item.trabajo?.nombre ?? 'Trabajo sin nombre'} (${item.cantidad}x)'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dimensiones: ${item.ancho}m x ${item.alto}m (${(item.ancho * item.alto).toStringAsFixed(2)} m²)'),
                      if (item.adicional > 0)
                        Text('Adicional: Bs ${item.adicional.toStringAsFixed(2)}'),
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Chip(
                            label: Text('${item.cantidad}x'),
                            backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                      AppSpacing.horizontalSM,
                      IconButton(
                        icon: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _showDeleteConfirmation(index),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                  onTap: () => _editTrabajoEnOrden(index, trabajosDisponibles),
                ),
              );
            }),

            // Total de trabajos
            if (_trabajosEnOrden.isNotEmpty) ...[
              AppSpacing.verticalMD,
              const Divider(),
              AppSpacing.verticalMD,
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: AppBorders.borderRadiusSM,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total de Trabajos:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Bs ${_trabajosEnOrden.fold(0.0, (sum, item) => sum + item.precioFinal).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
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

  Widget _buildSummaryAndClientSection(List<Cliente> clientesDisponibles) {
    double totalBruto = _trabajosEnOrden.fold(0.0, (p, e) => p + e.precioFinal);
    final totalPersonalizado = double.tryParse(_totalPersonalizadoController.text);
    double rebaja = 0.0;
    if (totalPersonalizado != null && totalPersonalizado < totalBruto) {
      rebaja = totalBruto - totalPersonalizado;
    }

    // Filtrar clientes únicos manualmente
    final uniqueClientes = <String, Cliente>{};
    for (var cliente in clientesDisponibles) {
      uniqueClientes[cliente.id] = cliente;
    }
    final clientesUnicos = uniqueClientes.values.toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen y Cliente',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AppSpacing.verticalMD,
            
            // Selección de cliente
            DropdownSearch<Cliente>(
              items: (filter, infiniteScrollProps) => clientesUnicos,
              selectedItem: _clienteSeleccionado,
              itemAsString: (Cliente cliente) => cliente.nombre,
              compareFn: (Cliente cliente1, Cliente cliente2) => cliente1.id == cliente2.id,
              onChanged: (Cliente? newValue) {
                setState(() {
                  _clienteSeleccionado = newValue;
                });
              },
              validator: (value) => value == null ? 'Seleccione un cliente' : null,
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Cliente',
                  prefixIcon: Icon(Icons.person_rounded),
                  hintText: 'Buscar cliente...',
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
            AppSpacing.verticalMD,

            // Campos financieros
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalPersonalizadoController,
                    decoration: const InputDecoration(
                      labelText: 'Total Personalizado (Bs)',
                      prefixIcon: Icon(Icons.edit_rounded),
                      hintText: 'Opcional',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: TextFormField(
                    controller: _adelantoController,
                    decoration: const InputDecoration(
                      labelText: 'Adelanto (Bs)',
                      prefixIcon: Icon(Icons.payment_rounded),
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    onChanged: (v) => setState(() {}),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMD,

            // Notas
            TextFormField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                prefixIcon: Icon(Icons.note_rounded),
                hintText: 'Información adicional...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            AppSpacing.verticalMD,

            // Fecha y hora de entrega
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fechaEntrega,
                          firstDate: DateTime(2020, 1, 1),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _fechaEntrega = picked);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded),
                            SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fecha de Entrega'),
                                Text(
                                  '${_fechaEntrega.day}/${_fechaEntrega.month}/${_fechaEntrega.year}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _horaEntrega,
                        );
                        if (picked != null) {
                          setState(() => _horaEntrega = picked);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded),
                            SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hora de Entrega'),
                                Text(
                                  _horaEntrega.format(context),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMD,

            // Resumen financiero
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: AppBorders.borderRadiusSM,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Total Bruto:', totalBruto, false),
                  if (rebaja > 0) ...[
                    AppSpacing.verticalSM,
                    _buildPriceRow('Rebaja:', rebaja, false, color: Colors.orange),
                  ],
                  AppSpacing.verticalSM,
                  const Divider(),
                  AppSpacing.verticalSM,
                  _buildPriceRow('Total Final:', _totalOrden, true),
                  if (double.tryParse(_adelantoController.text) != null &&
                      double.tryParse(_adelantoController.text)! > 0) ...[
                    AppSpacing.verticalSM,
                    _buildPriceRow('Adelanto:', double.tryParse(_adelantoController.text) ?? 0, false, color: Theme.of(context).colorScheme.primary),
                    AppSpacing.verticalSM,
                    _buildPriceRow('Saldo:', _totalOrden - (double.tryParse(_adelantoController.text) ?? 0), false, color: Theme.of(context).colorScheme.secondary),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
