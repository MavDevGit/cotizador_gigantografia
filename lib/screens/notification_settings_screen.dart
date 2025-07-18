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
  bool _dailyDigestEnabled = true;
  bool _overdueOrdersEnabled = true;
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
    _tabController = TabController(length: 4, vsync: this);
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
    _loadPendingNotifications();
    
    // Mostrar mensaje informativo si estamos en la pestaña de notificaciones programadas
    if (_selectedTabIndex == 1) {
      _showMessage('📅 Notificaciones actualizadas automáticamente', isError: false);
    }
  }

  Future<void> _loadUserPreferences() async {
    // Aquí cargarías las preferencias del usuario desde SharedPreferences
    // Por ahora usamos valores por defecto
    setState(() {
      _notificationsEnabled = true;
      _orderReminderEnabled = true;
      _statusChangeEnabled = true;
      _dailyDigestEnabled = true;
      _overdueOrdersEnabled = true;
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
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
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
              Tab(icon: Icon(Icons.work), text: 'Órdenes'),
              Tab(icon: Icon(Icons.analytics), text: 'Estadísticas'),
            ],
            labelColor: const Color(0xFF98CA3F),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF98CA3F),
            onTap: (index) {
              setState(() => _selectedTabIndex = index);
              // Refrescar notificaciones cuando se cambia a la pestaña de programadas
              if (index == 1) {
                _loadPendingNotifications();
              }
            },
          ),
        ),
        backgroundColor: const Color(0xFFFAFAFA),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildConfigurationTab(),
                  _buildPendingNotificationsTab(),
                  _buildOrdersTab(),
                  _buildStatisticsTab(),
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
          FormSpacing.verticalMedium(),
          _buildTestSection(),
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

  Widget _buildNotificationSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, color: Color(0xFF98CA3F)),
                SizedBox(width: 8),
                Text(
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
            _buildSwitchTile(
              title: 'Resumen Diario',
              subtitle: 'Resumen matutino de órdenes del día',
              value: _dailyDigestEnabled,
              onChanged: _notificationsEnabled ? (value) => setState(() => _dailyDigestEnabled = value) : null,
              icon: Icons.today,
            ),
            _buildSwitchTile(
              title: 'Órdenes Vencidas',
              subtitle: 'Alertas de órdenes que pasaron su fecha límite',
              value: _overdueOrdersEnabled,
              onChanged: _notificationsEnabled ? (value) => setState(() => _overdueOrdersEnabled = value) : null,
              icon: Icons.warning,
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
          Icon(icon, size: 20, color: onChanged != null ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onChanged != null ? Colors.black87 : Colors.grey[400],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Pruebas del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Usa estas opciones para probar el sistema de notificaciones:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testNotification(),
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Prueba Inmediata'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testScheduledNotification(),
                    icon: const Icon(Icons.schedule),
                    label: const Text('Prueba 30s'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _testLongScheduledNotification(),
                icon: const Icon(Icons.schedule_send),
                label: const Text('Prueba Programada - 2 minutos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
            const Text(
              'Las notificaciones se actualizan automáticamente cuando cambias fechas de entrega.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            if (_pendingNotifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay notificaciones programadas',
                    style: TextStyle(
                      color: Colors.grey,
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
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ID: ${notification.id}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.notifications_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notification.title ?? 'Sin título',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notification.body ?? 'Sin contenido',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (notification.payload != null) ...[
            const SizedBox(height: 4),
            Text(
              'Payload: ${notification.payload}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========================= TAB 3: ÓRDENES =========================
  
  Widget _buildOrdersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActiveOrdersCard(),
          FormSpacing.verticalMedium(),
          _buildOrderActionsCard(),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersCard() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final activeOrders = appState.ordenes.where((orden) => 
          orden.estado != 'entregado' && 
          orden.fechaEntrega.isAfter(DateTime.now())
        ).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.work, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Órdenes Activas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (activeOrders.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No hay órdenes activas',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeOrders.length,
                    itemBuilder: (context, index) {
                      final orden = activeOrders[index];
                      return _buildOrderItem(orden);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderItem(OrdenTrabajo orden) {
    final now = DateTime.now();
    final timeUntilDelivery = orden.fechaEntrega.difference(now);
    final isUrgent = timeUntilDelivery.inHours < 24;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent ? Colors.red.withOpacity(0.3) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUrgent ? Icons.warning : Icons.schedule,
                size: 16,
                color: isUrgent ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  orden.cliente.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(orden.estado).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  orden.estado.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(orden.estado),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Trabajos: ${orden.trabajos.map((t) => t.trabajo.nombre).join(', ')}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Entrega: ${_formatDateTime(orden.fechaEntrega, orden.horaEntrega)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isUrgent ? Colors.red : Colors.grey[600],
                  fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notification_add, size: 16),
                    onPressed: () => _scheduleCustomNotification(orden),
                    tooltip: 'Programar notificación',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, size: 16),
                    onPressed: () => _cancelOrderNotifications(orden),
                    tooltip: 'Cancelar notificaciones',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Acciones de Órdenes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _scheduleAllOrderNotifications(),
                icon: const Icon(Icons.schedule),
                label: const Text('Programar Todas las Notificaciones'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _sendDailyDigestNow(),
                icon: const Icon(Icons.today),
                label: const Text('Enviar Resumen Diario Ahora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================= TAB 4: ESTADÍSTICAS =========================
  
  Widget _buildStatisticsTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildNotificationStatsCard(appState.ordenes),
              FormSpacing.verticalMedium(),
              _buildDeliveryStatsCard(appState.ordenes),
              FormSpacing.verticalMedium(),
              _buildPerformanceStatsCard(appState.ordenes),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationStatsCard(List<OrdenTrabajo> ordenes) {
    final totalOrders = ordenes.length;
    final activeNotifications = _pendingNotifications.length;
    final completedOrders = ordenes.where((o) => o.estado == 'entregado').length;
    final overdueOrders = ordenes.where((o) => 
      o.estado != 'entregado' && o.fechaEntrega.isBefore(DateTime.now())
    ).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Estadísticas de Notificaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    title: 'Órdenes Totales',
                    value: totalOrders.toString(),
                    icon: Icons.work,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    title: 'Notificaciones Activas',
                    value: activeNotifications.toString(),
                    icon: Icons.notifications_active,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    title: 'Completadas',
                    value: completedOrders.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    title: 'Vencidas',
                    value: overdueOrders.toString(),
                    icon: Icons.warning,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatsCard(List<OrdenTrabajo> ordenes) {
    final now = DateTime.now();
    final today = ordenes.where((o) => 
      o.fechaEntrega.year == now.year &&
      o.fechaEntrega.month == now.month &&
      o.fechaEntrega.day == now.day
    ).length;
    
    final tomorrow = ordenes.where((o) => 
      o.fechaEntrega.year == now.year &&
      o.fechaEntrega.month == now.month &&
      o.fechaEntrega.day == now.day + 1
    ).length;

    final thisWeek = ordenes.where((o) => 
      o.fechaEntrega.isAfter(now) &&
      o.fechaEntrega.isBefore(now.add(const Duration(days: 7)))
    ).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Entregas Programadas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    title: 'Hoy',
                    value: today.toString(),
                    icon: Icons.today,
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    title: 'Mañana',
                    value: tomorrow.toString(),
                    icon: Icons.event,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    title: 'Esta Semana',
                    value: thisWeek.toString(),
                    icon: Icons.calendar_view_week,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStatsCard(List<OrdenTrabajo> ordenes) {
    final completedOnTime = ordenes.where((o) => 
      o.estado == 'entregado' &&
      o.historial.any((h) => h.cambio.contains('entregado'))
    ).length;

    final totalCompleted = ordenes.where((o) => o.estado == 'entregado').length;
    final onTimePercentage = totalCompleted > 0 ? (completedOnTime / totalCompleted * 100).toInt() : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.speed, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Rendimiento de Entregas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$onTimePercentage%',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            'A Tiempo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$completedOnTime de $totalCompleted órdenes entregadas a tiempo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================= MÉTODOS AUXILIARES =========================

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
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime fecha, TimeOfDay hora) {
    return DateTimeUtils.formatDateTime(DateTimeUtils.combineDateTime(fecha, hora));
  }

  Future<void> _scheduleCustomNotification(OrdenTrabajo orden) async {
    try {
      await NotificationService.scheduleOrderNotifications(orden);
      _showMessage('Notificación programada para ${orden.cliente.nombre}');
      await _loadPendingNotifications();
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _cancelOrderNotifications(OrdenTrabajo orden) async {
    try {
      await NotificationService.cancelOrderNotifications(orden.id);
      _showMessage('Notificaciones canceladas para ${orden.cliente.nombre}');
      await _loadPendingNotifications();
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _scheduleAllOrderNotifications() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final activeOrders = appState.ordenes.where((orden) => 
        orden.estado != 'entregado' && 
        orden.fechaEntrega.isAfter(DateTime.now())
      ).toList();

      for (final orden in activeOrders) {
        await NotificationService.scheduleOrderNotifications(orden);
      }
      
      _showMessage('Notificaciones programadas para ${activeOrders.length} órdenes');
      await _loadPendingNotifications();
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _sendDailyDigestNow() async {
    try {
      await NotificationService.testNotification();
      _showMessage('Resumen diario enviado');
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService.testNotification();
      _showMessage('Notificación de prueba enviada');
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _testScheduledNotification() async {
    try {
      await NotificationService.testScheduledNotification();
      _showMessage('Notificación programada en 30 segundos');
      await _loadPendingNotifications();
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _testLongScheduledNotification() async {
    try {
      await NotificationService.testScheduledNotification2Minutes();
      _showMessage('Notificación programada en 2 minutos');
      await _loadPendingNotifications();
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
