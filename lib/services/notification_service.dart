import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../models/models.dart';
import '../utils/utils.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  /// Inicializa el servicio de notificaciones
  static Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔍 Inicializando servicio de notificaciones...');

    // Inicializar timezone (solo si no está inicializado)
    if (!tz.timeZoneDatabase.isInitialized) {
      tz.initializeTimeZones();
    }
    
    // Configurar timezone local del dispositivo
    await _initializeDeviceTimezone();

    // Configuración Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Crear canales de notificación
    await _createNotificationChannels();

    // Solicitar permisos
    await _requestPermissions();

    // Inicializar WorkManager para tareas en background
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    _isInitialized = true;
    print('✅ Servicio de notificaciones inicializado correctamente');
  }

  /// Inicializa la zona horaria del dispositivo
  static Future<void> _initializeDeviceTimezone() async {
    try {
      // Obtener la zona horaria del dispositivo
      final String deviceTimezone = DateTime.now().timeZoneName;
      final Duration offset = DateTime.now().timeZoneOffset;
      
      print('🌍 Detectando timezone del dispositivo: $deviceTimezone (offset: ${offset.inHours}h)');
      
      // Intentar configurar la zona horaria detectada
      try {
        // Mapear algunos timezones comunes
        final Map<String, String> timezoneMap = {
          'BOT': 'America/La_Paz',
          'ART': 'America/Argentina/Buenos_Aires',
          'PET': 'America/Lima',
          'COT': 'America/Bogota',
          'ECT': 'America/Guayaquil',
          'VET': 'America/Caracas',
          'BRT': 'America/Sao_Paulo',
          'CLT': 'America/Santiago',
          'UYT': 'America/Montevideo',
          'PYT': 'America/Asuncion',
          'GMT': 'UTC',
          'UTC': 'UTC',
        };
        
        // Primero intentar usar el timezone mapeado
        if (timezoneMap.containsKey(deviceTimezone)) {
          final location = tz.getLocation(timezoneMap[deviceTimezone]!);
          tz.setLocalLocation(location);
          print('✅ Timezone configurado desde mapa: ${timezoneMap[deviceTimezone]}');
          return;
        }
        
        // Si no está mapeado, usar el offset para encontrar la zona horaria apropiada
        final String timezoneId = _getTimezoneFromOffset(offset);
        final location = tz.getLocation(timezoneId);
        tz.setLocalLocation(location);
        print('✅ Timezone configurado desde offset: $timezoneId');
        
      } catch (e) {
        print('⚠️ Error configurando timezone específico: $e');
        
        // Fallback: usar UTC como zona horaria segura
        tz.setLocalLocation(tz.getLocation('UTC'));
        print('✅ Timezone fallback configurado: UTC');
      }
      
    } catch (e) {
      print('❌ Error inicializando timezone del dispositivo: $e');
      
      // Fallback final: UTC
      tz.setLocalLocation(tz.getLocation('UTC'));
      print('✅ Timezone fallback final configurado: UTC');
    }
  }

  /// Obtiene la zona horaria basada en el offset del dispositivo
  static String _getTimezoneFromOffset(Duration offset) {
    final hours = offset.inHours;
    
    // Mapear offsets comunes a zonas horarias (considerando horario estándar)
    switch (hours) {
      case -12: return 'Pacific/Kwajalein';
      case -11: return 'Pacific/Midway';
      case -10: return 'Pacific/Honolulu';
      case -9: return 'America/Anchorage';
      case -8: return 'America/Los_Angeles';
      case -7: return 'America/Denver';
      case -6: return 'America/Chicago';
      case -5: return 'America/New_York';
      case -4: return 'America/La_Paz'; // Bolivia, Paraguay, Venezuela
      case -3: return 'America/Argentina/Buenos_Aires'; // Argentina, Brasil, Uruguay
      case -2: return 'America/Noronha';
      case -1: return 'Atlantic/Azores';
      case 0: return 'UTC';
      case 1: return 'Europe/Paris';
      case 2: return 'Europe/Helsinki';
      case 3: return 'Europe/Moscow';
      case 4: return 'Asia/Dubai';
      case 5: return 'Asia/Karachi';
      case 6: return 'Asia/Dhaka';
      case 7: return 'Asia/Jakarta';
      case 8: return 'Asia/Shanghai';
      case 9: return 'Asia/Tokyo';
      case 10: return 'Australia/Sydney';
      case 11: return 'Pacific/Noumea';
      case 12: return 'Pacific/Auckland';
      default: return 'UTC'; // Fallback para cualquier otro offset
    }
  }

  /// Callback para manejar tareas en background
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      print('🔄 Ejecutando tarea en background: $task');
      
      switch (task) {
        case 'dailyDigest':
          await _sendDailyDigest();
          break;
        case 'checkOverdueOrders':
          await _checkOverdueOrders();
          break;
      }
      
      return Future.value(true);
    });
  }

  /// Crea los canales de notificación
  static Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'order_reminders',
        'Recordatorios de Órdenes',
        description: 'Notificaciones de recordatorios de entrega',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'order_status',
        'Estado de Órdenes',
        description: 'Notificaciones de cambios de estado',
        importance: Importance.defaultImportance,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'daily_digest',
        'Resumen Diario',
        description: 'Resumen diario de órdenes',
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        'overdue_alerts',
        'Alertas de Retraso',
        description: 'Alertas de órdenes vencidas',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Solicita permisos de notificación
  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Solicitar permiso de notificación
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      print('📱 Permiso de notificaciones: ${granted ?? false}');

      // Solicitar permiso de alarma exacta
      final bool? exactAlarmsGranted = await androidImplementation?.requestExactAlarmsPermission();
      print('⏰ Permiso de alarmas exactas: ${exactAlarmsGranted ?? false}');
    }
  }

  /// Maneja el tap en notificaciones
  static void _onNotificationTap(NotificationResponse notificationResponse) {
    print('🔔 Notificación tocada: ${notificationResponse.payload}');
    // TODO: Implementar navegación según el payload
  }

  /// Programa notificaciones para una orden
  static Future<void> scheduleOrderNotifications(OrdenTrabajo orden) async {
    await initialize();
    
    // Cancelar notificaciones previas de esta orden
    await cancelOrderNotifications(orden.id);
    
    print('📅 Programando notificaciones para orden ${orden.id}');
    
    // Crear fecha y hora de entrega precisa
    final tz.TZDateTime deliveryTZ = tz.TZDateTime(
      tz.local,
      orden.fechaEntrega.year,
      orden.fechaEntrega.month,
      orden.fechaEntrega.day,
      orden.horaEntrega.hour,
      orden.horaEntrega.minute,
    );
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    
    print('📍 Fecha de entrega local TZ: ${deliveryTZ.toString()}');
    print('⏰ Hora actual: ${now.toString()}');
    
    // Si la fecha de entrega ya pasó, no hacer nada
    if (deliveryTZ.isBefore(now)) {
      print('⚠️ Fecha de entrega ya pasó, no se programan notificaciones');
      return;
    }

    // --- Generar contenido detallado para la notificación ---
    final String horaEntrega = DateTimeUtils.formatTime(orden.horaEntrega);
    final String trabajosResumen = orden.trabajos
        .map((t) => '${t.trabajo.nombre} (${t.ancho}x${t.alto}m, ${t.cantidad}ud)')
        .join(', ');

    // Calcular minutos restantes
    final Duration timeRemaining = deliveryTZ.difference(now);
    final int minutesRemaining = timeRemaining.inMinutes;

    // Lógica para órdenes urgentes (menos de 30 minutos)
    if (minutesRemaining <= 30) {
      print('🔥 Orden Urgente! Menos de 30 minutos restantes.');
      await _showNotification(
        id: '${orden.id}_urgent'.hashCode,
        title: '🔥 Entrega para ${orden.cliente.nombre} en $minutesRemaining min!',
        body: 'Hora: $horaEntrega. Trabajos: $trabajosResumen',
        channelId: 'overdue_alerts', // Usar canal de alta prioridad
        payload: 'order_${orden.id}',
      );
      return; // No programar más notificaciones
    }

    // Notificación 24 horas antes
    final tz.TZDateTime reminder24h = deliveryTZ.subtract(const Duration(hours: 24));
    if (reminder24h.isAfter(now)) {
      await _scheduleNotification(
        id: '${orden.id}_24h'.hashCode,
        title: '📅 Entrega para ${orden.cliente.nombre} mañana',
        body: 'Hora: $horaEntrega. Trabajos: $trabajosResumen',
        scheduledDate: reminder24h,
        channelId: 'order_reminders',
        payload: 'order_${orden.id}',
      );
    }
    
    // Notificación 2 horas antes
    final tz.TZDateTime reminder2h = deliveryTZ.subtract(const Duration(hours: 2));
    if (reminder2h.isAfter(now)) {
      await _scheduleNotification(
        id: '${orden.id}_2h'.hashCode,
        title: '⏰ Entrega para ${orden.cliente.nombre} en 2 horas',
        body: 'Hora: $horaEntrega. Trabajos: $trabajosResumen',
        scheduledDate: reminder2h,
        channelId: 'order_reminders',
        payload: 'order_${orden.id}',
      );
    }
    
    // Notificación 30 minutos antes
    final tz.TZDateTime reminder30min = deliveryTZ.subtract(const Duration(minutes: 30));
    if (reminder30min.isAfter(now)) {
      await _scheduleNotification(
        id: '${orden.id}_30min'.hashCode,
        title: '🚨 Entrega para ${orden.cliente.nombre} en 30 min',
        body: 'Hora: $horaEntrega. Trabajos: $trabajosResumen',
        scheduledDate: reminder30min,
        channelId: 'order_reminders',
        payload: 'order_${orden.id}',
      );
    }
    
    print('✅ Notificaciones programadas para orden ${orden.id}');
  }

  /// Programa una notificación específica
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String channelId,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'order_reminders',
      'Recordatorios de Órdenes',
      channelDescription: 'Notificaciones de recordatorios de entrega',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      print('📅 Notificación programada: $title para ${scheduledDate.toString()}');
    } catch (e) {
      print('❌ Error programando notificación: $e');
    }
  }

  /// Notifica cambio de estado de una orden
  static Future<void> notifyOrderStatusChange(OrdenTrabajo orden, String newStatus) async {
    await initialize();
    
    String statusText = '';
    String emoji = '';
    
    switch (newStatus) {
      case 'pendiente':
        statusText = 'Pendiente';
        emoji = '📋';
        break;
      case 'en_proceso':
        statusText = 'En Proceso';
        emoji = '🔄';
        break;
      case 'terminado':
        statusText = 'Terminado';
        emoji = '✅';
        break;
      case 'entregado':
        statusText = 'Entregado';
        emoji = '🎉';
        break;
    }
    
    await _showNotification(
      id: '${orden.id}_status'.hashCode,
      title: '$emoji Estado Actualizado',
      body: 'Orden de ${orden.cliente.nombre} ahora está: $statusText',
      channelId: 'order_status',
      payload: 'order_${orden.id}',
    );
  }

  /// Muestra una notificación inmediata
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'order_status',
      'Estado de Órdenes',
      channelDescription: 'Notificaciones de cambios de estado',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Cancela las notificaciones de una orden
  static Future<void> cancelOrderNotifications(String orderId) async {
    await initialize();
    
    final List<int> idsToCancel = [
      '${orderId}_24h'.hashCode,
      '${orderId}_2h'.hashCode,
      '${orderId}_30min'.hashCode,
      '${orderId}_status'.hashCode,
    ];
    
    for (final id in idsToCancel) {
      await _flutterLocalNotificationsPlugin.cancel(id);
    }
    
    print('🚫 Notificaciones canceladas para orden: $orderId');
  }

  /// Programa resumen diario
  static Future<void> scheduleDailyDigest({TimeOfDay? time}) async {
    await initialize();
    
    // Cancelar digest anterior
    await Workmanager().cancelByUniqueName('dailyDigest');
    
    // Usar horario personalizado o por defecto (8:00 AM)
    final digestTime = time ?? const TimeOfDay(hour: 8, minute: 0);
    
    // Programar para el horario especificado todos los días
    await Workmanager().registerPeriodicTask(
      'dailyDigest',
      'dailyDigest',
      frequency: const Duration(hours: 24),
      initialDelay: _getNextDailyDigestTime(digestTime),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
    
    print('📊 Resumen diario programado para las ${digestTime.hour.toString().padLeft(2, '0')}:${digestTime.minute.toString().padLeft(2, '0')}');
  }

  /// Calcula el tiempo hasta el próximo resumen diario
  static Duration _getNextDailyDigestTime([TimeOfDay? targetTime]) {
    final digestTime = targetTime ?? const TimeOfDay(hour: 8, minute: 0);
    final now = DateTimeUtils.nowLocal().toLocal();
    var nextDigest = DateTimeUtils.combineDateTime(
      DateTime(now.year, now.month, now.day),
      digestTime,
    );
    
    if (nextDigest.isBefore(now)) {
      nextDigest = nextDigest.add(const Duration(days: 1));
    }

    return nextDigest.difference(now);
  }  /// Envía el resumen diario
  static Future<void> _sendDailyDigest() async {
    try {
      // Obtener la fecha actual
      final now = DateTimeUtils.nowLocal().toLocal();
      final todayString = DateTimeUtils.formatDate(now);
      
      await _showNotification(
        id: 'daily_digest'.hashCode,
        title: '📊 Resumen Diario - $todayString',
        body: 'Buenos días! Revisa tus órdenes pendientes y entregas de hoy',
        channelId: 'daily_digest',
        payload: 'daily_digest:$todayString',
      );
      
      print('📊 Resumen diario enviado');
    } catch (e) {
      print('❌ Error enviando resumen diario: $e');
    }
  }

  /// Verifica órdenes vencidas
  static Future<void> _checkOverdueOrders() async {
    try {
      print('🔍 Verificando órdenes vencidas...');
      
      // Enviar notificación de verificación
      await _showNotification(
        id: 'overdue_check'.hashCode,
        title: '🔍 Verificación de Órdenes',
        body: 'Revisa si tienes órdenes vencidas que requieren atención',
        channelId: 'overdue_alerts',
        payload: 'overdue_check:${DateTime.now().millisecondsSinceEpoch}',
      );
      
      print('🔍 Verificación de órdenes vencidas completada');
    } catch (e) {
      print('❌ Error verificando órdenes vencidas: $e');
    }
  }

  /// Obtiene notificaciones pendientes
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize();
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Cancela todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    await initialize();
    await _flutterLocalNotificationsPlugin.cancelAll();
    await Workmanager().cancelAll();
    print('🚫 Todas las notificaciones canceladas');
  }

  /// Verifica configuración del sistema
  static Future<void> checkSystemConfiguration() async {
    await initialize();
    
    final pending = await getPendingNotifications();
    print('🔍 Verificación del sistema de notificaciones:');
    print('  📱 Servicio inicializado: $_isInitialized');
    print('  🔔 Notificaciones pendientes: ${pending.length}');
    
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? notificationsEnabled = await androidImplementation?.areNotificationsEnabled();
      print('  📢 Notificaciones habilitadas: ${notificationsEnabled ?? false}');
    }
  }

  /// Método de prueba - Notificación inmediata
  static Future<void> testNotification() async {
    await initialize();
    
    await _showNotification(
      id: 999,
      title: '🧪 Prueba de Notificación',
      body: 'Esta es una notificación de prueba',
      channelId: 'order_status',
    );
    
    print('✅ Notificación de prueba enviada');
  }

  /// Método de prueba - Notificación programada en 30 segundos
  static Future<void> testScheduledNotification() async {
    await initialize();
    
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30));
    
    await _scheduleNotification(
      id: 998,
      title: '⏰ Prueba Programada',
      body: 'Notificación programada hace 30 segundos',
      scheduledDate: scheduledDate,
      channelId: 'order_reminders',
    );
    
    print('✅ Notificación programada de prueba en 30 segundos');
  }

  /// Método de prueba - Notificación programada en 2 minutos
  static Future<void> testScheduledNotification2Minutes() async {
    await initialize();
    
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2));
    
    await _scheduleNotification(
      id: 997,
      title: '⏰ Prueba Programada - 2 minutos',
      body: 'Notificación programada hace 2 minutos',
      scheduledDate: scheduledDate,
      channelId: 'order_reminders',
    );
    
    print('✅ Notificación programada de prueba en 2 minutos');
  }

  /// Muestra notificación de orden vencida
  static Future<void> showOverdueOrderNotification(OrdenTrabajo orden) async {
    await initialize();
    
    final now = DateTimeUtils.nowLocal().toLocal();
    final deliveryDateTime = DateTimeUtils.combineDateTime(orden.fechaEntrega, orden.horaEntrega);
    final overdueDuration = now.difference(deliveryDateTime);
    
    final overdueText = DateTimeUtils.getTimeRemaining(orden.fechaEntrega, orden.horaEntrega);
    
    await _showNotification(
      id: orden.id.hashCode + 9000, // ID único para órdenes vencidas
      title: '🚨 Orden Vencida',
      body: '${orden.cliente.nombre} - $overdueText',
      channelId: 'overdue_alerts',
      payload: 'orden_vencida:${orden.id}',
    );
    
    print('🚨 Notificación de orden vencida enviada: ${orden.cliente.nombre}');
  }

}
