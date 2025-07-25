import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import 'screens.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // MODIFICADO: Mostrar loading mientras se verifica la sesión
    if (!appState.sessionCheckCompleted) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando sesión...'),
            ],
          ),
        ),
      );
    }
    
    // Una vez completada la verificación, decidir qué mostrar
    if (appState.currentUser != null) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}