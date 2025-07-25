import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state/app_state.dart';
import 'screens.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final supabaseSession = Supabase.instance.client.auth.currentSession;
    
    // Si hay sesión de Supabase pero no hay currentUser, crear uno temporal
    if (supabaseSession != null && appState.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Esto se ejecutará después del build actual
        appState.login(supabaseSession.user.email ?? '', '');
      });
      // Mostrar loading mientras se procesa
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (appState.currentUser != null || supabaseSession != null) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}