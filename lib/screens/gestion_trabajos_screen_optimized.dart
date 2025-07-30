import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import 'screens.dart';

abstract class GestionScreen<T> extends StatefulWidget {
  const GestionScreen({super.key});
}

abstract class GestionScreenState<T>
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
  String _searchText = '';
  
  // Optimización de rendimiento: variables de memoización
  List<Trabajo>? _cachedTrabajosData;
  List<Trabajo>? _cachedTrabajosArchivadosData;
  Future<List<Trabajo>>? _memoizedTrabajosFuture;
  Future<List<Trabajo>>? _memoizedTrabajosArchivadosFuture;
  
  // Controlador para búsqueda con debounce
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  
  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    // Memoizar los Futures para evitar recreación innecesaria
    _memoizedTrabajosFuture = appState.trabajos;
    _memoizedTrabajosArchivadosFuture = appState.trabajosArchivados;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }
  
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
    final trabajosActuales = List<Trabajo>.from(appState.trabajosSync);
    
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
    // Optimización: usar listen: false para evitar rebuilds innecesarios
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Usar futures memoizados para evitar recreación
    final Future<List<Trabajo>> currentFuture = showArchived 
        ? (_memoizedTrabajosArchivadosFuture ?? appState.trabajosArchivados)
        : (_memoizedTrabajosFuture ?? appState.trabajos);
    
    return FutureBuilder<List<Trabajo>>(
      future: currentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostrar datos cache si están disponibles
          final cachedData = showArchived ? _cachedTrabajosArchivadosData : _cachedTrabajosData;
          if (cachedData != null) {
            return _buildScaffoldWithData(context, cachedData);
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error al cargar trabajos: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Actualizar cache y devolver interfaz con datos
        final trabajosData = snapshot.data ?? [];
        if (showArchived) {
          _cachedTrabajosArchivadosData = trabajosData;
        } else {
          _cachedTrabajosData = trabajosData;
        }
        
        return _buildScaffoldWithData(context, trabajosData);
      },
    );
  }
  
  Widget _buildScaffoldWithData(BuildContext context, List<Trabajo> allTrabajos) {
    // Filtrar trabajos únicos manualmente
    final uniqueTrabajos = <String, Trabajo>{};
    for (var trabajo in allTrabajos) {
      uniqueTrabajos[trabajo.id] = trabajo;
    }
    final trabajosUnicos = uniqueTrabajos.values.toList();
    final trabajosToShow = _searchText.isEmpty
        ? trabajosUnicos
        : trabajosUnicos.where((t) => t.titulo.toLowerCase().contains(_searchText.toLowerCase())).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(showArchived ? 'Gestionar Trabajos (Archivados)' : 'Gestionar Trabajos'),
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
          if (!showArchived && trabajosUnicos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar Trabajo',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  hintText: 'Buscar trabajo por título...',
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
          
          // Lista de trabajos
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
                        const SizedBox(height: 16),
                        Text(
                          showArchived ? 'No hay trabajos archivados' : 'No hay trabajos',
                          style: UIUtils.getTitleStyle(context).copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!showArchived) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Presiona + para añadir tu primer trabajo',
                            style: UIUtils.getSubtitleStyle(context),
                          ),
                        ]
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: trabajosToShow.length,
                    onReorder: _reorderTrabajos,
                    itemBuilder: (context, index) {
                      final trabajo = trabajosToShow[index];
                      return Card(
                        key: ValueKey(trabajo.id),
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.work_rounded,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            trabajo.titulo,
                            style: UIUtils.getTitleStyle(context),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trabajo.descripcion.isNotEmpty
                                    ? trabajo.descripcion
                                    : 'Sin descripción',
                                style: UIUtils.getSubtitleStyle(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '\$${trabajo.precio.toStringAsFixed(2)}',
                                style: UIUtils.getSubtitleStyle(context).copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: !showArchived
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      onPressed: () => _showTrabajoDialog(context, trabajo: trabajo),
                                      tooltip: "Editar",
                                    ),
                                    Icon(
                                      Icons.drag_handle_rounded,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                )
                              : null,
                          onTap: () {
                            if (!showArchived) {
                              _showTrabajoDialog(context, trabajo: trabajo);
                            }
                          },
                        ),
                      );
                    },
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
