import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class ClienteFormDialog extends StatefulWidget {
  final Cliente? cliente;
  const ClienteFormDialog({super.key, this.cliente});

  @override
  _ClienteFormDialogState createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre;
  late String _contacto;

  @override
  void initState() {
    super.initState();
    _nombre = widget.cliente?.nombre ?? '';
    _contacto = widget.cliente?.contacto ?? '';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final appState = Provider.of<AppState>(context, listen: false);

      if (widget.cliente == null) {
        // Crear nuevo cliente
        final newCliente = Cliente(
          id: Random().nextDouble().toString(),
          nombre: _nombre,
          contacto: _contacto,
          negocioId: appState.currentUser!.negocioId,
          creadoEn: DateTime.now(),
        );
        appState.addCliente(newCliente);
      } else {
        // Actualizar cliente existente
        widget.cliente!.nombre = _nombre;
        widget.cliente!.contacto = _contacto;
        appState.updateCliente(widget.cliente!);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _nombre,
              decoration:
                  const InputDecoration(labelText: 'Nombre del Cliente'),
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              onSaved: (v) => _nombre = v!,
            ),
            FormSpacing.verticalMedium(),
            TextFormField(
              initialValue: _contacto,
              decoration: const InputDecoration(
                  labelText: 'Contacto (Teléfono, Email, etc.)'),
              onSaved: (v) => _contacto = v!,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.cliente != null)
          TextButton(
            child: Text('Archivar', style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              Provider.of<AppState>(context, listen: false)
                  .deleteCliente(widget.cliente!);
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
}
