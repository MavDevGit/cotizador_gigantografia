
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state/app_state.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'screens.dart';
import 'verificando_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyController = TextEditingController();
  
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _companyFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isLoading = false;
  
  // Validación en tiempo real
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _isCompanyValid = false;
  
  bool _hasEmailError = false;
  bool _hasPasswordError = false;
  bool _hasConfirmPasswordError = false;
  bool _hasCompanyError = false;
  
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _companyError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.medium,
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
    _confirmPasswordController.addListener(_validateConfirmPassword);
    _companyController.addListener(_validateCompany);
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _companyFocusNode.dispose();
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
        _emailError = 'Ingresa un email válido';
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
    
    // Re-validar confirmación de contraseña si ya tiene texto
    if (_confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }
  }
  
  void _validateConfirmPassword() {
    final confirmPassword = _confirmPasswordController.text;
    final password = _passwordController.text;
    setState(() {
      if (confirmPassword.isEmpty) {
        _isConfirmPasswordValid = false;
        _hasConfirmPasswordError = false;
        _confirmPasswordError = null;
      } else if (confirmPassword != password) {
        _isConfirmPasswordValid = false;
        _hasConfirmPasswordError = true;
        _confirmPasswordError = 'Las contraseñas no coinciden';
      } else {
        _isConfirmPasswordValid = true;
        _hasConfirmPasswordError = false;
        _confirmPasswordError = null;
      }
    });
  }
  
  void _validateCompany() {
    final company = _companyController.text.trim();
    setState(() {
      if (company.isEmpty) {
        _isCompanyValid = false;
        _hasCompanyError = false;
        _companyError = null;
      } else if (company.length < 2) {
        _isCompanyValid = false;
        _hasCompanyError = true;
        _companyError = 'Mínimo 2 caracteres';
      } else {
        _isCompanyValid = true;
        _hasCompanyError = false;
        _companyError = null;
      }
    });
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      AppFeedback.hapticFeedback(HapticType.heavy);
      AppFeedback.showWarning(
        context,
        'Por favor, completa todos los campos correctamente.',
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      AppFeedback.hapticFeedback(HapticType.light);
      
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final company = _companyController.text.trim();
      final nombre = email.split('@').first;

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
        
        if (mounted) {
          AppFeedback.hapticFeedback(HapticType.medium);
          AppFeedback.showSuccess(
            context,
            'Revisa tu correo para confirmar el registro.',
          );
          
          // Navegar a la pantalla de verificación
          AppNavigator.pushReplacement(
            context,
            VerificandoScreen(email: email),
            type: TransitionType.fade,
          );
        }
      } else {
        AppFeedback.hapticFeedback(HapticType.heavy);
        AppFeedback.showError(
          context,
          'Error al registrar. Intenta de nuevo.',
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () {
            AppFeedback.hapticFeedback(HapticType.light);
            Navigator.of(context).pop();
          },
        ),
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 500 : double.infinity,
                    minHeight: MediaQuery.of(context).size.height - 
                        kToolbarHeight - 
                        MediaQuery.of(context).padding.top - 
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? AppSpacing.xxl : AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
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
                                  ),
                                  child: Icon(
                                    Icons.business_rounded,
                                    size: 40,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              AppSpacing.verticalLG,
                              Text(
                                'Crear Cuenta',
                                style: AppTextStyles.heading1(context),
                                textAlign: TextAlign.center,
                              ),
                              AppSpacing.verticalSM,
                              Text(
                                'Únete y gestiona tus proyectos fácilmente',
                                style: AppTextStyles.body1(context).copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        AppSpacing.verticalXXL,

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email
                              DelayedAnimation(
                                delay: 200,
                                type: AnimationType.slideUp,
                                child: AppTextField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  label: 'Correo electrónico',
                                  hint: 'Ingresa tu email',
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

                              // Password
                              DelayedAnimation(
                                delay: 300,
                                type: AnimationType.slideUp,
                                child: AppTextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  label: 'Contraseña',
                                  hint: 'Mínimo 6 caracteres',
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: _obscureText 
                                      ? Icons.visibility_off 
                                      : Icons.visibility,
                                  onSuffixTap: () {
                                    setState(() => _obscureText = !_obscureText);
                                    AppFeedback.hapticFeedback(HapticType.selection);
                                  },
                                  obscureText: _obscureText,
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

                              // Confirm Password
                              DelayedAnimation(
                                delay: 400,
                                type: AnimationType.slideUp,
                                child: AppTextField(
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocusNode,
                                  label: 'Confirmar contraseña',
                                  hint: 'Repite tu contraseña',
                                  prefixIcon: Icons.lock_person_rounded,
                                  suffixIcon: _obscureConfirmText 
                                      ? Icons.visibility_off 
                                      : Icons.visibility,
                                  onSuffixTap: () {
                                    setState(() => _obscureConfirmText = !_obscureConfirmText);
                                    AppFeedback.hapticFeedback(HapticType.selection);
                                  },
                                  obscureText: _obscureConfirmText,
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

                              // Company
                              DelayedAnimation(
                                delay: 500,
                                type: AnimationType.slideUp,
                                child: AppTextField(
                                  controller: _companyController,
                                  focusNode: _companyFocusNode,
                                  label: 'Empresa',
                                  hint: 'Nombre de tu empresa',
                                  prefixIcon: Icons.business_outlined,
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

                              AppSpacing.verticalXXL,

                              // Register Button
                              DelayedAnimation(
                                delay: 600,
                                type: AnimationType.slideUp,
                                child: AppButton(
                                  text: 'Crear Cuenta',
                                  onPressed: _isLoading ? null : _signup,
                                  isLoading: _isLoading,
                                  icon: Icons.person_add_rounded,
                                  size: ButtonSize.large,
                                  width: double.infinity,
                                ),
                              ),

                              AppSpacing.verticalXXL,

                              // Login Link
                              DelayedAnimation(
                                delay: 700,
                                type: AnimationType.fadeIn,
                                child: TextButton(
                                  onPressed: () {
                                    AppFeedback.hapticFeedback(HapticType.light);
                                    Navigator.of(context).pop();
                                  },
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      text: '¿Ya tienes cuenta? ',
                                      style: AppTextStyles.body2(context),
                                      children: [
                                        TextSpan(
                                          text: 'Inicia sesión',
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
