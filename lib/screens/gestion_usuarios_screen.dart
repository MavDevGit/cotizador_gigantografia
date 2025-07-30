
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import 'usuario_form_dialog.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});
  @override
  _GestionUsuariosScreenState createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  String _searchText = '';
  bool showArchived = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _usuarios = [];
  
  // Optimización de rendimiento: variables de memoización
  List<Map<String, dynamic>>? _cachedUsuariosData;
  List<Map<String, dynamic>>? _cachedUsuariosArchivadosData;
  
  // Controlador para búsqueda con debounce
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  void _showCustomSnackBar(String message, {IconData icon = Icons.info_outline, Color? color}) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color ?? theme.colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: textColor))),
          ],
        ),
        backgroundColor: theme.colorScheme.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          left: 24,
          right: 24,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUsuarios({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final empresaId = appState.currentUser?.negocioId;
    print('🔍 EmpresaId desde AppState: $empresaId');
    
    if (empresaId == null) {
      print('❌ EmpresaId es null, verificando usuario actual...');
      print('   Usuario actual: ${appState.currentUser}');
      setState(() {
        _usuarios = [];
        _isLoading = false;
      });
      return;
    }
    
    // Verificar cache primero (solo si no es refresh forzado)
    if (!forceRefresh) {
      final cachedData = showArchived ? _cachedUsuariosArchivadosData : _cachedUsuariosData;
      if (cachedData != null) {
        print('📦 Usando datos del cache');
        setState(() {
          _usuarios = cachedData;
          _isLoading = false;
        });
        return;
      }
    } else {
      print('🔄 Refresh forzado - ignorando cache');
    }
    
    try {
      print('🔍 Buscando usuarios para empresa: $empresaId');
      print('🔍 Modo archivado: $showArchived');
      
      // Consulta DIRECTA sin RLS - seguridad manejada por filtro de empresa_id
      final response = await Supabase.instance.client
          .from('usuarios')
          .select('id, nombre, email, rol, empresa_id, archivado, auth_user_id, created_at')
          .eq('empresa_id', empresaId)  // Filtro de seguridad por empresa
          .eq('archivado', showArchived)
          .order('nombre', ascending: true);
      
      print('📊 Respuesta Supabase usuarios: $response');
      print('📊 Total usuarios encontrados: ${response.length}');
      
      // Log detallado de cada usuario
      for (var i = 0; i < response.length; i++) {
        final usuario = response[i];
        print('   ${i+1}. 👤 ${usuario['nombre']} - Rol: ${usuario['rol']} - Email: ${usuario['email']}');
      }
      
      final usuarios = List<Map<String, dynamic>>.from(response);
      
      // Actualizar cache
      if (showArchived) {
        _cachedUsuariosArchivadosData = usuarios;
      } else {
        _cachedUsuariosData = usuarios;
      }
      
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error en _fetchUsuarios: $e');
      print('❌ Tipo de error: ${e.runtimeType}');
      setState(() {
        _usuarios = [];
        _isLoading = false;
      });
    }
  }

  void _showUsuarioDialog({Map<String, dynamic>? usuario}) async {
    final appState = Provider.of<AppState>(context, listen: false);
    print('ID de Empresa que se está usando: ${appState.currentUser!.negocioId}');
    final isAdmin = appState.currentUser?.rol == 'admin';
    if (!isAdmin) return;
    final result = await showDialog(
      context: context,
      builder: (_) => UsuarioFormDialog(
        usuario: usuario,
        empresaId: appState.currentUser!.negocioId,
        isEdit: usuario != null,
      ),
    );
    if (result == true) {
      print('🔄 Usuario guardado, limpiando cache y recargando...');
      // Limpiar cache COMPLETAMENTE para forzar recarga
      _cachedUsuariosData = null;
      _cachedUsuariosArchivadosData = null;
      // Recargar datos sin cache
      await _fetchUsuarios(forceRefresh: true);
    }
  }

  Future<void> _toggleArchive(Map<String, dynamic> usuario) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final isAdmin = appState.currentUser?.rol == 'admin';
    if (!isAdmin) return;
    final newValue = !(usuario['archivado'] ?? false);
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'archivado': newValue})
          .eq('id', usuario['id']);
      
      // Limpiar cache para forzar recarga
      _cachedUsuariosData = null;
      _cachedUsuariosArchivadosData = null;
      _fetchUsuarios(forceRefresh: true);
      if (newValue) {
        _showCustomSnackBar('Usuario archivado', icon: Icons.archive, color: Theme.of(context).colorScheme.error);
      } else {
        _showCustomSnackBar('Usuario restaurado', icon: Icons.unarchive, color: Colors.green);
      }
    } catch (e) {
      _showCustomSnackBar('Error al actualizar usuario: $e', icon: Icons.error, color: Theme.of(context).colorScheme.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isAdmin = appState.currentUser?.rol == 'admin';
    final usuariosToShow = _searchText.isEmpty
        ? _usuarios
        : _usuarios.where((u) =>
            (u['nombre'] ?? '').toLowerCase().contains(_searchText.toLowerCase()) ||
            (u['email'] ?? '').toLowerCase().contains(_searchText.toLowerCase())
          ).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (showArchived) {
              setState(() {
                showArchived = false;
              });
              _fetchUsuarios();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(showArchived ? 'Usuarios Archivados' : 'Gestionar Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              print('🔄 Refresh manual solicitado');
              // Limpiar cache completamente
              _cachedUsuariosData = null;
              _cachedUsuariosArchivadosData = null;
              _fetchUsuarios(forceRefresh: true);
            },
          ),
          IconButton(
            icon: Icon(showArchived ? Icons.inventory_2_outlined : Icons.archive_outlined),
            tooltip: showArchived ? 'Ver Activos' : 'Ver Archivados',
            onPressed: () {
              setState(() {
                showArchived = !showArchived;
                // Limpiar cache para forzar recarga
                _cachedUsuariosData = null;
                _cachedUsuariosArchivadosData = null;
              });
              _fetchUsuarios(forceRefresh: true);
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (_usuarios.isNotEmpty && !showArchived)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar Usuario',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  hintText: 'Buscar usuario por nombre o email...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  labelStyle: UIUtils.getSubtitleStyle(context),
                  hintStyle: UIUtils.getSubtitleStyle(context),
                  floatingLabelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
                onChanged: (value) {
                  // Optimización: debounce search para evitar rebuilds excesivos
                  _searchTimer?.cancel();
                  _searchTimer = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() => _searchText = value);
                    }
                  });
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : usuariosToShow.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              showArchived ? Icons.archive_outlined : Icons.person_off_rounded,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              showArchived ? 'No hay usuarios archivados' : 'Solo tú estás registrado como administrador',
                              style: UIUtils.getTitleStyle(context).copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (!showArchived && isAdmin) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Crea usuarios empleados para que puedan gestionar órdenes',
                                style: UIUtils.getSubtitleStyle(context),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Presiona + para agregar empleados',
                                style: UIUtils.getSubtitleStyle(context).copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: usuariosToShow.length,
                        itemBuilder: (context, index) {
                          final usuario = usuariosToShow[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                usuario['nombre'] ?? '',
                                style: UIUtils.getTitleStyle(context),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    usuario['email'] ?? '',
                                    style: UIUtils.getSubtitleStyle(context),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: usuario['rol'] == 'admin' 
                                          ? Theme.of(context).colorScheme.errorContainer
                                          : Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      usuario['rol']?.toUpperCase() ?? 'EMPLEADO',
                                      style: UIUtils.getSubtitleStyle(context).copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: usuario['rol'] == 'admin'
                                            ? Theme.of(context).colorScheme.onErrorContainer
                                            : Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isAdmin
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          onPressed: () => _showUsuarioDialog(usuario: usuario),
                                          tooltip: 'Editar',
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            showArchived ? Icons.unarchive : Icons.archive,
                                            color: showArchived
                                                ? UIUtils.getSuccessColor(context)
                                                : Theme.of(context).colorScheme.error,
                                          ),
                                          onPressed: () => _toggleArchive(usuario),
                                          tooltip: showArchived ? 'Restaurar' : 'Archivar',
                                        ),
                                      ],
                                    )
                                  : null,
                              onTap: () {},
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: (!showArchived && isAdmin)
          ? FloatingActionButton(
              onPressed: () => _showUsuarioDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
