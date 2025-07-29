import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class TrabajoFormDialog extends StatefulWidget {
  final Trabajo? trabajo;
  final OrdenTrabajoTrabajo? trabajoEnOrden;
  final Function(OrdenTrabajoTrabajo)? onSave;
  final List<Trabajo>? availableTrabajos;

  const TrabajoFormDialog({
    super.key,
    this.trabajo,
    this.trabajoEnOrden,
    this.onSave,
    this.availableTrabajos,
  });

  @override
  _TrabajoFormDialogState createState() => _TrabajoFormDialogState();
}

class _TrabajoFormDialogState extends State<TrabajoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // For new/editing job types
  late String _nombre;
  late double _precioM2;

  // For jobs within an order
  Trabajo? _selectedTrabajo;
  double? _ancho;
  double? _alto;
  late int _cantidad;
  late double _adicional;

  bool get isOrderJob => widget.trabajoEnOrden != null || widget.onSave != null;

  @override
  void initState() {
    super.initState();
    if (isOrderJob) {
      _selectedTrabajo = widget.trabajoEnOrden?.trabajo;
      // Si es para editar, usar valores existentes; si es para añadir, dejar nulo para placeholder
      if (widget.trabajoEnOrden != null) {
        _ancho = widget.trabajoEnOrden!.ancho;
        _alto = widget.trabajoEnOrden!.alto;
      } else {
        _ancho = null;
        _alto = null;
      }
      _cantidad = widget.trabajoEnOrden?.cantidad ?? 1;
      _adicional = widget.trabajoEnOrden?.adicional ?? 0.0;
    } else {
      _nombre = widget.trabajo?.nombre ?? '';
      _precioM2 = widget.trabajo?.precioM2 ?? 0.0;
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (isOrderJob) {
        final newOrderJob = OrdenTrabajoTrabajo(
          id: widget.trabajoEnOrden?.id ?? const Uuid().v4(), // Usar UUID válido
          trabajo: _selectedTrabajo!,
          ancho: _ancho ?? 1.0,
          alto: _alto ?? 1.0,
          cantidad: _cantidad,
          adicional: _adicional,
        );
        widget.onSave!(newOrderJob);
      } else {
        final appState = Provider.of<AppState>(context, listen: false);
        
        // Obtener empresaId del usuario actual
        if (appState.currentUser == null) {
          // Mostrar error si no hay usuario autenticado
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No hay usuario autenticado')),
          );
          return;
        }
        
        final empresaId = appState.currentUser!.empresaId;
        
        if (widget.trabajo == null) {
          // Crear nuevo trabajo
          final newTrabajo = Trabajo.legacy(
              id: const Uuid().v4(), // Usar UUID válido
              nombre: _nombre,
              precioM2: _precioM2,
              negocioId: empresaId,
              createdAt: DateTime.now());
          await appState.addTrabajo(newTrabajo);
        } else {
          // Actualizar trabajo existente
          widget.trabajo!.nombre = _nombre;
          widget.trabajo!.precioM2 = _precioM2;
          await appState.updateTrabajo(widget.trabajo!);
        }
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        isOrderJob
            ? (widget.trabajoEnOrden == null
                ? 'Añadir Trabajo a Orden'
                : 'Editar Trabajo de Orden')
            : (widget.trabajo == null
                ? 'Nuevo Tipo de Trabajo'
                : 'Editar Tipo de Trabajo'),
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: isOrderJob ? _buildOrderJobForm() : _buildJobTypeForm(),
      ),
      actions: [
        if (!isOrderJob && widget.trabajo != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Archivar'),
            onPressed: () {
              Provider.of<AppState>(context, listen: false)
                  .deleteTrabajo(widget.trabajo!);
              Navigator.of(context).pop();
            },
          ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildJobTypeForm() {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          initialValue: _nombre,
          decoration: InputDecoration(
            labelText: 'Nombre del Trabajo',
            labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
          onSaved: (v) => _nombre = v!,
        ),
        FormSpacing.verticalMedium(),
        TextFormField(
          initialValue: _precioM2.toString(),
          decoration: InputDecoration(
            labelText: 'Precio por m²',
            labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
          validator: (v) =>
              (double.tryParse(v!) == null) ? 'Número inválido' : null,
          onSaved: (v) => _precioM2 = double.parse(v!),
        ),
      ],
    );
  }

  Widget _buildOrderJobForm() {
    final theme = Theme.of(context);
    // Filtrar trabajos únicos manualmente
    final uniqueTrabajos = <String, Trabajo>{};
    if (widget.availableTrabajos != null) {
      for (var trabajo in widget.availableTrabajos!) {
        uniqueTrabajos[trabajo.id] = trabajo;
      }
    }
    final trabajosUnicos = uniqueTrabajos.values.toList();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Trabajo>(
            value: _selectedTrabajo,
            items: trabajosUnicos.asMap().entries.map((entry) {
              int index = entry.key;
              Trabajo t = entry.value;
              return DropdownMenuItem(
                  key: Key(
                      'trabajo_dialog_${t.id}_$index'), // Key único con índice
                  value: t,
                  child: Text(t.nombre));
            }).toList(),
            onChanged: (val) => setState(() => _selectedTrabajo = val),
            decoration: InputDecoration(
              labelText: 'Tipo de Trabajo',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            validator: (v) => v == null ? 'Seleccione un trabajo' : null,
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _ancho != null ? _ancho.toString() : '',
            decoration: InputDecoration(
              labelText: 'Ancho (m)',
              hintText: 'Ej: 1.0',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            validator: (v) =>
                (double.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _ancho = double.parse(v!),
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _alto != null ? _alto.toString() : '',
            decoration: InputDecoration(
              labelText: 'Alto (m)',
              hintText: 'Ej: 1.0',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            validator: (v) =>
                (double.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _alto = double.parse(v!),
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _cantidad.toString(),
            decoration: InputDecoration(
              labelText: 'Cantidad',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly
            ],
            validator: (v) =>
                (int.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _cantidad = int.parse(v!),
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _adicional.toString(),
            decoration: InputDecoration(
              labelText: 'Adicional (Bs)',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            validator: (v) =>
                (double.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _adicional = double.parse(v!),
          ),
        ],
      ),
    );
  }
}
