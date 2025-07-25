import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/utils.dart';

class UsuarioFormDialog extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final String empresaId;
  final bool isEdit;
  const UsuarioFormDialog({super.key, this.usuario, required this.empresaId, required this.isEdit});

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
  bool _isLoading = false;

  void _showCustomSnackBar(String message, {IconData icon = Icons.info_outline, Color? color}) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color ?? theme.colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: textColor))),
          ],
        ),
        backgroundColor: theme.colorScheme.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          left: 24,
          right: 24,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nombre = widget.usuario?['nombre'] ?? '';
    _email = widget.usuario?['email'] ?? '';
    _rol = widget.usuario?['rol'] ?? 'empleado';
    _password = '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    // Validaciones adicionales como en signup_screen.dart
    if (_nombre.isEmpty) {
      _showCustomSnackBar('El nombre es obligatorio.', icon: Icons.warning_amber_rounded, color: Colors.orange);
      return;
    }
    if (_email.isEmpty || !_email.contains('@')) {
      _showCustomSnackBar('El correo debe ser válido y contener "@".', icon: Icons.email, color: Colors.orange);
      return;
    }
    if (!widget.isEdit && (_password.isEmpty || _password.length < 6)) {
      _showCustomSnackBar('La contraseña debe tener al menos 6 caracteres.', icon: Icons.lock_outline, color: Colors.orange);
      return;
    }
    setState(() => _isLoading = true);
    final client = Supabase.instance.client;
    try {
      if (!widget.isEdit) {
        // Crear usuario en Auth
        final authResponse = await client.auth.signUp(
          email: _email,
          password: _password,
        );
        final authUserId = authResponse.user?.id;
        if (authUserId == null) {
          throw Exception('No se pudo crear el usuario en Auth.');
        }
        // Insertar en tabla usuarios
        final response = await client.from('usuarios').insert({
          'email': _email,
          'nombre': _nombre,
          'rol': _rol,
          'empresa_id': widget.empresaId,
          'auth_user_id': authUserId,
        }).select().single();
        if (response == null) {
          throw Exception('No se pudo crear el usuario en la base de datos.');
        }
        if (!mounted) return;
        Navigator.of(context).pop(true);
        _showCustomSnackBar('Usuario creado correctamente.', icon: Icons.check_circle, color: Colors.green);
      } else {
        // Actualizar usuario en tabla usuarios
        final response = await client.from('usuarios').update({
          'email': _email,
          'nombre': _nombre,
          'rol': _rol,
        }).eq('id', widget.usuario!['id']).select().single();
        if (response == null) {
          throw Exception('No se pudo actualizar el usuario.');
        }
        if (!mounted) return;
        Navigator.of(context).pop(true);
        _showCustomSnackBar('Usuario actualizado correctamente.', icon: Icons.check_circle, color: Colors.green);
      }
    } catch (e) {
      _showCustomSnackBar('Error: $e', icon: Icons.error, color: Colors.red);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        widget.isEdit ? 'Editar Usuario' : 'Nuevo Usuario',
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
            if (!widget.isEdit)
              TextFormField(
                initialValue: _password,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
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
                  if (!widget.isEdit && (v == null || v.isEmpty)) {
                    return 'Campo requerido';
                  }
                  return null;
                },
                onSaved: (v) => _password = v ?? '',
                obscureText: _obscurePassword,
              ),
            if (widget.isEdit)
              const SizedBox.shrink(),
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
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}