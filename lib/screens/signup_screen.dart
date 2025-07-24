
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state/app_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}


class _SignupScreenState extends State<SignupScreen> {
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyController = TextEditingController();
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isLoading = false;

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final company = _companyController.text.trim();
    final nombre = email.split('@').first;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || company.isEmpty) {
      _showCustomSnackBar('Completa todos los campos', icon: Icons.warning_amber_rounded, color: Colors.orange);
      return;
    }
    if (!email.contains('@')) {
      _showCustomSnackBar('El correo debe contener "@"', icon: Icons.email, color: Colors.orange);
      return;
    }
    if (password.length < 6 || confirmPassword.length < 6) {
      _showCustomSnackBar('La contraseña debe tener al menos 6 caracteres', icon: Icons.lock_outline, color: Colors.orange);
      return;
    }
    if (password != confirmPassword) {
      _showCustomSnackBar('Las contraseñas no coinciden', icon: Icons.lock_person_rounded, color: Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'cotizador://auth/callback',
      );
      if (response.user != null) {
        // Guardar datos temporales para usarlos tras la confirmación
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_empresa', company);
        await prefs.setString('pending_nombre', nombre);
        await prefs.setString('pending_email', email);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Revisa tu correo para confirmar el registro.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        _showCustomSnackBar('Error al registrar. Intenta de nuevo.', icon: Icons.error, color: Colors.red);
      }
    } catch (e) {
      _showCustomSnackBar('Error: ${e.toString()}', icon: Icons.error, color: Colors.red);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final isDark = appState.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ActionChip(
              avatar: Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 20),
              label: Text(isDark ? 'Oscuro' : 'Claro'),
              onPressed: () {
                appState.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
              },
              backgroundColor: theme.chipTheme.backgroundColor,
              labelStyle: theme.chipTheme.labelStyle,
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 450 : 400, minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crear Cuenta',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Únete y gestiona tus proyectos fácilmente',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                      keyboardType: TextInputType.visiblePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmText,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmText ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscureConfirmText = !_obscureConfirmText),
                        ),
                      ),
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Empresa',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      keyboardType: TextInputType.text,
                      autofillHints: const [AutofillHints.organizationName],
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: _isLoading ? null : _signup,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Crear Cuenta'),
                    ),
                    const SizedBox(height: 24),

                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('O regístrate con'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Brand(Brands.google, size: 20),
                            label: Text(
                              'Google',
                              style: TextStyle(color: theme.colorScheme.onSurface),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: Brand(Brands.facebook, size: 20),
                            label: Text(
                              'Facebook',
                              style: TextStyle(color: theme.colorScheme.onSurface),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: '¿Ya tienes cuenta? ',
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: 'Inicia sesión',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
