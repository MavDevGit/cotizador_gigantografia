
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

  Future<void> _fetchUsuarios() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final empresaId = appState.currentUser?.negocioId;
    print('empresaId: $empresaId');
    if (empresaId == null) {
      setState(() {
        _usuarios = [];
        _isLoading = false;
      });
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('empresa_id', empresaId)
          .eq('archivado', showArchived)
          .order('nombre', ascending: true);
      print('Respuesta Supabase: $response');
      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error en _fetchUsuarios: $e');
      setState(() {
        _usuarios = [];
        _isLoading = false;
      });
    }
  }

  void _showUsuarioDialog({Map<String, dynamic>? usuario}) async {
    final appState = Provider.of<AppState>(context, listen: false);
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
      _fetchUsuarios();
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
      _fetchUsuarios();
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
    final appState = Provider.of<AppState>(context);
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
            icon: Icon(showArchived ? Icons.inventory_2_outlined : Icons.archive_outlined),
            tooltip: showArchived ? 'Ver Activos' : 'Ver Archivados',
            onPressed: () {
              setState(() {
                showArchived = !showArchived;
              });
              _fetchUsuarios();
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
                onChanged: (value) => setState(() => _searchText = value),
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
                              showArchived ? 'No hay usuarios archivados' : 'No hay usuarios',
                              style: UIUtils.getTitleStyle(context).copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (!showArchived && isAdmin) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Presiona el botón + para agregar un usuario',
                                style: UIUtils.getSubtitleStyle(context),
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
                              subtitle: Text(
                                usuario['email'] ?? '',
                                style: UIUtils.getSubtitleStyle(context),
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
