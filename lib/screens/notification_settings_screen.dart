import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> with TickerProviderStateMixin {
  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _isLoading = false;
  int _selectedTabIndex = 0;
  late TabController _tabController;
  
  // Configuración de notificaciones
  bool _notificationsEnabled = true;
  bool _orderReminderEnabled = true;
  bool _statusChangeEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // Horarios personalizados (en horas antes de la entrega)
  int _firstReminderHours = 24;
  int _secondReminderHours = 2;
  int _thirdReminderMinutes = 30;
  
  // Hora del resumen diario
  TimeOfDay _dailyDigestTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingNotifications();
    _loadUserPreferences();
    
    // Escuchar cambios en el AppState para refrescar notificaciones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).addListener(_onAppStateChanged);
    });
  }

  @override
  void dispose() {
    // Remover listener del AppState
    try {
      Provider.of<AppState>(context, listen: false).removeListener(_onAppStateChanged);
    } catch (e) {
      // Ignorar errores si el provider ya no existe
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingNotifications() async {
    setState(() => _isLoading = true);
    try {
      final pending = await NotificationService.getPendingNotifications();
      setState(() => _pendingNotifications = pending);
    } catch (e) {
      print('Error cargando notificaciones: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Callback para manejar cambios en el AppState
  void _onAppStateChanged() {
    // Refrescar notificaciones cuando hay cambios en las órdenes
    if (mounted) {
      _loadPendingNotifications();
      
      // Mostrar mensaje informativo si estamos en la pestaña de notificaciones programadas
      if (_selectedTabIndex == 1) {
        _showMessage('📅 Notificaciones actualizadas automáticamente', isError: false);
      }
    }
  }

  Future<void> _loadUserPreferences() async {
    // Aquí cargarías las preferencias del usuario desde SharedPreferences
    // Por ahora usamos valores por defecto
    setState(() {
      _notificationsEnabled = true;
      _orderReminderEnabled = true;
      _statusChangeEnabled = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
    });
  }

  Future<void> _saveUserPreferences() async {
    // Aquí guardarías las preferencias del usuario en SharedPreferences
    _showMessage('Preferencias guardadas correctamente');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Refrescar notificaciones antes de salir
        await _loadPendingNotifications();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Notificaciones'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveUserPreferences,
              tooltip: 'Guardar configuración',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.settings), text: 'Configuración'),
              Tab(icon: Icon(Icons.schedule), text: 'Programadas'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            onTap: (index) {
              setState(() => _selectedTabIndex = index);
              // Refrescar notificaciones cuando se cambia a la pestaña de programadas
              if (index == 1) {
                _loadPendingNotifications();
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildConfigurationTab(),
                  _buildPendingNotificationsTab(),
                ],
              ),
      ),
    );
  }

  // ========================= TAB 1: CONFIGURACIÓN =========================
  
  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemStatusCard(),
          FormSpacing.verticalMedium(),
          _buildNotificationSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Estado del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusItem(
              icon: Icons.notifications,
              title: 'Servicio de Notificaciones',
              status: 'Activo',
              statusColor: Colors.green,
            ),
            _buildStatusItem(
              icon: Icons.schedule,
              title: 'Notificaciones Programadas',
              status: '${_pendingNotifications.length}',
              statusColor: Colors.blue,
            ),
            _buildStatusItem(
              icon: Icons.access_time,
              title: 'Zona Horaria',
              status: 'America/La_Paz',
              statusColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String title,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon, 
            size: 20, 
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: UIUtils.getSubtitleStyle(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune, 
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Configuración General',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Notificaciones Habilitadas',
              subtitle: 'Activa/desactiva todas las notificaciones',
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
              icon: Icons.notifications,
            ),
            const Divider(height: 24),
            _buildSwitchTile(
              title: 'Recordatorios de Entrega',
              subtitle: 'Notificaciones antes de la fecha de entrega',
              value: _orderReminderEnabled,
              onChanged: _notificationsEnabled ? (value) => setState(() => _orderReminderEnabled = value) : null,
              icon: Icons.schedule,
            ),
            _buildSwitchTile(
              title: 'Cambios de Estado',
              subtitle: 'Notifica cuando cambia el estado de una orden',
              value: _statusChangeEnabled,
              onChanged: _notificationsEnabled ? (value) => setState(() => _statusChangeEnabled = value) : null,
              icon: Icons.update,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon, 
            size: 20, 
            color: onChanged != null 
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: UIUtils.getTitleStyle(context).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onChanged != null 
                        ? null 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                Text(
                  subtitle,
                  style: UIUtils.getSubtitleStyle(context).copyWith(
                    fontSize: 12,
                    color: onChanged != null 
                        ? null 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // ========================= TAB 2: NOTIFICACIONES PROGRAMADAS =========================
  
  Widget _buildPendingNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPendingNotificationsCard(),
        ],
      ),
    );
  }

  Widget _buildPendingNotificationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Notificaciones Programadas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingNotifications.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _loadPendingNotifications,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Actualizar',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Las notificaciones se actualizan automáticamente cuando cambias fechas de entrega.',
              style: UIUtils.getSubtitleStyle(context).copyWith(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            if (_pendingNotifications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No hay notificaciones programadas',
                    style: UIUtils.getTitleStyle(context).copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingNotifications.length,
                itemBuilder: (context, index) {
                  final notification = _pendingNotifications[index];
                  return _buildNotificationItem(notification);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(PendingNotificationRequest notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: UIUtils.cardDecoration(context).copyWith(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: UIUtils.getInfoColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ID: ${notification.id}',
                  style: TextStyle(
                    fontSize: 10,
                    color: UIUtils.getInfoColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.notifications_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notification.title ?? 'Sin título',
            style: UIUtils.getTitleStyle(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notification.body ?? 'Sin contenido',
            style: UIUtils.getSubtitleStyle(context).copyWith(
              fontSize: 12,
            ),
          ),
          if (notification.payload != null) ...[
            const SizedBox(height: 4),
            Text(
              'Payload: ${notification.payload}',
              style: UIUtils.getSubtitleStyle(context).copyWith(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========================= HELPERS =========================

  String _formatDateTime(DateTime date, TimeOfDay time) {
    return '${DateTimeUtils.formatDate(date)} a las ${DateTimeUtils.formatTime(time)}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendiente':
        return UIUtils.getWarningColor(context);
      case 'en_proceso':
        return UIUtils.getInfoColor(context);
      case 'terminado':
        return UIUtils.getSuccessColor(context);
      case 'entregado':
        return Theme.of(context).colorScheme.onSurfaceVariant;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError 
              ? UIUtils.getErrorColor(context) 
              : UIUtils.getSuccessColor(context),
        ),
      );
    }
  }

  // ========================= ACCIONES =========================

}
