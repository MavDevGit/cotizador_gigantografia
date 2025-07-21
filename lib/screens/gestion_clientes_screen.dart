
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import 'screens.dart';

class GestionClientesScreen extends GestionScreen<Cliente> {
  const GestionClientesScreen({super.key});
  @override
  _GestionClientesScreenState createState() => _GestionClientesScreenState();
}

class _GestionClientesScreenState extends GestionScreenState<Cliente> {
  Cliente? _clienteSeleccionado;
  
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
    final clientesToShow = showArchived ? appState.clientesArchivados : appState.clientes;
    for (var cliente in clientesToShow) {
      uniqueClientes[cliente.id] = cliente;
    }
    final clientesUnicos = uniqueClientes.values.toList();
    
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
          // DropdownSearch para buscar clientes
          if (!showArchived && clientesUnicos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownSearch<Cliente>(
                items: (filter, infiniteScrollProps) => clientesUnicos,
                selectedItem: _clienteSeleccionado,
                itemAsString: (Cliente cliente) => cliente.nombre,
                onChanged: _onClienteSelected,
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: 'Buscar Cliente',
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Buscar cliente por nombre...',
                    border: OutlineInputBorder(),
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  itemBuilder: (context, Cliente cliente, isSelected, isHighlighted) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cliente.nombre,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : null,
                                  ),
                                ),
                                Text(
                                  'Contacto: ${cliente.contacto}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor.withOpacity(0.8)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  emptyBuilder: (context, searchEntry) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No se encontraron clientes',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          if (searchEntry.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'para "$searchEntry"',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                compareFn: (Cliente cliente1, Cliente cliente2) =>
                    cliente1.id == cliente2.id,
              ),
            ),
          
          // Lista de clientes
          Expanded(
            child: clientesToShow.isEmpty
                ? Center(
                    child: Text(showArchived
                        ? 'No hay clientes archivados.'
                        : 'No hay clientes.'))
                : ListView.builder(
                    itemCount: clientesToShow.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(clientesToShow[index].nombre),
                      subtitle: Text('Contacto: ${clientesToShow[index].contacto}'),
                      trailing: showArchived
                          ? IconButton(
                              icon: Icon(Icons.unarchive),
                              onPressed: () => appState.restoreCliente(clientesToShow[index]),
                              tooltip: "Restaurar",
                            )
                          : IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showClienteDialog(context, cliente: clientesToShow[index])),
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
