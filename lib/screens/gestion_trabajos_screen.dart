import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';
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
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: 'Buscar Trabajo',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    hintText: 'Buscar trabajo por nombre...',
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
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          UIUtils.buildThemedIcon(
                            icon: Icons.work_rounded,
                            context: context,
                            isSelected: isSelected,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trabajo.nombre,
                                  style: UIUtils.getTitleStyle(
                                    context,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Bs ${trabajo.precioM2.toStringAsFixed(2)}/m²',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  emptyBuilder: (context, searchEntry) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_off_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                          FormSpacing.verticalSmall(),
                          Text(
                            'No se encontraron trabajos',
                            style: UIUtils.getTitleStyle(context).copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (searchEntry.isNotEmpty) ...[
                            FormSpacing.verticalSmall(),
                            Text(
                              'para "$searchEntry"',
                              style: UIUtils.getSubtitleStyle(context),
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
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : UIUtils.getWarningColor(context).withOpacity(0.1),
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
                        ? Theme.of(context).colorScheme.primary
                        : UIUtils.getWarningColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appState.tieneOrdenPersonalizadoTrabajos
                          ? 'Orden personalizado activo - Arrastra para modificar'
                          : 'Mantén presionado y arrastra para reordenar',
                      style: UIUtils.getSubtitleStyle(context).copyWith(
                        fontSize: 12,
                        color: appState.tieneOrdenPersonalizadoTrabajos 
                            ? Theme.of(context).colorScheme.primary
                            : UIUtils.getWarningColor(context),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          showArchived ? Icons.archive_outlined : Icons.work_off_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                        FormSpacing.verticalLarge(),
                        Text(
                          showArchived ? 'No hay trabajos archivados' : 'No hay trabajos',
                          style: UIUtils.getTitleStyle(context).copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!showArchived) ...[
                          FormSpacing.verticalSmall(),
                          Text(
                            'Presiona el botón + para agregar un trabajo',
                            style: UIUtils.getSubtitleStyle(context),
                          ),
                        ],
                      ],
                    ),
                  )
                : showArchived 
                    ? ListView.builder(
                        itemCount: trabajosToShow.length,
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
                                Icons.work_rounded,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              trabajosToShow[index].nombre,
                              style: UIUtils.getTitleStyle(context),
                            ),
                            subtitle: Text(
                              'Precio m²: Bs ${trabajosToShow[index].precioM2.toStringAsFixed(2)}',
                              style: UIUtils.getSubtitleStyle(context),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.unarchive,
                                color: UIUtils.getSuccessColor(context),
                              ),
                              onPressed: () => appState.restoreTrabajo(trabajosToShow[index]),
                              tooltip: "Restaurar",
                            ),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Icon(
                              Icons.drag_handle_rounded,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              trabajosToShow[index].nombre,
                              style: UIUtils.getTitleStyle(context),
                            ),
                            subtitle: Text(
                              'Precio m²: Bs ${trabajosToShow[index].precioM2.toStringAsFixed(2)}',
                              style: UIUtils.getSubtitleStyle(context),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () => _showTrabajoDialog(context, trabajo: trabajosToShow[index]),
                              tooltip: "Editar",
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
