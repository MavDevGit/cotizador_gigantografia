
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final success = await Provider.of<AppState>(context, listen: false)
        .login(_emailController.text, _passwordController.text);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos.')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo y título
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF98CA3F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.print_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cotizador Pro',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1D29),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestión profesional de gigantografías',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Formulario de login
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person_rounded),
                            hintText: 'Ingresa tu usuario',
                          ),
                          keyboardType: TextInputType.text,
                        ),
                        FormSpacing.verticalLarge(),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_rounded),
                            hintText: 'Ingresa tu contraseña',
                          ),
                          obscureText: true,
                        ),
                        FormSpacing.verticalExtraLarge(),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize:
                                      const Size(double.infinity, 56),
                                ),
                                onPressed: _login,
                                child: const Text('Iniciar Sesión'),
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Información de demo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Credenciales de demo',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Usuario: admin\nContraseña: admin',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue.shade700,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
