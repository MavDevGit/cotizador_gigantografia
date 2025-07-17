
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import 'screens.dart';

class GestionClientesScreen extends GestionScreen<Cliente> {
  const GestionClientesScreen({super.key});
  @override
  _GestionClientesScreenState createState() => _GestionClientesScreenState();
}

class _GestionClientesScreenState extends GestionScreenState<Cliente> {
  void _showClienteDialog(BuildContext context, {Cliente? cliente}) {
    showDialog(
        context: context,
        builder: (_) => ClienteFormDialog(cliente: cliente));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return buildScaffold(
      context,
      title: 'Gestionar Clientes',
      items: appState.clientes,
      archivedItems: appState.clientesArchivados,
      onFabPressed: () => _showClienteDialog(context),
      buildTile: (cliente) => ListTile(
        title: Text(cliente.nombre),
        subtitle: Text('Contacto: ${cliente.contacto}'),
        trailing: showArchived
            ? IconButton(
                icon: Icon(Icons.unarchive),
                onPressed: () => appState.restoreCliente(cliente),
                tooltip: "Restaurar",
              )
            : IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showClienteDialog(context, cliente: cliente)),
        onTap: () {
          if (!showArchived) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ClienteDetalleScreen(cliente: cliente)));
          }
        },
      ),
    );
  }
}
