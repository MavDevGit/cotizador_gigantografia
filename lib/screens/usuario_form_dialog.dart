import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';

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
  bool _obscurePassword = true;

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

      if (widget.usuario == null) {
        // Crear nuevo usuario
        final newUsuario = Usuario(
          id: Random().nextDouble().toString(),
          nombre: _nombre,
          email: _email,
          rol: _rol,
          password: passwordToSave,
          negocioId: appState.currentUser!.negocioId,
          creadoEn: DateTime.now(),
        );
        appState.addUsuario(newUsuario);
      } else {
        // Actualizar usuario existente
        widget.usuario!.nombre = _nombre;
        widget.usuario!.email = _email;
        widget.usuario!.rol = _rol;
        widget.usuario!.password = passwordToSave;
        appState.updateUsuario(widget.usuario!);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context, listen: false);
    
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        widget.usuario == null ? 'Nuevo Usuario' : 'Editar Usuario',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _nombre,
              decoration: InputDecoration(
                labelText: 'Nombre',
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
              initialValue: _email,
              decoration: InputDecoration(
                labelText: 'Email (login)',
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
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) => v!.isEmpty ? 'Email inválido' : null,
              onSaved: (v) => _email = v!,
            ),
            FormSpacing.verticalMedium(),
            TextFormField(
              initialValue: widget.usuario != null ? '' : _password,
              decoration: InputDecoration(
                labelText: widget.usuario != null ? 'Nueva Contraseña (opcional)' : 'Contraseña',
                labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                hintText: widget.usuario != null ? 'Dejar vacío para mantener la actual' : null,
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
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                ),
              ),
              validator: (v) {
                // Solo requerir contraseña para usuarios nuevos
                if (widget.usuario == null && (v == null || v.isEmpty)) {
                  return 'Campo requerido';
                }
                return null;
              },
              onSaved: (v) => _password = v ?? '',
              obscureText: _obscurePassword,
            ),
            FormSpacing.verticalMedium(),
            DropdownButtonFormField<String>(
              value: _rol,
              decoration: InputDecoration(
                labelText: 'Rol',
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
              items: ['admin', 'empleado'].asMap().entries.map((entry) {
                int index = entry.key;
                String rol = entry.value;
                return DropdownMenuItem<String>(
                  key: Key('rol_${rol}_$index'),
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
            ),
          ],
        ),
      ),
      actions: [
        if (widget.usuario != null &&
            widget.usuario!.id != appState.currentUser!.id)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text('Archivar'),
            onPressed: () {
              Provider.of<AppState>(context, listen: false)
                  .deleteUsuario(widget.usuario!);
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
}