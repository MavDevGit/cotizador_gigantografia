import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state/app_state.dart';
import 'screens.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isProcessingSession = false;

  @override
  void initState() {
    super.initState();
    print('🚀 AuthWrapper initState');
    _processSession();
  }

  Future<void> _processSession() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final supabaseSession = Supabase.instance.client.auth.currentSession;
    
    print('🔄 Procesando sesión:');
    print('   - Supabase session: ${supabaseSession != null}');
    print('   - Current user: ${appState.currentUser != null}');
    print('   - Session check completed: ${appState.sessionCheckCompleted}');
    print('   - AppState initialized: ${appState.isInitialized}');
    
    // Solo esperar si no se ha completado la verificación de sesión
    if (!appState.sessionCheckCompleted && !appState.isInitialized) {
      print('⏳ Esperando a que se complete la inicialización...');
      setState(() {
        _isProcessingSession = true;
      });
      
      // Esperar a que se complete la inicialización
      while (!appState.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      print('✅ Inicialización completada');
      setState(() {
        _isProcessingSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    print('🏗️ AuthWrapper build:');
    print('   - Processing session: $_isProcessingSession');
    print('   - Session check completed: ${appState.sessionCheckCompleted}');
    print('   - Current user: ${appState.currentUser != null}');
    print('   - AppState initialized: ${appState.isInitialized}');
    
    // Si estamos procesando la sesión o no se ha completado la inicialización, mostrar loading
    if (_isProcessingSession || !appState.isInitialized) {
      print('⏳ Mostrando loading...');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Si hay usuario autenticado, ir a MainScreen
    if (appState.currentUser != null) {
      print('✅ Redirigiendo a MainScreen');
      return const MainScreen();
    }
    
    // Si no hay usuario autenticado, ir a LoginScreen
    print('🔐 Redirigiendo a LoginScreen');
    return const LoginScreen();
  }
}