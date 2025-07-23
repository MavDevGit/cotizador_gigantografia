
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import 'screens.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});
  @override
  _GestionUsuariosScreenState createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  String _searchText = '';
  bool showArchived = false;

  void _showUsuarioDialog(BuildContext context, {Usuario? usuario}) {
    showDialog(
      context: context,
      builder: (_) => UsuarioFormDialog(usuario: usuario),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Filtrar usuarios únicos manualmente
    final uniqueUsuarios = <String, Usuario>{};
    final allUsuarios = showArchived ? appState.usuariosArchivados : appState.usuarios;
    for (var usuario in allUsuarios) {
      uniqueUsuarios[usuario.id] = usuario;
    }
    final usuariosUnicos = uniqueUsuarios.values.toList();
    final usuariosToShow = _searchText.isEmpty
        ? usuariosUnicos
        : usuariosUnicos.where((u) => u.nombre.toLowerCase().contains(_searchText.toLowerCase()) || u.email.toLowerCase().contains(_searchText.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(showArchived ? 'Gestionar Usuarios (Archivados)' : 'Gestionar Usuarios'),
        actions: [
          IconButton(
            icon: Icon(showArchived
                ? Icons.inventory_2_outlined
                : Icons.archive_outlined),
            tooltip: showArchived ? 'Ver Activos' : 'Ver Archivados',
            onPressed: () => setState(() => showArchived = !showArchived),
          )
        ],
      ),
      body: Column(
        children: [
          if (!showArchived && usuariosUnicos.isNotEmpty)
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

          // Lista de usuarios
          Expanded(
            child: usuariosToShow.isEmpty
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
                        if (!showArchived) ...[
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
                    itemBuilder: (context, index) => Card(
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
                          usuariosToShow[index].nombre,
                          style: UIUtils.getTitleStyle(context),
                        ),
                        subtitle: Text(
                          usuariosToShow[index].email,
                          style: UIUtils.getSubtitleStyle(context),
                        ),
                        trailing: showArchived
                            ? IconButton(
                                icon: Icon(
                                  Icons.unarchive,
                                  color: UIUtils.getSuccessColor(context),
                                ),
                                onPressed: () => appState.restoreUsuario(usuariosToShow[index]),
                                tooltip: "Restaurar",
                              )
                            : (usuariosToShow[index].id != appState.currentUser?.id
                                ? IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: () => _showUsuarioDialog(context, usuario: usuariosToShow[index]),
                                    tooltip: "Editar",
                                  )
                                : null),
                        onTap: () {
                          if (!showArchived) {
                            // Puedes agregar navegación a detalle de usuario si existe
                          }
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: showArchived
          ? null
          : FloatingActionButton(
              onPressed: () => _showUsuarioDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }
}
