
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import 'screens.dart';

class ClienteDetalleScreen extends StatelessWidget {
  final Cliente cliente;
  const ClienteDetalleScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final ordenesCliente =
        appState.ordenes.where((o) => o.cliente.id == cliente.id).toList();

    return Scaffold(
      appBar: AppBar(title: Text(cliente.nombre)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Órdenes de Trabajo Asociadas",
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: ordenesCliente.isEmpty
                ? Center(child: Text("Este cliente no tiene órdenes de trabajo."))
                : ListView.builder(
                    itemCount: ordenesCliente.length,
                    itemBuilder: (context, index) {
                      final orden = ordenesCliente[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text("Orden #${orden.id.substring(0, 4)}"),
                          subtitle: Text(
                              "Total: \$${orden.total.toStringAsFixed(2)}"),
                          trailing: Chip(
                            label: Text(orden.estado,
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: _getStatusColor(orden.estado),
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        OrdenDetalleScreen(orden: orden)));
                          },
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'terminado':
        return Colors.green;
      case 'entregado':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
