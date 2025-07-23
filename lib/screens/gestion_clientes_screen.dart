
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import 'screens.dart';

class GestionClientesScreen extends GestionScreen<Cliente> {
  const GestionClientesScreen({super.key});
  @override
  _GestionClientesScreenState createState() => _GestionClientesScreenState();
}

class _GestionClientesScreenState extends GestionScreenState<Cliente> {
  String _searchText = '';
  
  void _showClienteDialog(BuildContext context, {Cliente? cliente}) {
    showDialog(
        context: context,
        builder: (_) => ClienteFormDialog(cliente: cliente));
  }

  void _onClienteSelected(Cliente? cliente) {
    if (cliente != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClienteDetalleScreen(cliente: cliente)
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Filtrar clientes únicos manualmente
    final uniqueClientes = <String, Cliente>{};
    final allClientes = showArchived ? appState.clientesArchivados : appState.clientes;
    for (var cliente in allClientes) {
      uniqueClientes[cliente.id] = cliente;
    }
    final clientesUnicos = uniqueClientes.values.toList();
    final clientesToShow = _searchText.isEmpty
        ? clientesUnicos
        : clientesUnicos.where((c) => c.nombre.toLowerCase().contains(_searchText.toLowerCase())).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(showArchived ? 'Gestionar Clientes (Archivados)' : 'Gestionar Clientes'),
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
          if (!showArchived && clientesUnicos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Buscar Cliente',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  hintText: 'Buscar cliente por nombre...',
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
          
          // Lista de clientes
          Expanded(
            child: clientesToShow.isEmpty
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
                          showArchived ? 'No hay clientes archivados' : 'No hay clientes',
                          style: UIUtils.getTitleStyle(context).copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!showArchived) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Presiona el botón + para agregar un cliente',
                            style: UIUtils.getSubtitleStyle(context),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: clientesToShow.length,
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
                            Icons.person_rounded,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          clientesToShow[index].nombre,
                          style: UIUtils.getTitleStyle(context),
                        ),
                        subtitle: Text(
                          'Contacto: ${clientesToShow[index].contacto}',
                          style: UIUtils.getSubtitleStyle(context),
                        ),
                        trailing: showArchived
                            ? IconButton(
                                icon: Icon(
                                  Icons.unarchive,
                                  color: UIUtils.getSuccessColor(context),
                                ),
                                onPressed: () => appState.restoreCliente(clientesToShow[index]),
                                tooltip: "Restaurar",
                              )
                            : IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () => _showClienteDialog(context, cliente: clientesToShow[index]),
                                tooltip: "Editar",
                              ),
                        onTap: () {
                          if (!showArchived) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ClienteDetalleScreen(cliente: clientesToShow[index])));
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
              onPressed: () => _showClienteDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }
}
