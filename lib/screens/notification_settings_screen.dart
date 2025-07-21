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
        await _loadPendingNotifications();
        return true;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Configuración de Notificaciones'),
              backgroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black26,
              actions: [
                IconButton(
                  icon: const Icon(Icons.save_rounded, color: Color(0xFF98CA3F)),
                  onPressed: _saveUserPreferences,
                  tooltip: 'Guardar configuración',
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.settings), text: 'Configuración'),
                      Tab(icon: Icon(Icons.schedule), text: 'Programadas'),
                    ],
                    labelColor: const Color(0xFF98CA3F),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF98CA3F),
                    indicatorWeight: 3,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isTablet ? 18 : 15),
                    onTap: (index) {
                      setState(() => _selectedTabIndex = index);
                      if (index == 1) {
                        _loadPendingNotifications();
                      }
                    },
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFFF5F7FB),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConfigurationTab(isTablet),
                      _buildPendingNotificationsTab(isTablet),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // ========================= TAB 1: CONFIGURACIÓN =========================
  
  Widget _buildConfigurationTab(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 12, vertical: isTablet ? 32 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemStatusCard(isTablet),
          SizedBox(height: isTablet ? 32 : 24),
          _buildNotificationSettingsCard(isTablet),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(bool isTablet) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTablet ? 24 : 16)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(isTablet ? 10 : 6),
                  child: Icon(Icons.info_outline, color: Colors.blue, size: isTablet ? 28 : 22),
                ),
                SizedBox(width: isTablet ? 18 : 10),
                Text(
                  'Estado del Sistema',
                  style: TextStyle(
                    fontSize: isTablet ? 23 : 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 24 : 16),
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
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
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

  Widget _buildNotificationSettingsCard(bool isTablet) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTablet ? 24 : 16)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF98CA3F).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(isTablet ? 10 : 6),
                  child: Icon(Icons.tune, color: Color(0xFF98CA3F), size: isTablet ? 28 : 22),
                ),
                SizedBox(width: isTablet ? 18 : 10),
                Text(
                  'Configuración General',
                  style: TextStyle(
                    fontSize: isTablet ? 23 : 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 24 : 18),
            _buildSwitchTile(
              title: 'Notificaciones Habilitadas',
              subtitle: 'Activa/desactiva todas las notificaciones',
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
              icon: Icons.notifications,
              isTablet: isTablet,
            ),
            Divider(height: isTablet ? 36 : 28, thickness: 1.2),
            _buildSwitchTile(
              title: 'Recordatorios de Entrega',
              subtitle: 'Notificaciones antes de la fecha de entrega',
              value: _orderReminderEnabled,
              onChanged: _notificationsEnabled ? (value) => setState(() => _orderReminderEnabled = value) : null,
              icon: Icons.schedule,
              isTablet: isTablet,
            ),
            _buildSwitchTile(
              title: 'Cambios de Estado',
              subtitle: 'Notifica cuando cambia el estado de una orden',
              value: _statusChangeEnabled,
              onChanged: _notificationsEnabled ? (value) => setState(() => _statusChangeEnabled = value) : null,
              icon: Icons.update,
              isTablet: isTablet,
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
    bool isTablet = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: onChanged != null ? Colors.grey[200] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(isTablet ? 10 : 6),
            child: Icon(icon, size: isTablet ? 28 : 22, color: onChanged != null ? Color(0xFF98CA3F) : Colors.grey[400]),
          ),
          SizedBox(width: isTablet ? 22 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 15,
                    fontWeight: FontWeight.w600,
                    color: onChanged != null ? Colors.black87 : Colors.grey[400],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: onChanged != null ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF98CA3F),
          ),
        ],
      ),
    );
  }

  // ========================= TAB 2: NOTIFICACIONES PROGRAMADAS =========================
  
  Widget _buildPendingNotificationsTab(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 12, vertical: isTablet ? 32 : 18),
      child: Column(
        children: [
          _buildPendingNotificationsCard(isTablet),
        ],
      ),
    );
  }

  Widget _buildPendingNotificationsCard(bool isTablet) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTablet ? 24 : 16)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(isTablet ? 10 : 6),
                      child: Icon(Icons.schedule, color: Colors.blue, size: isTablet ? 28 : 22),
                    ),
                    SizedBox(width: isTablet ? 18 : 10),
                    Text(
                      'Notificaciones Programadas',
                      style: TextStyle(
                        fontSize: isTablet ? 23 : 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 10, vertical: isTablet ? 10 : 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingNotifications.length}',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 13,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 14 : 8),
                    IconButton(
                      onPressed: _loadPendingNotifications,
                      icon: Icon(Icons.refresh, color: Colors.blue, size: isTablet ? 28 : 22),
                      tooltip: 'Actualizar',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: isTablet ? 22 : 14),
            Text(
              'Las notificaciones se actualizan automáticamente cuando cambias fechas de entrega.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isTablet ? 15 : 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: isTablet ? 28 : 18),
            if (_pendingNotifications.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 36 : 24),
                  child: Text(
                    'No hay notificaciones programadas',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: isTablet ? 19 : 16,
                      fontWeight: FontWeight.w500,
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
                  return _buildNotificationItem(notification, isTablet);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(PendingNotificationRequest notification, [bool isTablet = false]) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 12),
      padding: EdgeInsets.all(isTablet ? 28 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 18 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: isTablet ? 12 : 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 8, vertical: isTablet ? 6 : 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 6),
                ),
                child: Text(
                  'ID: ${notification.id}',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 11,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Spacer(),
              Icon(
                Icons.notifications_outlined,
                size: isTablet ? 26 : 18,
                color: Color(0xFF98CA3F),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 10),
          Text(
            notification.title ?? 'Sin título',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 19 : 15,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 10 : 6),
          Text(
            notification.body ?? 'Sin contenido',
            style: TextStyle(
              fontSize: isTablet ? 16 : 13,
              color: Colors.grey[700],
            ),
          ),
          if (notification.payload != null) ...[
            SizedBox(height: isTablet ? 10 : 6),
            Text(
              'Payload: ${notification.payload}',
              style: TextStyle(
                fontSize: isTablet ? 13 : 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
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

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  // ========================= ACCIONES =========================

}
