
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
      final newUsuario = Usuario(
        id: widget.usuario?.id ?? Random().nextDouble().toString(),
        nombre: _nombre,
        email: _email,
        rol: _rol,
        password:
            _password, // In a real app, this should be handled more securely
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
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              onSaved: (v) => _nombre = v!,
            ),
            TextFormField(
              initialValue: _email,
              decoration: const InputDecoration(labelText: 'Email (login)'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? 'Email inválido' : null,
              onSaved: (v) => _email = v!,
            ),
            TextFormField(
              initialValue: _password,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              onSaved: (v) => _password = v!,
              obscureText: true,
            ),
            DropdownButtonFormField<String>(
              value: _rol,
              decoration: const InputDecoration(labelText: 'Rol'),
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
            child: Text('Archivar', style: TextStyle(color: Colors.redAccent)),
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
