import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icons_plus/icons_plus.dart';

import '../app_state/app_state.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _obscureText = true;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _hasEmailError = false;
  bool _hasPasswordError = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.defaultCurve,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.defaultCurve,
    ));
    
    // Listeners para validación en tiempo real
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    
    // Iniciar animación
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _isEmailValid = false;
        _hasEmailError = false;
        _emailError = null;
      } else if (!email.contains('@') || !email.contains('.')) {
        _isEmailValid = false;
        _hasEmailError = true;
        _emailError = 'Formato de email inválido';
      } else {
        _isEmailValid = true;
        _hasEmailError = false;
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      if (password.isEmpty) {
        _isPasswordValid = false;
        _hasPasswordError = false;
        _passwordError = null;
      } else if (password.length < 6) {
        _isPasswordValid = false;
        _hasPasswordError = true;
        _passwordError = 'Mínimo 6 caracteres';
      } else {
        _isPasswordValid = true;
        _hasPasswordError = false;
        _passwordError = null;
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      AppFeedback.hapticFeedback(HapticType.medium);
      return;
    }

    if (!_isEmailValid || !_isPasswordValid) {
      AppFeedback.showWarning(
        context,
        'Por favor corrige los errores antes de continuar',
      );
      AppFeedback.hapticFeedback(HapticType.medium);
      return;
    }

    setState(() => _isLoading = true);
    AppFeedback.hapticFeedback(HapticType.light);

    try {
      final success = await Provider.of<AppState>(context, listen: false)
          .login(_emailController.text.trim(), _passwordController.text);

      if (!mounted) return;

      if (success) {
        AppFeedback.hapticFeedback(HapticType.medium);
        AppFeedback.showSuccess(context, '¡Bienvenido!');
        
        // Usar transición animada
        AppNavigator.pushReplacement(
          context,
          const MainScreen(),
          type: TransitionType.fade,
        );
      } else {
        AppFeedback.hapticFeedback(HapticType.heavy);
        AppFeedback.showError(
          context,
          'Credenciales incorrectas. Verifica tu email y contraseña.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.hapticFeedback(HapticType.heavy);
        AppFeedback.showError(
          context,
          'Error de conexión. Verifica tu internet e inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final isDark = appState.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: AppStatusChip(
              label: isDark ? 'Oscuro' : 'Claro',
              status: StatusType.neutral,
              icon: isDark ? Icons.dark_mode : Icons.light_mode,
              onTap: () {
                AppFeedback.hapticFeedback(HapticType.selection);
                appState.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 450 : 400,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header con Hero logo
                        DelayedAnimation(
                          delay: 100,
                          type: AnimationType.fadeIn,
                          child: Column(
                            children: [
                              Hero(
                                tag: 'app_logo',
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.calculate_rounded,
                                    size: 40,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              AppSpacing.verticalLG,
                              Text(
                                'Bienvenido',
                                style: AppTextStyles.heading2(context),
                                textAlign: TextAlign.center,
                              ),
                              AppSpacing.verticalSM,
                              Text(
                                'Accede a tu cuenta de forma segura',
                                style: AppTextStyles.subtitle1(context).copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        AppSpacing.verticalXXL,

                        // Email Field con validación
                        DelayedAnimation(
                          delay: 300,
                          type: AnimationType.slideUp,
                          child: AppTextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            label: 'Correo electrónico',
                            hint: 'Ingresa tu correo',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Este campo es requerido';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              // La validación ya se hace en el listener
                            },
                          ),
                        ),

                        AppSpacing.verticalLG,

                        // Password Field con validación
                        DelayedAnimation(
                          delay: 400,
                          type: AnimationType.slideUp,
                          child: AppTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            label: 'Contraseña',
                            hint: 'Ingresa tu contraseña',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: _obscureText 
                                ? Icons.visibility_off 
                                : Icons.visibility,
                            onSuffixTap: () {
                              setState(() => _obscureText = !_obscureText);
                              AppFeedback.hapticFeedback(HapticType.selection);
                            },
                            obscureText: _obscureText,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Este campo es requerido';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              // La validación ya se hace en el listener
                            },
                          ),
                        ),

                        AppSpacing.verticalLG,

                        // Forgot Password Link
                        DelayedAnimation(
                          delay: 500,
                          type: AnimationType.fadeIn,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                AppFeedback.hapticFeedback(HapticType.light);
                                // TODO: Implementar recuperación de contraseña
                              },
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: AppTextStyles.body2(context).copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),

                        AppSpacing.verticalLG,

                        // Login Button
                        DelayedAnimation(
                          delay: 600,
                          type: AnimationType.slideUp,
                          child: AppButton(
                            text: 'Iniciar Sesión',
                            onPressed: _isLoading ? null : _login,
                            isLoading: _isLoading,
                            icon: Icons.login_rounded,
                            size: ButtonSize.large,
                            width: double.infinity,
                          ),
                        ),

                        AppSpacing.verticalXXL,

                        // Register Link
                        DelayedAnimation(
                          delay: 700,
                          type: AnimationType.fadeIn,
                          child: TextButton(
                            onPressed: () {
                              AppFeedback.hapticFeedback(HapticType.light);
                              AppNavigator.push(
                                context,
                                const SignupScreen(),
                                type: TransitionType.slide,
                              );
                            },
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                text: '¿No tienes cuenta? ',
                                style: AppTextStyles.body2(context),
                                children: [
                                  TextSpan(
                                    text: 'Regístrate',
                                    style: AppTextStyles.body2(context).copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }
}
