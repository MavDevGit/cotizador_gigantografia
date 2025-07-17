
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import 'screens.dart';

class GestionUsuariosScreen extends GestionScreen<Usuario> {
  const GestionUsuariosScreen({super.key});
  @override
  _GestionUsuariosScreenState createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends GestionScreenState<Usuario> {
  void _showUsuarioDialog(BuildContext context, {Usuario? usuario}) {
    showDialog(
        context: context,
        builder: (_) => UsuarioFormDialog(usuario: usuario));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return buildScaffold(
      context,
      title: 'Gestionar Usuarios',
      items: appState.usuarios,
      archivedItems: appState.usuariosArchivados,
      buildTile: (usuario) => ListTile(
        leading:
            CircleAvatar(child: Text(usuario.rol.substring(0, 1).toUpperCase())),
        title: Text(usuario.nombre),
        subtitle: Text(usuario.email),
        trailing: showArchived
            ? IconButton(
                icon: Icon(Icons.unarchive),
                onPressed: () => appState.restoreUsuario(usuario),
                tooltip: "Restaurar",
              )
            : (usuario.id != appState.currentUser?.id
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _showUsuarioDialog(context, usuario: usuario))
                : null),
      ),
      onFabPressed: () => _showUsuarioDialog(context),
    );
  }
}
