import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
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
    if (_selectedIndex != index) {
      AppFeedback.hapticFeedback(HapticType.selection);
      setState(() {
        _selectedIndex = index;
      });
    }
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Semantics(
              label: theme.brightness == Brightness.dark 
                  ? 'Cambiar a modo claro' 
                  : 'Cambiar a modo oscuro',
              button: true,
              child: AppStatusChip(
                label: theme.brightness == Brightness.dark ? 'Oscuro' : 'Claro',
                status: StatusType.neutral,
                icon: theme.brightness == Brightness.dark 
                    ? Icons.dark_mode_rounded 
                    : Icons.light_mode_rounded,
                onTap: () {
                  AppFeedback.hapticFeedback(HapticType.selection);
                  appState.toggleTheme();
                },
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, appState),
      body: Container(
        color: theme.colorScheme.surface,
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Semantics(
        label: 'Navegación principal',
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate_rounded),
              label: 'Cotizar',
              tooltip: 'Crear nueva cotización',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Órdenes',
              tooltip: 'Ver órdenes de trabajo',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          backgroundColor: theme.colorScheme.surface,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.caption(context),
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final isAdmin = appState.currentUser?.rol == 'admin';
    
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          // Header mejorado
          UserAccountsDrawerHeader(
            accountName: Text(
              appState.currentUser?.nombre ?? 'Usuario',
              style: AppTextStyles.subtitle1(context).copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            accountEmail: Text(
              appState.currentUser?.email ?? 'email@example.com',
              style: AppTextStyles.body2(context).copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            currentAccountPicture: Hero(
              tag: 'user_avatar',
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.onPrimary,
                child: Text(
                  appState.currentUser?.nombre.substring(0, 1).toUpperCase() ?? 'A',
                  style: AppTextStyles.heading2(context).copyWith(
                    color: theme.colorScheme.primary,
                  ),
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
          
          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.people_alt_outlined,
                  title: 'Gestionar Clientes',
                  onTap: () => _navigateFromDrawer(context, const GestionClientesScreen()),
                  semanticLabel: 'Ir a gestión de clientes',
                ),
                
                if (isAdmin)
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Gestionar Usuarios',
                    onTap: () => _navigateFromDrawer(context, const GestionUsuariosScreen()),
                    semanticLabel: 'Ir a gestión de usuarios',
                  ),
                
                _buildDrawerItem(
                  context,
                  icon: Icons.work_outline,
                  title: 'Gestionar Trabajos',
                  onTap: () => _navigateFromDrawer(context, const GestionTrabajosScreen()),
                  semanticLabel: 'Ir a gestión de trabajos',
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  onTap: () => _navigateFromDrawer(context, const NotificationSettingsScreen()),
                  semanticLabel: 'Configurar notificaciones',
                ),
                
                _buildDrawerItem(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'Tema',
                  onTap: () => _navigateFromDrawer(context, const ThemeSettingsScreen()),
                  semanticLabel: 'Configurar tema de la aplicación',
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
              ],
            ),
          ),
          
          // Logout button at bottom
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildDrawerItem(
              context,
              icon: Icons.logout_rounded,
              title: 'Cerrar Sesión',
              onTap: () => _handleLogout(context, appState),
              semanticLabel: 'Cerrar sesión de la aplicación',
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required String semanticLabel,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive 
        ? theme.colorScheme.error 
        : theme.colorScheme.onSurface;
    
    return Semantics(
      label: semanticLabel,
      button: true,
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
          size: AppConstants.iconSize,
        ),
        title: Text(
          title,
          style: AppTextStyles.body1(context).copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  void _navigateFromDrawer(BuildContext context, Widget screen) {
    Navigator.pop(context);
    AppFeedback.hapticFeedback(HapticType.light);
    AppNavigator.push(
      context,
      screen,
      type: TransitionType.slide,
    );
  }

  void _handleLogout(BuildContext context, AppState appState) async {
    Navigator.pop(context);
    
    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Cerrar Sesión',
      cancelText: 'Cancelar',
      icon: Icons.logout_rounded,
      confirmColor: AppColors.getError(context),
    );

    if (confirmed == true) {
      AppFeedback.showLoadingDialog(context, message: 'Cerrando sesión...');
      
      try {
        await appState.logout();
        
        if (context.mounted) {
          AppFeedback.hideLoadingDialog(context);
          AppNavigator.pushReplacement(
            context,
            const LoginScreen(),
            type: TransitionType.fade,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppFeedback.hideLoadingDialog(context);
          AppFeedback.showError(
            context,
            'Error al cerrar sesión. Inténtalo de nuevo.',
          );
        }
      }
    }
  }
}
