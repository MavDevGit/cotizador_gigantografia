import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';

class AppState extends ChangeNotifier {
  Usuario? _currentUser;
  Usuario? get currentUser => _currentUser;

  // Theme management
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Hive boxes references
  late Box<Cliente> _clientesBox;
  late Box<Trabajo> _trabajosBox;
  late Box<OrdenTrabajo> _ordenesBox;
  late Box<Usuario> _usuariosBox;
  
  // Lista para mantener el orden personalizado de trabajos
  List<String> _ordenPersonalizadoTrabajosIds = [];

  AppState() {
    // Initialization is now async and happens in main()
  }

  Future<void> init() async {
    _clientesBox = Hive.box<Cliente>('clientes');
    _trabajosBox = Hive.box<Trabajo>('trabajos');
    _ordenesBox = Hive.box<OrdenTrabajo>('ordenes');
    _usuariosBox = Hive.box<Usuario>('usuarios');

    await _createDefaultAdminUser();
    await _loadThemePreference();
    notifyListeners();
  }

  Future<void> _createDefaultAdminUser() async {
    if (_usuariosBox.isEmpty) {
      final adminUser = Usuario(
        id: 'admin_user',
        email: 'admin',
        password: 'admin', // In a real app, this should be hashed
        nombre: 'Administrador',
        rol: 'admin',
        negocioId: 'default_negocio',
        creadoEn: DateTime.now(),
      );
      await _usuariosBox.put(adminUser.id, adminUser);
    }
  }

  Future<bool> login(String email, String password) async {
    final user = _usuariosBox.values.firstWhere(
      (u) => u.email == email && u.eliminadoEn == null,
      orElse: () => Usuario(
          id: '',
          email: '',
          nombre: '',
          rol: '',
          negocioId: '',
          creadoEn: DateTime.now(),
          password: ''), // Return a dummy user
    );

    if (user.id.isNotEmpty && user.password == password) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // --- Getters now read from Hive boxes ---
  List<Cliente> get clientes => _clientesBox.values
      .where((c) => c.eliminadoEn == null)
      .toList()
    ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  List<Cliente> get clientesArchivados => _clientesBox.values
      .where((c) => c.eliminadoEn != null)
      .toList()
    ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  List<Trabajo> get trabajos {
    final trabajosActivos = _trabajosBox.values
        .where((t) => t.eliminadoEn == null)
        .toList();
    
    // Si hay orden personalizado, usarlo
    if (_ordenPersonalizadoTrabajosIds.isNotEmpty) {
      final trabajosOrdenados = <Trabajo>[];
      final trabajosRestantes = List<Trabajo>.from(trabajosActivos);
      
      // Agregar trabajos en el orden personalizado
      for (String id in _ordenPersonalizadoTrabajosIds) {
        final trabajo = trabajosRestantes.firstWhere(
          (t) => t.id == id,
          orElse: () => null as Trabajo,
        );
        if (trabajo != null) {
          trabajosOrdenados.add(trabajo);
          trabajosRestantes.remove(trabajo);
        }
      }
      
      // Agregar trabajos restantes (nuevos) al final en orden alfabético
      trabajosRestantes.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      trabajosOrdenados.addAll(trabajosRestantes);
      
      return trabajosOrdenados;
    }
    
    // Si no hay orden personalizado, usar orden alfabético
    return trabajosActivos
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  }
  List<Trabajo> get trabajosArchivados => _trabajosBox.values
      .where((t) => t.eliminadoEn != null)
      .toList()
    ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  List<OrdenTrabajo> get ordenes => _ordenesBox.values.toList()
    ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  List<Usuario> get usuarios =>
      _usuariosBox.values.where((u) => u.eliminadoEn == null).toList();
  List<Usuario> get usuariosArchivados =>
      _usuariosBox.values.where((u) => u.eliminadoEn != null).toList();

  // --- CRUD methods now write to Hive boxes ---
  Future<void> addOrden(OrdenTrabajo orden) async {
    await _ordenesBox.put(orden.id, orden);
    
    // Programar notificaciones para la nueva orden
    await NotificationService.scheduleOrderNotifications(orden);
    
    notifyListeners();
  }

  Future<void> updateOrden(OrdenTrabajo orden, String cambio) async {
    print('🔄 updateOrden: Iniciando actualización para orden ${orden.id}');
    print('🔄 Cambio: $cambio');

    // Obtener la orden actual para comparar cambios
    final ordenActual = _ordenesBox.get(orden.id);
    
    // Verificar si cambió el estado
    bool estadoCambio = ordenActual?.estado != orden.estado;

    orden.historial.add(OrdenHistorial(
      id: Random().nextDouble().toString(),
      cambio: cambio,
      usuarioId: _currentUser!.id,
      usuarioNombre: _currentUser!.nombre,
      timestamp: DateTimeUtils.nowUtc(),
    ));

    // Ensure the order is saved to Hive
    await _ordenesBox.put(orden.id, orden);

    // Reprogramar notificaciones si cambió fecha/hora de entrega
    final bool fechaCambio = ordenActual?.fechaEntrega != orden.fechaEntrega;
    final bool horaCambio = ordenActual?.horaEntrega.hour != orden.horaEntrega.hour ||
                            ordenActual?.horaEntrega.minute != orden.horaEntrega.minute;

    if (fechaCambio || horaCambio) {
      await NotificationService.scheduleOrderNotifications(orden);
    }
    
    // Notificar cambio de estado
    if (estadoCambio) {
      await NotificationService.notifyOrderStatusChange(orden, orden.estado);
    }

    notifyListeners();
    print('🔄 updateOrden: Actualización completada');
  }

  Future<void> deleteOrden(String ordenId) async {
    // Cancelar notificaciones antes de eliminar
    await NotificationService.cancelOrderNotifications(ordenId);
    
    await _ordenesBox.delete(ordenId);
    notifyListeners();
  }

  // Método auxiliar para formatear fechas
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Método auxiliar para formatear horas
  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<void> addArchivosAOrden(
      OrdenTrabajo orden, List<ArchivoAdjunto> archivos) async {
    orden.archivos.addAll(archivos);
    await updateOrden(
        orden, 'Se agregaron ${archivos.length} archivo(s) adjunto(s)');
  }

  Future<void> removeArchivoDeOrden(
      OrdenTrabajo orden, ArchivoAdjunto archivo) async {
    orden.archivos.removeWhere((a) => a.id == archivo.id);
    await ArchivoService.eliminarArchivo(archivo);
    await updateOrden(orden, 'Se eliminó el archivo adjunto: ${archivo.nombre}');
  }

  Future<void> addTrabajo(Trabajo trabajo) async {
    await _trabajosBox.put(trabajo.id, trabajo);
    notifyListeners();
  }

  Future<void> updateTrabajo(Trabajo trabajo) async {
    await trabajo.save();
    notifyListeners();
  }

  Future<void> deleteTrabajo(Trabajo trabajo) async {
    trabajo.eliminadoEn = DateTimeUtils.nowUtc();
    await trabajo.save();
    notifyListeners();
  }

  Future<void> restoreTrabajo(Trabajo trabajo) async {
    trabajo.eliminadoEn = null;
    await trabajo.save();
    notifyListeners();
  }

  // Métodos para manejar el orden personalizado de trabajos
  void setOrdenPersonalizadoTrabajos(List<Trabajo> trabajosOrdenados) {
    _ordenPersonalizadoTrabajosIds = trabajosOrdenados.map((t) => t.id).toList();
    notifyListeners();
  }
  
  void resetOrdenPersonalizadoTrabajos() {
    _ordenPersonalizadoTrabajosIds.clear();
    notifyListeners();
  }
  
  bool get tieneOrdenPersonalizadoTrabajos => _ordenPersonalizadoTrabajosIds.isNotEmpty;

  Future<void> addCliente(Cliente cliente) async {
    await _clientesBox.put(cliente.id, cliente);
    notifyListeners();
  }

  Future<void> updateCliente(Cliente cliente) async {
    await cliente.save();
    notifyListeners();
  }

  Future<void> deleteCliente(Cliente cliente) async {
    cliente.eliminadoEn = DateTimeUtils.nowUtc();
    await cliente.save();
    notifyListeners();
  }

  Future<void> restoreCliente(Cliente cliente) async {
    cliente.eliminadoEn = null;
    await cliente.save();
    notifyListeners();
  }

  Future<void> addUsuario(Usuario usuario) async {
    await _usuariosBox.put(usuario.id, usuario);
    notifyListeners();
  }

  Future<void> updateUsuario(Usuario usuario) async {
    await usuario.save();
    notifyListeners();
  }

  Future<void> deleteUsuario(Usuario usuario) async {
    if (usuario.id == _currentUser?.id) return;
    usuario.eliminadoEn = DateTimeUtils.nowUtc();
    await usuario.save();
    notifyListeners();
  }

  Future<void> restoreUsuario(Usuario usuario) async {
    usuario.eliminadoEn = null;
    await usuario.save();
    notifyListeners();
  }

  // Theme management methods
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
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
}
