
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

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
  void _showTrabajoDialog(BuildContext context, {Trabajo? trabajo}) {
    showDialog(
        context: context,
        builder: (_) => TrabajoFormDialog(trabajo: trabajo));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return buildScaffold(
      context,
      title: 'Gestionar Trabajos',
      items: appState.trabajos,
      archivedItems: appState.trabajosArchivados,
      onFabPressed: () => _showTrabajoDialog(context),
      buildTile: (trabajo) => ListTile(
        title: Text(trabajo.nombre),
        subtitle: Text('Precio m²: \$${trabajo.precioM2.toStringAsFixed(2)}'),
        trailing: showArchived
            ? IconButton(
                icon: Icon(Icons.unarchive),
                onPressed: () => appState.restoreTrabajo(trabajo),
                tooltip: "Restaurar",
              )
            : IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showTrabajoDialog(context, trabajo: trabajo)),
      ),
    );
  }
}
