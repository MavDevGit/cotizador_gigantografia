import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/utils.dart';

class VerificandoScreen extends StatefulWidget {
  final String email;
  final String mensaje;
  
  const VerificandoScreen({
    Key? key, 
    required this.email,
    this.mensaje = 'Verificando tu cuenta...',
  }) : super(key: key);

  @override
  State<VerificandoScreen> createState() => _VerificandoScreenState();
}

class _VerificandoScreenState extends State<VerificandoScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  int _tiempoRestante = 60; // 60 segundos para reenvío
  bool _puedeReenviar = false;
  bool _isReenviando = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _iniciarContador();
  }

  void _iniciarContador() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _tiempoRestante--;
        });
        if (_tiempoRestante > 0) {
          _iniciarContador();
        } else {
          setState(() {
            _puedeReenviar = true;
          });
        }
      }
    });
  }

  Future<void> _reenviarEmail() async {
    if (!_puedeReenviar || _isReenviando) return;
    
    setState(() {
      _isReenviando = true;
    });
    
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          'Email de verificación reenviado correctamente',
        );
        
        // Reiniciar contador
        setState(() {
          _tiempoRestante = 60;
          _puedeReenviar = false;
          _isReenviando = false;
        });
        _iniciarContador();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Error al reenviar el email. Intenta nuevamente.',
        );
        setState(() {
          _isReenviando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Icono animado
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 2 * 3.14159,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Título principal
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.7 + (_pulseController.value * 0.3),
                    child: Text(
                      widget.mensaje,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Instrucciones
              Text(
                'Hemos enviado un enlace de verificación a:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Email del usuario
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Instrucciones detalladas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInstruccion(
                      icon: Icons.email_outlined,
                      texto: 'Revisa tu bandeja de entrada',
                    ),
                    const SizedBox(height: 8),
                    _buildInstruccion(
                      icon: Icons.touch_app_outlined,
                      texto: 'Haz clic en el enlace de verificación',
                    ),
                    const SizedBox(height: 8),
                    _buildInstruccion(
                      icon: Icons.check_circle_outline,
                      texto: 'Tu cuenta se activará automáticamente',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Contador y botón de reenvío
              if (_puedeReenviar)
                Column(
                  children: [
                    Text(
                      '¿No recibiste el email?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isReenviando ? null : _reenviarEmail,
                        icon: _isReenviando 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                        label: Text(_isReenviando ? 'Reenviando...' : 'Reenviar Email'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Puedes reenviar el email en $_tiempoRestante segundos',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Indicador de carga
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Esperando verificación...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Botón para volver al login
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Volver al inicio de sesión',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruccion({
    required IconData icon,
    required String texto,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
} 