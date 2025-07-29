import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cliente.dart';
import '../models/trabajo.dart';
import '../models/usuario.dart';
import '../models/orden_trabajo.dart';
import '../services/supabase_service.dart';
import '../utils/utils.dart';

class AppState extends ChangeNotifier {
  Usuario? _currentUser;
  Usuario? get currentUser => _currentUser;

  // Theme management
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Supabase service
  final SupabaseService _supabaseService = SupabaseService();

  // Cache de datos para mejorar rendimiento
  List<Cliente>? _clientesCache;
  List<Cliente>? _clientesArchivadosCache;
  List<Trabajo>? _trabajosCache;
  List<Trabajo>? _trabajosArchivadosCache;
  List<OrdenTrabajo>? _ordenesCache;

  // Lista para mantener el orden personalizado de trabajos
  List<String> _ordenPersonalizadoTrabajosIds = [];

  // NUEVO: Verificar si ya se intentó restaurar la sesión
  bool _sessionRestoreAttempted = false;
  bool get sessionRestoreAttempted => _sessionRestoreAttempted;

  // NUEVO: Para compatibilidad con SplashScreen
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    print('🔄 AppState: Iniciando...');
    await _loadThemeMode();
    await _loadOrdenPersonalizadoTrabajos();
    await _tryRestoreSession();
    _isInitialized = true; // Marcar como inicializado
    print('✅ AppState: Inicialización completa');
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString('theme_mode') ?? 'system';
      switch (themeModeString) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    } catch (e) {
      print('⚠️ Error cargando tema: $e');
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', _themeMode.name);
    } catch (e) {
      print('⚠️ Error guardando tema: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveThemeMode();
      notifyListeners();
    }
  }

  Future<void> _loadOrdenPersonalizadoTrabajos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ordenPersonalizadoTrabajosIds = 
          prefs.getStringList('orden_personalizado_trabajos') ?? [];
    } catch (e) {
      print('⚠️ Error cargando orden personalizado: $e');
      _ordenPersonalizadoTrabajosIds = [];
    }
  }

  Future<void> _saveOrdenPersonalizadoTrabajos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('orden_personalizado_trabajos', _ordenPersonalizadoTrabajosIds);
    } catch (e) {
      print('⚠️ Error guardando orden personalizado: $e');
    }
  }

  Future<void> _tryRestoreSession() async {
    _sessionRestoreAttempted = true;
    notifyListeners();

    try {
      final user = await _supabaseService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        await _loadAllData();
        notifyListeners();
        print('✅ Sesión restaurada exitosamente');
      } else {
        print('ℹ️ No hay sesión activa para restaurar');
      }
    } catch (e) {
      print('⚠️ Error restaurando sesión: $e');
    }
  }

  Future<void> _loadAllData() async {
    // Invalidar cache para forzar recarga
    _clientesCache = null;
    _clientesArchivadosCache = null;
    _trabajosCache = null;
    _trabajosArchivadosCache = null;
    _ordenesCache = null;
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final user = await _supabaseService.getCurrentUser();
        if (user != null) {
          _currentUser = user;
          await _loadAllData();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('⚠️ Error en login: $e');
      _currentUser = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    _currentUser = null;
    // Limpiar cache
    _clientesCache = null;
    _clientesArchivadosCache = null;
    _trabajosCache = null;
    _trabajosArchivadosCache = null;
    _ordenesCache = null;
    notifyListeners();
  }

  // === GETTERS CON CACHE ===

  Future<List<Cliente>> get clientes async {
    if (_clientesCache == null) {
      _clientesCache = await _supabaseService.getClientes();
    }
    return _clientesCache!;
  }

  // Getter síncrono para compatibilidad
  List<Cliente> get clientesSync => _clientesCache ?? [];

  Future<List<Cliente>> get clientesArchivados async {
    if (_clientesArchivadosCache == null) {
      _clientesArchivadosCache = await _supabaseService.getClientesArchivados();
    }
    return _clientesArchivadosCache!;
  }

  // Getter síncrono para compatibilidad  
  List<Cliente> get clientesArchivadosSync => _clientesArchivadosCache ?? [];

  Future<List<Trabajo>> get trabajos async {
    if (_trabajosCache == null) {
      final trabajosActivos = await _supabaseService.getTrabajos();
      
      // Aplicar orden personalizado si existe
      if (_ordenPersonalizadoTrabajosIds.isNotEmpty) {
        final trabajosOrdenados = <Trabajo>[];
        final trabajosRestantes = List<Trabajo>.from(trabajosActivos);
        
        // Agregar trabajos en el orden personalizado
        for (String id in _ordenPersonalizadoTrabajosIds) {
          final trabajo = trabajosRestantes.where((t) => t.id == id).firstOrNull;
          if (trabajo != null) {
            trabajosOrdenados.add(trabajo);
            trabajosRestantes.remove(trabajo);
          }
        }
        
        // Agregar trabajos restantes (nuevos) al final en orden alfabético
        trabajosRestantes.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        trabajosOrdenados.addAll(trabajosRestantes);
        
        _trabajosCache = trabajosOrdenados;
      } else {
        // Si no hay orden personalizado, usar orden alfabético
        trabajosActivos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        _trabajosCache = trabajosActivos;
      }
    }
    return _trabajosCache!;
  }

  // Getter síncrono para compatibilidad
  List<Trabajo> get trabajosSync => _trabajosCache ?? [];

  Future<List<Trabajo>> get trabajosArchivados async {
    if (_trabajosArchivadosCache == null) {
      _trabajosArchivadosCache = await _supabaseService.getTrabajosArchivados();
      _trabajosArchivadosCache!.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    }
    return _trabajosArchivadosCache!;
  }

  // Getter síncrono para compatibilidad
  List<Trabajo> get trabajosArchivadosSync => _trabajosArchivadosCache ?? [];

  Future<List<OrdenTrabajo>> get ordenes async {
    if (_ordenesCache == null) {
      _ordenesCache = await _supabaseService.getOrdenes();
    }
    return _ordenesCache!;
  }

  // Getter síncrono para compatibilidad
  List<OrdenTrabajo> get ordenesSync => _ordenesCache ?? [];

  // === MÉTODOS CRUD PARA CLIENTES ===

  Future<void> addCliente(Cliente cliente) async {
    final success = await _supabaseService.addCliente(cliente);
    if (success) {
      _clientesCache = null; // Invalidar cache
      notifyListeners();
    }
  }

  Future<void> updateCliente(Cliente cliente) async {
    final success = await _supabaseService.updateCliente(cliente);
    if (success) {
      _clientesCache = null; // Invalidar cache
      notifyListeners();
    }
  }

  Future<void> deleteCliente(Cliente cliente) async {
    final success = await _supabaseService.deleteCliente(cliente.id);
    if (success) {
      _clientesCache = null; // Invalidar cache
      _clientesArchivadosCache = null; // Invalidar cache de archivados
      notifyListeners();
    }
  }

  Future<void> restoreCliente(Cliente cliente) async {
    final success = await _supabaseService.restoreCliente(cliente.id);
    if (success) {
      _clientesCache = null; // Invalidar cache
      _clientesArchivadosCache = null; // Invalidar cache de archivados
      notifyListeners();
    }
  }

  // === MÉTODOS CRUD PARA TRABAJOS ===

  Future<void> addTrabajo(Trabajo trabajo) async {
    final success = await _supabaseService.addTrabajo(trabajo);
    if (success) {
      _trabajosCache = null; // Invalidar cache
      notifyListeners();
    }
  }

  Future<void> updateTrabajo(Trabajo trabajo) async {
    final success = await _supabaseService.updateTrabajo(trabajo);
    if (success) {
      _trabajosCache = null; // Invalidar cache
      notifyListeners();
    }
  }

  Future<void> deleteTrabajo(Trabajo trabajo) async {
    final success = await _supabaseService.deleteTrabajo(trabajo.id);
    if (success) {
      _trabajosCache = null; // Invalidar cache
      _trabajosArchivadosCache = null; // Invalidar cache de archivados
      notifyListeners();
    }
  }

  Future<void> restoreTrabajo(Trabajo trabajo) async {
    final success = await _supabaseService.restoreTrabajo(trabajo.id);
    if (success) {
      _trabajosCache = null; // Invalidar cache
      _trabajosArchivadosCache = null; // Invalidar cache de archivados
      notifyListeners();
    }
  }

  // === MÉTODOS PARA ORDEN PERSONALIZADO DE TRABAJOS ===

  void setOrdenPersonalizadoTrabajos(List<Trabajo> trabajosOrdenados) {
    _ordenPersonalizadoTrabajosIds = trabajosOrdenados.map((t) => t.id).toList();
    _trabajosCache = null; // Invalidar cache para aplicar nuevo orden
    _saveOrdenPersonalizadoTrabajos();
    notifyListeners();
  }

  void resetOrdenPersonalizadoTrabajos() {
    _ordenPersonalizadoTrabajosIds.clear();
    _trabajosCache = null; // Invalidar cache
    _saveOrdenPersonalizadoTrabajos();
    notifyListeners();
  }

  bool get tieneOrdenPersonalizadoTrabajos => _ordenPersonalizadoTrabajosIds.isNotEmpty;

  // === MÉTODOS CRUD PARA ÓRDENES ===

  Future<void> addOrden(OrdenTrabajo orden) async {
    print('🔄 AppState: Iniciando addOrden para orden ${orden.id}');
    print('🔄 Orden cliente: ${orden.cliente.nombre}');
    print('🔄 Orden items: ${orden.items.length}');
    
    try {
      final ordenId = await _supabaseService.addOrden(orden);
      print('🔄 Respuesta de SupabaseService: $ordenId');
      
      if (ordenId != null) {
        print('✅ Orden guardada exitosamente con ID: $ordenId');
        _ordenesCache = null; // Invalidar cache
        notifyListeners();
      } else {
        print('❌ Error: SupabaseService retornó null');
        throw Exception('Error al guardar la orden en la base de datos');
      }
    } catch (e) {
      print('❌ Error en AppState.addOrden: $e');
      rethrow; // Re-lanzar la excepción para que la maneje la UI
    }
  }

  Future<void> updateOrden(OrdenTrabajo orden, String cambio) async {
    print('🔄 updateOrden: Iniciando actualización para orden ${orden.id}');
    print('🔄 Cambio: $cambio');

    final success = await _supabaseService.updateOrden(orden);
    if (success) {
      _ordenesCache = null; // Invalidar cache
      notifyListeners();
      print('🔄 updateOrden: Actualización completada');
    }
  }

  Future<void> deleteOrden(String ordenId) async {
    final success = await _supabaseService.deleteOrden(ordenId);
    if (success) {
      _ordenesCache = null; // Invalidar cache
      notifyListeners();
    }
  }

  Future<void> updateOrdenEstado(String ordenId, String nuevoEstado) async {
    final success = await _supabaseService.updateOrdenEstado(ordenId, nuevoEstado);
    if (success) {
      _ordenesCache = null; // Invalidar cache
      notifyListeners();
    }
  }

  // === MÉTODOS DE COMPATIBILIDAD (para mantener el código existente funcionando) ===

  // Para compatibilidad con el código que espera listas síncronas
  List<Usuario> get usuarios => []; // Implementar si se necesita
  List<Usuario> get usuariosArchivados => []; // Implementar si se necesita

  Future<void> addUsuario(Usuario usuario) async {
    // Implementar si se necesita gestión de usuarios desde la app
  }

  Future<void> updateUsuario(Usuario usuario) async {
    // Implementar si se necesita gestión de usuarios desde la app
  }

  Future<void> deleteUsuario(Usuario usuario) async {
    // Implementar si se necesita gestión de usuarios desde la app
  }

  Future<void> restoreUsuario(Usuario usuario) async {
    // Implementar si se necesita gestión de usuarios desde la app
  }

  // === MÉTODOS ADICIONALES PARA COMPATIBILIDAD ===

  Future<bool> checkExistingSession() async {
    try {
      final user = await _supabaseService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        await _loadAllData();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('⚠️ Error verificando sesión existente: $e');
      return false;
    }
  }

  bool get sessionCheckCompleted => _sessionRestoreAttempted;

  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.system:
        setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.system);
        break;
    }
  }

  String getThemeModeString() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  // === MÉTODOS PARA ARCHIVOS ADJUNTOS ===

  Future<void> addArchivosAOrden(String ordenId, List<dynamic> archivos) async {
    // Implementar según sea necesario
    // Por ahora, simplemente notificar cambios
    notifyListeners();
  }

  Future<void> removeArchivoDeOrden(String ordenId, dynamic archivo) async {
    // Implementar según sea necesario
    // Por ahora, simplemente notificar cambios
    notifyListeners();
  }
}
