import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import 'screens.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final titles = ['Cotizar', 'Órdenes de Trabajo'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_selectedIndex],
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      drawer: _buildDrawer(context, appState),
      body: Container(
        color: theme.colorScheme.surface,
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
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        backgroundColor: theme.colorScheme.surface,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              appState.currentUser?.nombre ?? 'Usuario',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            accountEmail: Text(
              appState.currentUser?.email ?? 'email@example.com',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.onPrimary,
              child: Text(
                appState.currentUser?.nombre.substring(0, 1).toUpperCase() ?? 'A',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.people_alt_outlined,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              'Gestionar Clientes',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionClientesScreen()));
            },
          ),
          ListTile(
            leading: Icon(
              Icons.person_outline,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              'Gestionar Usuarios',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionUsuariosScreen()));
            },
          ),
          ListTile(
            leading: Icon(
              Icons.work_outline,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              'Gestionar Trabajos',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionTrabajosScreen()));
            },
          ),
          Divider(color: theme.colorScheme.outline),
          ListTile(
            leading: Icon(
              Icons.notifications_outlined,
              color: theme.colorScheme.secondary,
            ),
            title: Text(
              'Config. Notificaciones',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
            },
          ),
          ListTile(
            leading: Icon(
              Icons.palette_outlined,
              color: theme.colorScheme.secondary,
            ),
            title: Text(
              'Configuración de Tema',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()));
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.secondary,
            ),
            title: Text(
              'Configuración General',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onTap: () {
              // TODO: Navegar a una pantalla de configuración general
              Navigator.pop(context);
            },
          ),
          Divider(color: theme.colorScheme.outline),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Cerrar Sesión',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
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
