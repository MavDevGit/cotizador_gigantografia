import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:uuid/uuid.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../core/design_system/design_tokens.dart';
import 'screens.dart';

class CotizarScreenLegacy extends StatefulWidget {
  const CotizarScreenLegacy({super.key});

  @override
  _CotizarScreenLegacyState createState() => _CotizarScreenLegacyState();
}

class _CotizarScreenLegacyState extends State<CotizarScreenLegacy> {
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

    // Validaciones
    if (ancho <= 0 || alto <= 0) {
      AppFeedback.showWarning(
        context,
        'Las dimensiones deben ser mayores a 0',
      );
      AppFeedback.hapticFeedback(HapticType.medium);
      return;
    }

    if (cantidad <= 0) {
      AppFeedback.showWarning(
        context,
        'La cantidad debe ser mayor a 0',
      );
      AppFeedback.hapticFeedback(HapticType.medium);
      return;
    }

    setState(() {
      _trabajosEnOrden.add(OrdenTrabajoTrabajo(
        id: const Uuid().v4(), // Usar UUID válido
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

    // Feedback de éxito
    AppFeedback.hapticFeedback(HapticType.light);
    AppFeedback.showToast(
      context,
      message: 'Trabajo agregado a la orden',
      type: ToastType.success,
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
          AppFeedback.hapticFeedback(HapticType.light);
          AppFeedback.showToast(
            context,
            message: 'Trabajo actualizado',
            type: ToastType.success,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(int index) async {
    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: 'Eliminar trabajo',
      message: '¿Estás seguro de que deseas eliminar este trabajo de la orden?',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmColor: AppColors.getError(context),
      icon: Icons.delete_rounded,
    );

    if (confirmed == true) {
      setState(() {
        _trabajosEnOrden.removeAt(index);
      });
      AppFeedback.hapticFeedback(HapticType.medium);
      AppFeedback.showToast(
        context,
        message: 'Trabajo eliminado de la orden',
        type: ToastType.info,
      );
    }
  }

  void _guardarOrden() async {
    if (!_formKey.currentState!.validate()) {
      AppFeedback.hapticFeedback(HapticType.medium);
      return;
    }

    if (_clienteSeleccionado == null) {
      AppFeedback.showWarning(
        context,
        'Por favor, selecciona un cliente para continuar',
      );
      AppFeedback.hapticFeedback(HapticType.medium);
      return;
    }

    if (_trabajosEnOrden.isEmpty) {
      AppFeedback.showWarning(
        context,
        'Añade al menos un trabajo a la orden para continuar',
      );
      AppFeedback.hapticFeedback(HapticType.medium);
      return;
    }

    // Mostrar loading
    AppFeedback.showLoadingDialog(context, message: 'Guardando orden...');
    AppFeedback.hapticFeedback(HapticType.light);

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      final totalPersonalizadoValue =
          double.tryParse(_totalPersonalizadoController.text);
      final adelantoValue = double.tryParse(_adelantoController.text) ?? 0.0;
      final notasValue = _notasController.text;

      final ordenId = const Uuid().v4(); // Generar ID una sola vez

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
        AppFeedback.hideLoadingDialog(context);
        
        // Mostrar éxito con haptic feedback
        AppFeedback.hapticFeedback(HapticType.medium);
        AppFeedback.showSuccess(
          context,
          'Orden guardada exitosamente',
          actionLabel: 'Ver órdenes',
          onAction: () {
            // Navegar a la pantalla de órdenes
            Navigator.of(context).pushNamed('/ordenes');
          },
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
        AppFeedback.hideLoadingDialog(context);
        AppFeedback.hapticFeedback(HapticType.heavy);
        AppFeedback.showError(
          context,
          'Error al guardar la orden: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _dataFuture, // Usar el Future memoizado
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
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error al cargar datos: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final trabajosDisponibles = (snapshot.data?[0] as List<Trabajo>?) ?? [];
        final clientesDisponibles = (snapshot.data?[1] as List<Cliente>?) ?? [];

        return Scaffold(
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  _buildAddWorkSection(trabajosDisponibles),
                  AppSpacing.verticalXL,
                  _buildWorkList(trabajosDisponibles),
                  AppSpacing.verticalXL,
                  _buildSummaryAndClientSection(clientesDisponibles),
                  AppSpacing.verticalXXL,
                  _buildSaveButton(),
                  AppSpacing.verticalXXL,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    final isEnabled = _clienteSeleccionado != null && _trabajosEnOrden.isNotEmpty;
    
    return Center(
      child: AppButton(
        text: 'Guardar Orden de Trabajo',
        icon: Icons.save_rounded,
        onPressed: isEnabled ? _guardarOrden : null,
        size: ButtonSize.large,
        width: ResponsiveBreakpoints.isMobile(context) ? double.infinity : 300,
      ),
    );
  }

  Card _buildAddWorkSection(List<Trabajo> trabajosDisponibles) {
    // Filtrar trabajos únicos manualmente
    final uniqueTrabajos = <String, Trabajo>{};
    for (var trabajo in trabajosDisponibles) {
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

  Widget _buildWorkList(List<Trabajo> trabajosDisponibles) {
    if (_trabajosEnOrden.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          icon: Icons.work_off_rounded,
          title: 'Aún no hay trabajos en esta orden',
          subtitle: 'Agrega trabajos usando el formulario superior',
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lista de trabajos
          ...List.generate(_trabajosEnOrden.length, (index) {
            final item = _trabajosEnOrden[index];
            final theme = Theme.of(context);
            
            return DelayedAnimation(
              delay: index * 100,
              type: AnimationType.slideUp,
              child: Container(
                margin: EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  isClickable: true,
                  onTap: () => _editTrabajoEnOrden(index, trabajosDisponibles),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(AppSpacing.md),
                    leading: Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                      ),
                      child: Icon(
                        Icons.work_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: AppConstants.iconSizeSmall,
                      ),
                    ),
                    title: Text(
                      '${item.trabajo?.nombre ?? 'Trabajo sin nombre'} (${item.cantidad}x)',
                      style: AppTextStyles.subtitle2(context),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSpacing.verticalXS,
                        Text(
                          'Dimensiones: ${item.ancho}m x ${item.alto}m (${(item.ancho * item.alto).toStringAsFixed(2)} m²)',
                          style: AppTextStyles.caption(context),
                        ),
                        if (item.adicional > 0) ...[
                          AppSpacing.verticalXS,
                          Text(
                            'Adicional: Bs ${item.adicional.toStringAsFixed(2)}',
                            style: AppTextStyles.caption(context).copyWith(
                              color: AppColors.getInfo(context),
                            ),
                          ),
                        ],
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
                              style: AppTextStyles.price(context),
                            ),
                            AppSpacing.verticalXS,
                            AppStatusChip(
                              label: '${item.cantidad}x',
                              status: StatusType.info,
                            ),
                          ],
                        ),
                        AppSpacing.horizontalSM,
                        IconButton(
                          icon: Icon(
                            Icons.delete_rounded,
                            color: AppColors.getError(context),
                            size: AppConstants.iconSizeSmall,
                          ),
                          onPressed: () {
                            AppFeedback.hapticFeedback(HapticType.medium);
                            _showDeleteConfirmation(index);
                          },
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Total de trabajos
          if (_trabajosEnOrden.isNotEmpty) ...[
            AppSpacing.verticalMD,
            Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            AppSpacing.verticalMD,
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total de Trabajos:',
                    style: AppTextStyles.subtitle2(context),
                  ),
                  Text(
                    'Bs ${_trabajosEnOrden.fold(0.0, (sum, item) => sum + item.precioFinal).toStringAsFixed(2)}',
                    style: AppTextStyles.price(context, isLarge: true),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryAndClientSection(List<Cliente> clientesDisponibles) {
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
    for (var cliente in clientesDisponibles) {
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
