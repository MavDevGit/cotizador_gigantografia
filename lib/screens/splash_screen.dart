import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state/app_state.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    
    _setupSystemUI();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _setupSystemUI() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: AppAnimations.verySlow,
      vsync: this,
    );
    
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: AppAnimations.bounceCurve,
    ));
    
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    // Text animations
    _textController = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: AppAnimations.defaultCurve,
    ));
    
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: AppAnimations.defaultCurve,
    ));
    
    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Background gradient animation
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    // Start logo animation
    _logoController.forward();
    
    // Wait for logo to appear, then start text
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _textController.forward();
    }
    
    // Wait for text to appear, then start progress
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _progressController.repeat();
    }
    
    // Check app initialization and navigate
    await _checkAppReady();
  }

  Future<void> _checkAppReady() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Minimum splash time for UX
    await Future.delayed(const Duration(seconds: 2));
    
    // Wait for app to be initialized
    while (!appState.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (mounted) {
      // Use fade transition to AuthWrapper
      AppNavigator.pushReplacement(
        context,
        const AuthWrapper(),
        type: TransitionType.fade,
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1 * _backgroundAnimation.value),
                  theme.colorScheme.surface,
                  theme.colorScheme.secondary.withOpacity(0.05 * _backgroundAnimation.value),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo animado mejorado
                          DelayedAnimation(
                            delay: 200,
                            type: AnimationType.scale,
                            child: AnimatedBuilder(
                              animation: _logoController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: Opacity(
                                    opacity: _logoOpacityAnimation.value,
                                    child: Hero(
                                      tag: 'app_logo',
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(32),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary.withOpacity(0.4),
                                              blurRadius: 30,
                                              offset: const Offset(0, 15),
                                              spreadRadius: 5,
                                            ),
                                            BoxShadow(
                                              color: theme.colorScheme.primary.withOpacity(0.1),
                                              blurRadius: 60,
                                              offset: const Offset(0, 30),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.calculate_rounded,
                                          size: 70,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          AppSpacing.verticalXXL,
                          
                          // Título con animación de slide
                          SlideTransition(
                            position: _textSlideAnimation,
                            child: FadeTransition(
                              opacity: _textOpacityAnimation,
                              child: Column(
                                children: [
                                  Text(
                                    'Cotizador Pro',
                                    style: AppTextStyles.heading1(context).copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  AppSpacing.verticalMD,
                                  
                                  Text(
                                    'Gestiona tus cotizaciones de\nforma profesional',
                                    style: AppTextStyles.subtitle1(context).copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Loading indicator en la parte inferior
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                    child: Column(
                      children: [
                        AppLoadingSpinner(
                          size: 32,
                          color: theme.colorScheme.primary,
                          strokeWidth: 3,
                        ),
                        
                        AppSpacing.verticalLG,
                        
                        DelayedAnimation(
                          delay: 800,
                          type: AnimationType.fadeIn,
                          child: Text(
                            'Inicializando aplicación...',
                            style: AppTextStyles.caption(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 