import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import 'screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    CotizarScreen(),
    OrdenesTrabajoScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final titles = ['Cotizar', 'Órdenes de Trabajo'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        // El Drawer se activará automáticamente con el icono de menú
      ),
      drawer: _buildDrawer(context, appState),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Cotizar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Órdenes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, AppState appState) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(appState.currentUser?.nombre ?? 'Usuario'),
            accountEmail: Text(appState.currentUser?.email ?? 'email@example.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Text(
                appState.currentUser?.nombre.substring(0, 1).toUpperCase() ?? 'A',
                style: TextStyle(fontSize: 40.0, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Gestionar Clientes'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionClientesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: const Text('Gestionar Trabajos'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionTrabajosScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Config. Notificaciones'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración General'),
            onTap: () {
              // TODO: Navegar a una pantalla de configuración general
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              appState.logout();
              Navigator.pop(context); // Cierra el drawer
            },
          ),
        ],
      ),
    );
  }
}
