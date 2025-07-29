import 'package:flutter/material.dart';

/// Clase base abstracta para ambos AppState
/// Esto permite que el Provider use un tipo común
abstract class BaseAppState extends ChangeNotifier {
  // Métodos y propiedades comunes que ambos AppState deben implementar
  
  // Usuario actual
  dynamic get currentUser;
  
  // Loading state
  bool get isLoading;
  
  // Métodos comunes
  Future<void> initialize();
  Future<void> logout();
  
  // Métodos que podrían ser específicos pero necesarios
  // Se pueden implementar de forma diferente en cada subclase
}
