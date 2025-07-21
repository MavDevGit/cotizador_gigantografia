import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import 'screens.dart';

abstract class GestionScreen<T extends HiveObject> extends StatefulWidget {
  const GestionScreen({super.key});
}

abstract class GestionScreenState<T extends HiveObject>
    extends State<GestionScreen<T>> {
  bool showArchived = false;

  Widget buildScaffold(
    BuildContext context, {
    required String title,
    required List<T> items,
    required List<T> archivedItems,
    required Widget Function(T item) buildTile,
    required void Function() onFabPressed,
  }) {
    final displayItems = showArchived ? archivedItems : items;
    return Scaffold(
      appBar: AppBar(
        title: Text(showArchived ? '$title (Archivados)' : title),
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
      body: displayItems.isEmpty
          ? Center(
              child: Text(showArchived
                  ? 'No hay elementos archivados.'
                  : 'No hay elementos.'))
          : ListView.builder(
              itemCount: displayItems.length,
              itemBuilder: (context, index) => buildTile(displayItems[index]),
            ),
      floatingActionButton: showArchived
          ? null
          : FloatingActionButton(
              onPressed: onFabPressed,
              child: const Icon(Icons.add),
            ),
    );
  }
}

class GestionTrabajosScreen extends GestionScreen<Trabajo> {
  const GestionTrabajosScreen({super.key});
  @override
  _GestionTrabajosScreenState createState() => _GestionTrabajosScreenState();
}

class _GestionTrabajosScreenState extends GestionScreenState<Trabajo> {
  Trabajo? _trabajoSeleccionado;
  
  void _showTrabajoDialog(BuildContext context, {Trabajo? trabajo}) {
    showDialog(
        context: context,
        builder: (_) => TrabajoFormDialog(trabajo: trabajo));
  }

  void _onTrabajoSelected(Trabajo? trabajo) {
    if (trabajo != null) {
      _showTrabajoDialog(context, trabajo: trabajo);
    }
  }
  
  void _reorderTrabajos(int oldIndex, int newIndex) {
    final appState = Provider.of<AppState>(context, listen: false);
    final trabajosActuales = List<Trabajo>.from(appState.trabajos);
    
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final trabajo = trabajosActuales.removeAt(oldIndex);
    trabajosActuales.insert(newIndex, trabajo);
    
    // Guardar el nuevo orden en el AppState
    appState.setOrdenPersonalizadoTrabajos(trabajosActuales);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Filtrar trabajos únicos manualmente para el dropdown
    final uniqueTrabajos = <String, Trabajo>{};
    final trabajosToShow = showArchived ? appState.trabajosArchivados : appState.trabajos;
    final trabajosParaDropdown = showArchived ? appState.trabajosArchivados : appState.trabajos;
    
    for (var trabajo in trabajosParaDropdown) {
      uniqueTrabajos[trabajo.id] = trabajo;
    }
    final trabajosUnicos = uniqueTrabajos.values.toList();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(showArchived ? 'Gestionar Trabajos (Archivados)' : 'Gestionar Trabajos'),
        actions: [
          if (!showArchived && appState.tieneOrdenPersonalizadoTrabajos)
            IconButton(
              icon: Icon(Icons.shuffle_rounded),
              tooltip: 'Restablecer orden alfabético',
              onPressed: () {
                appState.resetOrdenPersonalizadoTrabajos();
              },
            ),
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
          // DropdownSearch para buscar trabajos
          if (!showArchived && trabajosUnicos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownSearch<Trabajo>(
                items: (filter, infiniteScrollProps) => trabajosUnicos,
                selectedItem: _trabajoSeleccionado,
                itemAsString: (Trabajo trabajo) => trabajo.nombre,
                onChanged: _onTrabajoSelected,
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: 'Buscar Trabajo',
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Buscar trabajo por nombre...',
                    border: OutlineInputBorder(),
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Buscar trabajo...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  itemBuilder: (context, Trabajo trabajo, isSelected, isHighlighted) {
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
                            Icons.work_rounded,
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
                                  trabajo.nombre,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Bs ${trabajo.precioM2.toStringAsFixed(2)}/m²',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
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
                            Icons.work_off_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No se encontraron trabajos',
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
                compareFn: (Trabajo trabajo1, Trabajo trabajo2) =>
                    trabajo1.id == trabajo2.id,
              ),
            ),
          
          // Instrucciones de reordenamiento
          if (!showArchived && trabajosToShow.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: appState.tieneOrdenPersonalizadoTrabajos 
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    appState.tieneOrdenPersonalizadoTrabajos 
                        ? Icons.sort_rounded 
                        : Icons.drag_handle_rounded,
                    size: 20,
                    color: appState.tieneOrdenPersonalizadoTrabajos 
                        ? Theme.of(context).primaryColor
                        : Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appState.tieneOrdenPersonalizadoTrabajos
                          ? 'Orden personalizado activo - Arrastra para modificar'
                          : 'Mantén presionado y arrastra para reordenar',
                      style: TextStyle(
                        fontSize: 12,
                        color: appState.tieneOrdenPersonalizadoTrabajos 
                            ? Theme.of(context).primaryColor
                            : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Lista de trabajos reordenable
          Expanded(
            child: trabajosToShow.isEmpty
                ? Center(
                    child: Text(showArchived
                        ? 'No hay trabajos archivados.'
                        : 'No hay trabajos.'))
                : showArchived 
                    ? ListView.builder(
                        itemCount: trabajosToShow.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(trabajosToShow[index].nombre),
                          subtitle: Text('Precio m²: Bs ${trabajosToShow[index].precioM2.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: Icon(Icons.unarchive),
                            onPressed: () => appState.restoreTrabajo(trabajosToShow[index]),
                            tooltip: "Restaurar",
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: trabajosToShow.length,
                        onReorder: _reorderTrabajos,
                        itemBuilder: (context, index) => Card(
                          key: ValueKey(trabajosToShow[index].id),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              Icons.drag_handle_rounded,
                              color: Colors.grey[600],
                            ),
                            title: Text(trabajosToShow[index].nombre),
                            subtitle: Text('Precio m²: Bs ${trabajosToShow[index].precioM2.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showTrabajoDialog(context, trabajo: trabajosToShow[index]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: showArchived
          ? null
          : FloatingActionButton(
              onPressed: () => _showTrabajoDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }
}
