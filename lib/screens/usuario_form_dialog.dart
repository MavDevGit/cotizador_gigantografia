
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';

class UsuarioFormDialog extends StatefulWidget {
  final Usuario? usuario;
  const UsuarioFormDialog({super.key, this.usuario});

  @override
  _UsuarioFormDialogState createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre;
  late String _email;
  late String _rol;
  late String _password;

  @override
  void initState() {
    super.initState();
    _nombre = widget.usuario?.nombre ?? '';
    _email = widget.usuario?.email ?? '';
    _rol = widget.usuario?.rol ?? 'empleado';
    _password = widget.usuario?.password ?? '';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final appState = Provider.of<AppState>(context, listen: false);
      String passwordToSave = _password;
      // Si estamos editando y el campo de contraseña está vacío, conservar la anterior
      if (widget.usuario != null && (_password.isEmpty || _password.trim().isEmpty)) {
        passwordToSave = widget.usuario!.password;
      }
      final newUsuario = Usuario(
        id: widget.usuario?.id ?? Random().nextDouble().toString(),
        nombre: _nombre,
        email: _email,
        rol: _rol,
        password: passwordToSave, // Solo cambia si se ingresó una nueva
        negocioId: appState.currentUser!.negocioId,
        creadoEn: widget.usuario?.creadoEn ?? DateTime.now(),
      );

      if (widget.usuario == null) {
        appState.addUsuario(newUsuario);
      } else {
        appState.updateUsuario(newUsuario);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return AlertDialog(
      title:
          Text(widget.usuario == null ? 'Nuevo Usuario' : 'Editar Usuario'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _nombre,
              decoration: InputDecoration(
                labelText: 'Nombre',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              onSaved: (v) => _nombre = v!,
            ),
            TextFormField(
              initialValue: _email,
              decoration: InputDecoration(
                labelText: 'Email (login)',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) => v!.isEmpty ? 'Email inválido' : null,
              onSaved: (v) => _email = v!,
            ),
            TextFormField(
              initialValue: _password,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              onSaved: (v) => _password = v!,
              obscureText: true,
            ),
            DropdownButtonFormField<String>(
              value: _rol,
              decoration: InputDecoration(
                labelText: 'Rol',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              items: ['admin', 'empleado'].asMap().entries.map((entry) {
                int index = entry.key;
                String rol = entry.value;
                return DropdownMenuItem<String>(
                  key: Key('rol_${rol}_$index'), // Key único con índice
                  value: rol,
                  child: Text(rol.toUpperCase()),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _rol = newValue;
                  });
                }
              },
            )
          ],
        ),
      ),
      actions: [
        if (widget.usuario != null &&
            widget.usuario!.id != appState.currentUser!.id)
          TextButton(
            child: Text('Archivar', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
            onPressed: () {
              Provider.of<AppState>(context, listen: false)
                  .deleteUsuario(widget.usuario!);
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
