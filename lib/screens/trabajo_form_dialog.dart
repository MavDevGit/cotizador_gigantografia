import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  late double _ancho;
  late double _alto;
  late int _cantidad;
  late double _adicional;

  bool get isOrderJob => widget.trabajoEnOrden != null || widget.onSave != null;

  @override
  void initState() {
    super.initState();
    if (isOrderJob) {
      _selectedTrabajo = widget.trabajoEnOrden?.trabajo;
      _ancho = widget.trabajoEnOrden?.ancho ?? 1.0;
      _alto = widget.trabajoEnOrden?.alto ?? 1.0;
      _cantidad = widget.trabajoEnOrden?.cantidad ?? 1;
      _adicional = widget.trabajoEnOrden?.adicional ?? 0.0;
    } else {
      _nombre = widget.trabajo?.nombre ?? '';
      _precioM2 = widget.trabajo?.precioM2 ?? 0.0;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (isOrderJob) {
        final newOrderJob = OrdenTrabajoTrabajo(
          id: widget.trabajoEnOrden?.id ?? Random().nextDouble().toString(),
          trabajo: _selectedTrabajo!,
          ancho: _ancho,
          alto: _alto,
          cantidad: _cantidad,
          adicional: _adicional,
        );
        widget.onSave!(newOrderJob);
      } else {
        final appState = Provider.of<AppState>(context, listen: false);
        if (widget.trabajo == null) {
          // Crear nuevo trabajo
          final newTrabajo = Trabajo(
              id: Random().nextDouble().toString(),
              nombre: _nombre,
              precioM2: _precioM2,
              negocioId: appState.currentUser!.negocioId,
              creadoEn: DateTime.now());
          appState.addTrabajo(newTrabajo);
        } else {
          // Actualizar trabajo existente
          widget.trabajo!.nombre = _nombre;
          widget.trabajo!.precioM2 = _precioM2;
          appState.updateTrabajo(widget.trabajo!);
        }
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isOrderJob
          ? (widget.trabajoEnOrden == null
              ? 'Añadir Trabajo a Orden'
              : 'Editar Trabajo de Orden')
          : (widget.trabajo == null
              ? 'Nuevo Tipo de Trabajo'
              : 'Editar Tipo de Trabajo')),
      content: Form(
        key: _formKey,
        child: isOrderJob ? _buildOrderJobForm() : _buildJobTypeForm(),
      ),
      actions: [
        if (!isOrderJob && widget.trabajo != null)
          TextButton(
            child: Text('Archivar', style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              Provider.of<AppState>(context, listen: false)
                  .deleteTrabajo(widget.trabajo!);
              Navigator.of(context).pop();
            },
          ),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }

  Widget _buildJobTypeForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          initialValue: _nombre,
          decoration: const InputDecoration(labelText: 'Nombre del Trabajo'),
          validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
          onSaved: (v) => _nombre = v!,
        ),
        FormSpacing.verticalMedium(),
        TextFormField(
          initialValue: _precioM2.toString(),
          decoration: const InputDecoration(labelText: 'Precio por m²'),
          keyboardType: TextInputType.number,
          validator: (v) =>
              (double.tryParse(v!) == null) ? 'Número inválido' : null,
          onSaved: (v) => _precioM2 = double.parse(v!),
        ),
      ],
    );
  }

  Widget _buildOrderJobForm() {
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
            decoration: InputDecoration(labelText: 'Tipo de Trabajo'),
            validator: (v) => v == null ? 'Seleccione un trabajo' : null,
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _ancho.toString(),
            decoration: const InputDecoration(labelText: 'Ancho (m)'),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (double.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _ancho = double.parse(v!),
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _alto.toString(),
            decoration: const InputDecoration(labelText: 'Alto (m)'),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (double.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _alto = double.parse(v!),
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _cantidad.toString(),
            decoration: const InputDecoration(labelText: 'Cantidad'),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (int.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _cantidad = int.parse(v!),
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _adicional.toString(),
            decoration: const InputDecoration(labelText: 'Adicional (\$)'),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (double.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _adicional = double.parse(v!),
          ),
        ],
      ),
    );
  }
}
