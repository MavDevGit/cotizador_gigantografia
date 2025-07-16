import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// You need to generate these files with 'flutter pub run build_runner build'
part 'main.g.dart';

// -------------------
// --- ARCHIVO SERVICE ---
// -------------------

class ArchivoService {
  static Future<Directory> _getAppDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final archivosDir = Directory('${directory.path}/archivos_adjuntos');
    if (!await archivosDir.exists()) {
      await archivosDir.create(recursive: true);
    }
    return archivosDir;
  }

  static Future<List<ArchivoAdjunto>> seleccionarArchivos(
    String usuarioId,
    String usuarioNombre,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowedExtensions: null,
      );

      if (result != null && result.files.isNotEmpty) {
        List<ArchivoAdjunto> archivos = [];
        final appDir = await _getAppDocumentsDirectory();

        for (PlatformFile file in result.files) {
          if (file.path != null) {
            // Generar nombre único para el archivo
            final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final String destinationPath = '${appDir.path}/$fileName';
            
            // Copiar archivo al directorio de la aplicación
            await File(file.path!).copy(destinationPath);
            
            // Obtener tipo MIME
            final String mimeType = lookupMimeType(destinationPath) ?? 'application/octet-stream';
            
            // Crear objeto ArchivoAdjunto
            final archivo = ArchivoAdjunto(
              id: Random().nextDouble().toString(),
              nombre: file.name,
              rutaArchivo: destinationPath,
              tipoMime: mimeType,
              tamano: file.size,
              fechaSubida: DateTime.now(),
              subidoPorUsuarioId: usuarioId,
              subidoPorUsuarioNombre: usuarioNombre,
            );
            
            archivos.add(archivo);
          }
        }
        
        return archivos;
      }
      
      return [];
    } catch (e) {
      print('Error al seleccionar archivos: $e');
      return [];
    }
  }

  static Future<bool> eliminarArchivo(ArchivoAdjunto archivo) async {
    try {
      final file = File(archivo.rutaArchivo);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al eliminar archivo: $e');
      return false;
    }
  }

  static Future<bool> abrirArchivo(ArchivoAdjunto archivo) async {
    try {
      final file = File(archivo.rutaArchivo);
      if (await file.exists()) {
        final result = await OpenFile.open(archivo.rutaArchivo);
        return result.type == ResultType.done;
      }
      return false;
    } catch (e) {
      print('Error al abrir archivo: $e');
      return false;
    }
  }

  static Future<void> limpiarArchivosOrfanos() async {
    try {
      final appDir = await _getAppDocumentsDirectory();
      final archivos = appDir.listSync();
      
      // Aquí podrías implementar lógica para eliminar archivos que ya no están
      // referenciados en ninguna orden de trabajo
      
      print('Limpieza de archivos completada');
    } catch (e) {
      print('Error en limpieza de archivos: $e');
    }
  }
}

// -------------------
// --- RESPONSIVE UTILITIES ---
// -------------------

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
  
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobile && 
           MediaQuery.of(context).size.width < tablet;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }
  
  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < mobile) return screenWidth;
    if (screenWidth < tablet) return screenWidth * 0.95;
    if (screenWidth < desktop) return screenWidth * 0.9;
    return 1200; // Max width for desktop
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

// Utilidades para espaciado consistente
class FormSpacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
  
  static Widget verticalSmall() => const SizedBox(height: small);
  static Widget verticalMedium() => const SizedBox(height: medium);
  static Widget verticalLarge() => const SizedBox(height: large);
  static Widget verticalExtraLarge() => const SizedBox(height: extraLarge);
  
  static Widget horizontalSmall() => const SizedBox(width: small);
  static Widget horizontalMedium() => const SizedBox(width: medium);
  static Widget horizontalLarge() => const SizedBox(width: large);
  static Widget horizontalExtraLarge() => const SizedBox(width: extraLarge);
}

// -------------------
// --- NOTIFICATION SERVICE ---
// -------------------

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/La_Paz')); // Bolivia timezone

    // Configuración para Android
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuración para iOS (si planeas soportarlo)
    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          print('Notificación tocada: ${response.payload}');
        }
      },
    );

    // Solicitar permisos para Android 13+
    await _requestPermissions();

    // Inicializar Workmanager para notificaciones en background
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    _isInitialized = true;
  }

  static Future<void> _requestPermissions() async {
    // Para flutter_local_notifications v17.2.3
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      if (granted != null && granted) {
        print('Permisos de notificación concedidos');
      }
    }
  }

  // Método removido - no es necesario para la versión 13.0.0
  // static void _onNotificationTap(NotificationResponse response) {
  //   print('Notificación tocada: ${response.payload}');
  // }

  // Programar notificaciones para una orden de trabajo
  static Future<void> scheduleOrderNotifications(OrdenTrabajo orden) async {
    print('📅 scheduleOrderNotifications: Iniciando para orden ${orden.id}');
    
    if (!_isInitialized) await initialize();

    // Solo notificar si está en proceso
    if (orden.estado != 'en_proceso') {
      print('📅 No se programan notificaciones - Estado: ${orden.estado}');
      return;
    }

    // Cancelar notificaciones existentes para esta orden
    await cancelOrderNotifications(orden.id);

    final now = DateTime.now();
    final deliveryDateTime = DateTime(
      orden.fechaEntrega.year,
      orden.fechaEntrega.month,
      orden.fechaEntrega.day,
      orden.horaEntrega.hour,
      orden.horaEntrega.minute,
    );

    print('📅 Fecha/hora actual: $now');
    print('📅 Fecha/hora de entrega: $deliveryDateTime');

    // Si la fecha de entrega ya pasó, no programar notificaciones
    if (deliveryDateTime.isBefore(now)) {
      print('📅 No se programan notificaciones - Fecha de entrega ya pasó');
      return;
    }

    final timeUntilDelivery = deliveryDateTime.difference(now);
    final isToday = _isSameDay(now, deliveryDateTime);

    print('📅 Tiempo hasta entrega: ${timeUntilDelivery.inMinutes} minutos');
    print('📅 Es hoy: $isToday');

    List<NotificationSchedule> schedules = [];

    if (isToday) {
      // Si es hoy, notificar 15 minutos antes
      if (timeUntilDelivery.inMinutes > 15) {
        final notificationTime = deliveryDateTime.subtract(const Duration(minutes: 15));
        print('📅 Programando notificación para: $notificationTime (15 min antes)');
        schedules.add(NotificationSchedule(
          id: '${orden.id}_15min',
          title: 'Entrega en 15 minutos',
          body: 'Orden #${orden.id.substring(0, 8)} para ${orden.cliente.nombre}',
          scheduledTime: notificationTime,
          payload: orden.id,
        ));
      } else {
        print('📅 No se programa notificación - Faltan solo ${timeUntilDelivery.inMinutes} minutos');
      }
    } else {
      // Si es otro día, notificar 2 horas y 1 hora antes
      if (timeUntilDelivery.inHours > 2) {
        final notificationTime = deliveryDateTime.subtract(const Duration(hours: 2));
        print('📅 Programando notificación para: $notificationTime (2 horas antes)');
        schedules.add(NotificationSchedule(
          id: '${orden.id}_2h',
          title: 'Entrega en 2 horas',
          body: 'Orden #${orden.id.substring(0, 8)} para ${orden.cliente.nombre}',
          scheduledTime: notificationTime,
          payload: orden.id,
        ));
      }
      
      if (timeUntilDelivery.inHours > 1) {
        final notificationTime = deliveryDateTime.subtract(const Duration(hours: 1));
        print('📅 Programando notificación para: $notificationTime (1 hora antes)');
        schedules.add(NotificationSchedule(
          id: '${orden.id}_1h',
          title: 'Entrega en 1 hora',
          body: 'Orden #${orden.id.substring(0, 8)} para ${orden.cliente.nombre}',
          scheduledTime: notificationTime,
          payload: orden.id,
        ));
      }
    }

    print('📅 Total de notificaciones a programar: ${schedules.length}');

    // Programar las notificaciones
    for (final schedule in schedules) {
      await _scheduleNotification(schedule);
      print('📅 Notificación programada: ${schedule.id} para ${schedule.scheduledTime}');
    }

    // Programar verificación en background
    await _scheduleBackgroundCheck(orden);
    print('📅 Verificación en background programada');
    
    // Mostrar notificación inmediata informando que se programaron las notificaciones
    if (schedules.isNotEmpty) {
      String mensaje;
      if (schedules.length == 1) {
        final schedule = schedules.first;
        final timeStr = DateFormat('HH:mm dd/MM/yyyy').format(schedule.scheduledTime);
        mensaje = 'Notificación programada para ${timeStr}';
      } else {
        mensaje = '${schedules.length} notificaciones programadas para esta orden';
      }
      
      await showImmediateNotification(
        title: '📅 Notificaciones Programadas',
        body: 'Orden #${orden.id.substring(0, 8)} - $mensaje',
        payload: 'schedule_info_${orden.id}',
      );
    }
  }

  static Future<void> _scheduleNotification(NotificationSchedule schedule) async {
    print('🔔 _scheduleNotification: Programando ${schedule.id} para ${schedule.scheduledTime}');
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'order_delivery_channel',
      'Entregas de Órdenes',
      channelDescription: 'Notificaciones para entregas de órdenes de trabajo',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF98CA3F),
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.zonedSchedule(
        schedule.id.hashCode,
        schedule.title,
        schedule.body,
        tz.TZDateTime.from(schedule.scheduledTime, tz.local),
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: schedule.payload,
      );
      print('🔔 ✅ Notificación ${schedule.id} programada exitosamente');
    } catch (e) {
      print('🔔 ❌ Error al programar notificación ${schedule.id}: $e');
    }
  }

  static Future<void> _scheduleBackgroundCheck(OrdenTrabajo orden) async {
    await Workmanager().registerOneOffTask(
      'check_order_${orden.id}',
      'checkOrderDelivery',
      initialDelay: const Duration(minutes: 5),
      inputData: {
        'orderId': orden.id,
        'clienteName': orden.cliente.nombre,
        'deliveryDate': orden.fechaEntrega.toIso8601String(),
        'deliveryHour': orden.horaEntrega.hour,
        'deliveryMinute': orden.horaEntrega.minute,
      },
    );
  }

  // Cancelar notificaciones para una orden específica
  static Future<void> cancelOrderNotifications(String orderId) async {
    print('🗑️ cancelOrderNotifications: Cancelando notificaciones para orden $orderId');
    
    final notifications = [
      '${orderId}_15min',
      '${orderId}_1h',
      '${orderId}_2h',
    ];

    for (final notificationId in notifications) {
      try {
        await _notifications.cancel(notificationId.hashCode);
        print('🗑️ ✅ Notificación $notificationId cancelada');
      } catch (e) {
        print('🗑️ ❌ Error al cancelar notificación $notificationId: $e');
      }
    }

    // Cancelar tarea de background
    try {
      await Workmanager().cancelByUniqueName('check_order_$orderId');
      print('🗑️ ✅ Tarea de background cancelada para orden $orderId');
    } catch (e) {
      print('🗑️ ❌ Error al cancelar tarea de background para orden $orderId: $e');
    }
  }

  // Cancelar todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    await Workmanager().cancelAll();
  }

  // Actualizar notificaciones cuando cambia el estado, fecha o hora de la orden
  static Future<void> updateOrderNotifications(OrdenTrabajo orden) async {
    print('🔄 updateOrderNotifications: Iniciando para orden ${orden.id}');
    print('🔄 Estado de la orden: ${orden.estado}');
    print('🔄 Fecha de entrega: ${orden.fechaEntrega}');
    print('🔄 Hora de entrega: ${orden.horaEntrega}');
    
    // Primero cancelar todas las notificaciones existentes para esta orden
    await cancelOrderNotifications(orden.id);
    print('🔄 Notificaciones canceladas para orden ${orden.id}');
    
    // Mostrar notificación inmediata informando que se cancelaron las notificaciones
    await showImmediateNotification(
      title: '🔄 Notificaciones Reprogramadas',
      body: 'Orden #${orden.id.substring(0, 8)} - Canceladas notificaciones anteriores',
      payload: 'cancel_info_${orden.id}',
    );
    
    // Luego programar nuevas notificaciones si la orden está en proceso
    if (orden.estado == 'en_proceso') {
      print('🔄 Programando nuevas notificaciones para orden ${orden.id}');
      await scheduleOrderNotifications(orden);
    } else {
      print('🔄 No se programan notificaciones - Estado: ${orden.estado}');
      await showImmediateNotification(
        title: '🔄 Notificaciones No Programadas',
        body: 'Orden #${orden.id.substring(0, 8)} - Estado: ${orden.estado}',
        payload: 'no_schedule_info_${orden.id}',
      );
    }
  }

  // Verificar si dos fechas son del mismo día
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Notificación inmediata (para pruebas o casos especiales)
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'immediate_channel',
      'Notificaciones Inmediatas',
      channelDescription: 'Notificaciones que se muestran inmediatamente',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF98CA3F),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Función de prueba para verificar que las notificaciones funcionan
  static Future<void> testNotification() async {
    await showImmediateNotification(
      title: '🧪 Prueba de Notificación',
      body: 'Si ves esto, el sistema de notificaciones funciona correctamente!',
      payload: 'test_notification',
    );
    print('🧪 Notificación de prueba enviada');
  }

  // Obtener notificaciones pendientes (para debugging)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

// Clase auxiliar para programar notificaciones
class NotificationSchedule {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String payload;

  NotificationSchedule({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.payload,
  });
}

// Callback para Workmanager (debe estar fuera de la clase)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'checkOrderDelivery':
        await _handleOrderDeliveryCheck(inputData);
        break;
    }
    return Future.value(true);
  });
}

// Función para verificar entregas en background
Future<void> _handleOrderDeliveryCheck(Map<String, dynamic>? inputData) async {
  if (inputData == null) return;

  final orderId = inputData['orderId'] as String;
  final clienteName = inputData['clienteName'] as String;
  final deliveryDate = DateTime.parse(inputData['deliveryDate'] as String);
  final deliveryHour = inputData['deliveryHour'] as int;
  final deliveryMinute = inputData['deliveryMinute'] as int;

  final deliveryDateTime = DateTime(
    deliveryDate.year,
    deliveryDate.month,
    deliveryDate.day,
    deliveryHour,
    deliveryMinute,
  );

  final now = DateTime.now();
  final timeUntilDelivery = deliveryDateTime.difference(now);

  // Si faltan menos de 5 minutos, mostrar notificación de urgencia
  if (timeUntilDelivery.inMinutes <= 5 && timeUntilDelivery.inMinutes > 0) {
    await NotificationService.showImmediateNotification(
      title: '¡Entrega URGENTE!',
      body: 'Orden #${orderId.substring(0, 8)} para $clienteName en ${timeUntilDelivery.inMinutes} minutos',
      payload: orderId,
    );
  }
}

// -------------------
// --- PDF GENERATOR ---
// -------------------

// Extensión para TimeOfDay que permite formatear sin BuildContext
extension TimeOfDayExtension on TimeOfDay {
  String formatTime(BuildContext? context) {
    if (context != null) {
      return MaterialLocalizations.of(context).formatTimeOfDay(this);
    }
    // Formato manual cuando no hay context disponible
    final hours = hour.toString().padLeft(2, '0');
    final minutes = minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

class PDFGenerator {
  static Future<Uint8List> generateOrdenTrabajo(OrdenTrabajo orden) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter, // Cambiado a tamaño carta
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              _buildHeader('ORDEN DE TRABAJO', boldFont, font),
              pw.SizedBox(height: 20),
              
              // Información de la orden
              _buildOrderInfo(orden, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Información del cliente
              _buildClientInfo(orden.cliente, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Tabla de trabajos
              _buildWorkTable(orden.trabajos, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Resumen financiero
              _buildFinancialSummary(orden, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Notas
              if (orden.notas != null && orden.notas!.isNotEmpty)
                _buildNotes(orden.notas!, font, boldFont),
              
              pw.Spacer(),
              
              // Pie de página
              _buildFooter(font),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  static Future<Uint8List> generateProforma(OrdenTrabajo orden) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter, // Cambiado a tamaño carta
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              _buildHeader('PROFORMA', boldFont, font),
              pw.SizedBox(height: 20),
              
              // Información de la proforma
              _buildProformaInfo(orden, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Información del cliente
              _buildClientInfo(orden.cliente, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Tabla de trabajos
              _buildWorkTable(orden.trabajos, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Resumen financiero
              _buildFinancialSummary(orden, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Términos y condiciones
              _buildTermsAndConditions(font, boldFont),
              
              pw.Spacer(),
              
              // Pie de página
              _buildFooter(font),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  static Future<Uint8List> generateNotaVenta(OrdenTrabajo orden) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter, // Cambiado a tamaño carta
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              _buildHeader('NOTA DE VENTA', boldFont, font),
              pw.SizedBox(height: 20),
              
              // Información de la nota de venta
              _buildNotaVentaInfo(orden, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Información del cliente
              _buildClientInfo(orden.cliente, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Tabla de trabajos
              _buildWorkTable(orden.trabajos, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Resumen financiero con pagos
              _buildFinancialSummaryWithPayments(orden, font, boldFont),
              pw.SizedBox(height: 20),
              
              // Información de entrega
              _buildDeliveryInfo(orden, font, boldFont),
              
              pw.Spacer(),
              
              // Pie de página
              _buildFooter(font),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  static pw.Widget _buildHeader(String title, pw.Font boldFont, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green300,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'COTIZADOR PRO',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 24,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 18,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildOrderInfo(OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');
    final timeFormat = DateFormat('HH:mm', 'es_ES');
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Orden N°:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('#${orden.id.substring(0, 8)}', style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Estado:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(orden.estado.toUpperCase(), style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Fecha de Creación:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(dateFormat.format(orden.creadoEn), style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Fecha de Entrega:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('${dateFormat.format(orden.fechaEntrega)} - ${_formatTimeOfDay(orden.horaEntrega)}', 
                        style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildProformaInfo(OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Proforma N°:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('PRO-${orden.id.substring(0, 8)}', style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Validez:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('30 días', style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Fecha:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(dateFormat.format(DateTime.now()), style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Tiempo de Entrega:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('${orden.fechaEntrega.difference(DateTime.now()).inDays} días', 
                        style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildNotaVentaInfo(OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Nota de Venta N°:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('NV-${orden.id.substring(0, 8)}', style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Estado:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(orden.estado.toUpperCase(), style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Fecha de Venta:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(dateFormat.format(DateTime.now()), style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Text('Método de Pago:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text(orden.adelanto > 0 ? 'Adelanto + Saldo' : 'Contado', 
                        style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildClientInfo(Cliente cliente, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INFORMACIÓN DEL CLIENTE', style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Nombre:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.Text(cliente.nombre, style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Contacto:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.Text(cliente.contacto, style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildWorkTable(List<OrdenTrabajoTrabajo> trabajos, pw.Font font, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Descripción', boldFont, isHeader: true),
            _buildTableCell('Ancho', boldFont, isHeader: true),
            _buildTableCell('Alto', boldFont, isHeader: true),
            _buildTableCell('Cant.', boldFont, isHeader: true),
            _buildTableCell('Precio/m²', boldFont, isHeader: true),
            _buildTableCell('Total', boldFont, isHeader: true),
          ],
        ),
        // Trabajos
        ...trabajos.map((trabajo) => pw.TableRow(
          children: [
            _buildTableCell(trabajo.trabajo.nombre, font),
            _buildTableCell('${trabajo.ancho}m', font),
            _buildTableCell('${trabajo.alto}m', font),
            _buildTableCell('${trabajo.cantidad}', font),
            _buildTableCell('Bs ${trabajo.trabajo.precioM2.toStringAsFixed(2)}', font),
            _buildTableCell('Bs ${trabajo.precioFinal.toStringAsFixed(2)}', font),
          ],
        )),
      ],
    );
  }
  
  static pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
  
  static pw.Widget _buildFinancialSummary(OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RESUMEN FINANCIERO', style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          _buildFinancialRow('Subtotal:', 'Bs ${orden.totalBruto.toStringAsFixed(2)}', font, boldFont),
          if (orden.rebaja > 0)
            _buildFinancialRow('Rebaja:', '-Bs ${orden.rebaja.toStringAsFixed(2)}', font, boldFont),
          pw.Divider(color: PdfColors.grey400),
          _buildFinancialRow('TOTAL:', 'Bs ${orden.total.toStringAsFixed(2)}', font, boldFont, isTotal: true),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFinancialSummaryWithPayments(OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RESUMEN FINANCIERO', style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          _buildFinancialRow('Subtotal:', 'Bs ${orden.totalBruto.toStringAsFixed(2)}', font, boldFont),
          if (orden.rebaja > 0)
            _buildFinancialRow('Rebaja:', '-Bs ${orden.rebaja.toStringAsFixed(2)}', font, boldFont),
          pw.Divider(color: PdfColors.grey400),
          _buildFinancialRow('TOTAL:', 'Bs ${orden.total.toStringAsFixed(2)}', font, boldFont, isTotal: true),
          if (orden.adelanto > 0) ...[
            pw.SizedBox(height: 8),
            _buildFinancialRow('Adelanto:', 'Bs ${orden.adelanto.toStringAsFixed(2)}', font, boldFont),
            _buildFinancialRow('Saldo Pendiente:', 'Bs ${orden.saldo.toStringAsFixed(2)}', font, boldFont),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _buildFinancialRow(String label, String value, pw.Font font, pw.Font boldFont, {bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: isTotal ? boldFont : font, fontSize: isTotal ? 14 : 12)),
        pw.Text(value, style: pw.TextStyle(font: isTotal ? boldFont : font, fontSize: isTotal ? 14 : 12)),
      ],
    );
  }
  
  static pw.Widget _buildNotes(String notes, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('NOTAS', style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Text(notes, style: pw.TextStyle(font: font, fontSize: 12)),
        ],
      ),
    );
  }
  
  static pw.Widget _buildTermsAndConditions(pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TÉRMINOS Y CONDICIONES', style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Text('• Esta proforma tiene validez de 30 días.', style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('• Los precios incluyen diseño y material.', style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('• Se requiere 50% de adelanto para iniciar el trabajo.', style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('• El tiempo de entrega es estimado y puede variar.', style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text('• No incluye instalación salvo especificación contraria.', style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }
  
  static pw.Widget _buildDeliveryInfo(OrdenTrabajo orden, pw.Font font, pw.Font boldFont) {
    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INFORMACIÓN DE ENTREGA', style: pw.TextStyle(font: boldFont, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Fecha de Entrega:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.Text(dateFormat.format(orden.fechaEntrega), style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Hora de Entrega:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.Text(_formatTimeOfDay(orden.horaEntrega), style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('COTIZADOR PRO - Sistema de Gestión de Gigantografías', 
                  style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(          'Generado el ${DateFormat('d/M/yyyy HH:mm', 'es_ES').format(DateTime.now())}', 
                  style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }
  
  // Función auxiliar para formatear TimeOfDay
  static String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

// -------------------
// --- HIVE DATA MODELS ---
// -------------------

// Interface for items that can be soft-deleted.
abstract class SoftDeletable {
  DateTime? eliminadoEn;
}

@HiveType(typeId: 1)
class Trabajo extends HiveObject implements SoftDeletable {
  @HiveField(0)
  String id;
  @HiveField(1)
  String nombre;
  @HiveField(2)
  double precioM2;
  @HiveField(3)
  String negocioId;
  @HiveField(4)
  DateTime creadoEn;
  @HiveField(5)
  @override
  DateTime? eliminadoEn;

  Trabajo({
    required this.id,
    required this.nombre,
    required this.precioM2,
    required this.negocioId,
    required this.creadoEn,
    this.eliminadoEn,
  });

  double calcularPrecio(double ancho, double alto, int cantidad, double adicional) {
    final area = ancho * alto;
    final precioBase = area * precioM2 * cantidad;
    return precioBase + adicional;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trabajo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 2)
class Cliente extends HiveObject implements SoftDeletable {
  @HiveField(0)
  String id;
  @HiveField(1)
  String nombre;
  @HiveField(2)
  String contacto;
  @HiveField(3)
  String negocioId;
  @HiveField(4)
  DateTime creadoEn;
  @HiveField(5)
  @override
  DateTime? eliminadoEn;

  Cliente({
    required this.id,
    required this.nombre,
    required this.contacto,
    required this.negocioId,
    required this.creadoEn,
    this.eliminadoEn,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cliente && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 3)
class Usuario extends HiveObject implements SoftDeletable {
  @HiveField(0)
  String id;
  @HiveField(1)
  String email;
  @HiveField(2)
  String nombre;
  @HiveField(3)
  String rol; // 'admin' or 'empleado'
  @HiveField(4)
  String negocioId;
  @HiveField(5)
  DateTime creadoEn;
  @HiveField(6)
  @override
  DateTime? eliminadoEn;
  @HiveField(7)
  String password; // For local auth

  Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.negocioId,
    required this.creadoEn,
    required this.password,
    this.eliminadoEn,
  });
}

@HiveType(typeId: 4)
class OrdenTrabajoTrabajo extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  Trabajo trabajo;
  @HiveField(2)
  double ancho;
  @HiveField(3)
  double alto;
  @HiveField(4)
  int cantidad;
  @HiveField(5)
  double adicional;
  
  double get precioFinal =>
      (ancho * alto * trabajo.precioM2 * cantidad) + adicional;

  OrdenTrabajoTrabajo({
    required this.id,
    required this.trabajo,
    this.ancho = 1.0,
    this.alto = 1.0,
    this.cantidad = 1,
    this.adicional = 0.0,
  });
}

@HiveType(typeId: 5)
class OrdenHistorial extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String cambio;
  @HiveField(2)
  final String usuarioId;
  @HiveField(3)
  final String usuarioNombre;
  @HiveField(4)
  final DateTime timestamp;
  @HiveField(5)
  final String? dispositivo;
  @HiveField(6)
  final String? ip;

  OrdenHistorial({
    required this.id,
    required this.cambio,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.timestamp,
    this.dispositivo,
    this.ip,
  });
}

@HiveType(typeId: 6)
class OrdenTrabajo extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  Cliente cliente;
  @HiveField(2)
  List<OrdenTrabajoTrabajo> trabajos;
  @HiveField(3)
  List<OrdenHistorial> historial;
  @HiveField(4)
  double adelanto;
  @HiveField(5)
  double? totalPersonalizado;
  @HiveField(6)
  String? notas;
  @HiveField(7)
  String estado;
  @HiveField(8)
  DateTime fechaEntrega;
  @HiveField(9)
  TimeOfDay horaEntrega;
  @HiveField(10)
  DateTime creadoEn;
  @HiveField(11)
  String creadoPorUsuarioId;
  @HiveField(12)
  List<ArchivoAdjunto> archivos;

  double get totalBruto => trabajos.fold(0.0, (prev, item) => prev + item.precioFinal);
  
  double get rebaja {
    if (totalPersonalizado != null && totalPersonalizado! < totalBruto) {
      return totalBruto - totalPersonalizado!;
    }
    return 0.0;
  }

  double get total {
    if (totalPersonalizado != null) {
      return totalPersonalizado!;
    }
    return totalBruto;
  }
  
  double get saldo => total - adelanto;

  OrdenTrabajo({
    required this.id,
    required this.cliente,
    required this.trabajos,
    required this.historial,
    this.adelanto = 0.0,
    this.totalPersonalizado,
    this.notas,
    this.estado = 'pendiente',
    required this.fechaEntrega,
    required this.horaEntrega,
    required this.creadoEn,
    required this.creadoPorUsuarioId,
    List<ArchivoAdjunto>? archivos,
  }) : archivos = archivos ?? [];
}

@HiveType(typeId: 7)
class ArchivoAdjunto extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String nombre;
  @HiveField(2)
  String rutaArchivo;
  @HiveField(3)
  String tipoMime;
  @HiveField(4)
  int tamano;
  @HiveField(5)
  DateTime fechaSubida;
  @HiveField(6)
  String subidoPorUsuarioId;
  @HiveField(7)
  String subidoPorUsuarioNombre;
  @HiveField(8)
  String? descripcion;

  ArchivoAdjunto({
    required this.id,
    required this.nombre,
    required this.rutaArchivo,
    required this.tipoMime,
    required this.tamano,
    required this.fechaSubida,
    required this.subidoPorUsuarioId,
    required this.subidoPorUsuarioNombre,
    this.descripcion,
  });

  // Método para obtener el tamaño formateado
  String get tamanoFormateado {
    if (tamano < 1024) {
      return '$tamano B';
    } else if (tamano < 1024 * 1024) {
      return '${(tamano / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(tamano / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Método para obtener el tipo de archivo
  String get tipoArchivo {
    if (tipoMime.startsWith('image/')) {
      return 'Imagen';
    } else if (tipoMime.startsWith('video/')) {
      return 'Video';
    } else if (tipoMime.startsWith('audio/')) {
      return 'Audio';
    } else if (tipoMime.contains('pdf')) {
      return 'PDF';
    } else if (tipoMime.contains('word') || tipoMime.contains('document')) {
      return 'Documento';
    } else if (tipoMime.contains('excel') || tipoMime.contains('spreadsheet')) {
      return 'Hoja de cálculo';
    } else if (tipoMime.contains('presentation')) {
      return 'Presentación';
    } else if (tipoMime.startsWith('text/')) {
      return 'Texto';
    } else {
      return 'Archivo';
    }
  }

  // Método para obtener el icono según el tipo
  IconData get icono {
    if (tipoMime.startsWith('image/')) {
      return Icons.image_rounded;
    } else if (tipoMime.startsWith('video/')) {
      return Icons.video_file_rounded;
    } else if (tipoMime.startsWith('audio/')) {
      return Icons.audio_file_rounded;
    } else if (tipoMime.contains('pdf')) {
      return Icons.picture_as_pdf_rounded;
    } else if (tipoMime.contains('word') || tipoMime.contains('document')) {
      return Icons.description_rounded;
    } else if (tipoMime.contains('excel') || tipoMime.contains('spreadsheet')) {
      return Icons.table_chart_rounded;
    } else if (tipoMime.contains('presentation')) {
      return Icons.present_to_all_rounded;
    } else if (tipoMime.startsWith('text/')) {
      return Icons.text_snippet_rounded;
    } else {
      return Icons.attach_file_rounded;
    }
  }

  // Método para verificar si el archivo existe
  Future<bool> exists() async {
    return await File(rutaArchivo).exists();
  }
}

// *** FIX: Added custom TimeOfDayAdapter ***
@HiveType(typeId: 100)
class TimeOfDayAdapter extends TypeAdapter<TimeOfDay> {
  @override
  final int typeId = 100;

  @override
  TimeOfDay read(BinaryReader reader) {
    final hour = reader.readByte();
    final minute = reader.readByte();
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void write(BinaryWriter writer, TimeOfDay obj) {
    writer.writeByte(obj.hour);
    writer.writeByte(obj.minute);
  }
}


// -------------------
// --- STATE MANAGEMENT (PROVIDER) WITH HIVE ---
// -------------------

class AppState extends ChangeNotifier {
  Usuario? _currentUser;
  Usuario? get currentUser => _currentUser;

  // Hive boxes references
  late Box<Cliente> _clientesBox;
  late Box<Trabajo> _trabajosBox;
  late Box<OrdenTrabajo> _ordenesBox;
  late Box<Usuario> _usuariosBox;
  
  // SharedPreferences para configuraciones
  late SharedPreferences _prefs;

  // Configuración de notificaciones
  bool _notificationsEnabled = true;
  
  bool get notificationsEnabled => _notificationsEnabled;
  
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
    _saveNotificationSettings();
  }

  Future<void> _saveNotificationSettings() async {
    await _prefs.setBool('notifications_enabled', _notificationsEnabled);
  }

  Future<void> _loadNotificationSettings() async {
    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
  }

  AppState() {
    // Initialization is now async and happens in main()
  }

  Future<void> init() async {
    // Inicializar SharedPreferences
    _prefs = await SharedPreferences.getInstance();
    
    _clientesBox = Hive.box<Cliente>('clientes');
    _trabajosBox = Hive.box<Trabajo>('trabajos');
    _ordenesBox = Hive.box<OrdenTrabajo>('ordenes');
    _usuariosBox = Hive.box<Usuario>('usuarios');
    
    // Cargar configuraciones
    await _loadNotificationSettings();
    
    // Inicializar servicio de notificaciones
    await NotificationService.initialize();
    
    await _createDefaultAdminUser();
    notifyListeners();
  }

  Future<void> _createDefaultAdminUser() async {
    if (_usuariosBox.isEmpty) {
      final adminUser = Usuario(
        id: 'admin_user',
        email: 'admin',
        password: 'admin', // In a real app, this should be hashed
        nombre: 'Administrador',
        rol: 'admin',
        negocioId: 'default_negocio',
        creadoEn: DateTime.now(),
      );
      await _usuariosBox.put(adminUser.id, adminUser);
    }
  }

  Future<bool> login(String email, String password) async {
    final user = _usuariosBox.values.firstWhere(
      (u) => u.email == email && u.eliminadoEn == null,
      orElse: () => Usuario(id: '', email: '', nombre: '', rol: '', negocioId: '', creadoEn: DateTime.now(), password: ''), // Return a dummy user
    );

    if (user.id.isNotEmpty && user.password == password) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // --- Getters now read from Hive boxes ---
  List<Cliente> get clientes => _clientesBox.values.where((c) => c.eliminadoEn == null).toList();
  List<Cliente> get clientesArchivados => _clientesBox.values.where((c) => c.eliminadoEn != null).toList();
  List<Trabajo> get trabajos => _trabajosBox.values.where((t) => t.eliminadoEn == null).toList();
  List<Trabajo> get trabajosArchivados => _trabajosBox.values.where((t) => t.eliminadoEn != null).toList();
  List<OrdenTrabajo> get ordenes => _ordenesBox.values.toList()..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  List<Usuario> get usuarios => _usuariosBox.values.where((u) => u.eliminadoEn == null).toList();
  List<Usuario> get usuariosArchivados => _usuariosBox.values.where((u) => u.eliminadoEn != null).toList();

  // --- CRUD methods now write to Hive boxes ---
  Future<void> addOrden(OrdenTrabajo orden) async {
    await _ordenesBox.put(orden.id, orden);
    
    // Programar notificaciones si está habilitado
    if (_notificationsEnabled) {
      await NotificationService.scheduleOrderNotifications(orden);
    }
    
    notifyListeners();
  }
  
  Future<void> updateOrden(OrdenTrabajo orden, String cambio) async {
    print('🔄 updateOrden: Iniciando actualización para orden ${orden.id}');
    print('🔄 Cambio: $cambio');
    
    // Obtener la orden actual para comparar cambios
    final ordenActual = _ordenesBox.get(orden.id);
    
    orden.historial.add(OrdenHistorial(
      id: Random().nextDouble().toString(),
      cambio: cambio,
      usuarioId: _currentUser!.id,
      usuarioNombre: _currentUser!.nombre,
      timestamp: DateTime.now(),
    ));
    
    // Ensure the order is saved to Hive
    await _ordenesBox.put(orden.id, orden);
    
    // Verificar si cambió el estado, fecha o hora
    final estadoCambio = ordenActual != null && ordenActual.estado != orden.estado;
    final fechaCambio = ordenActual != null && (
      ordenActual.fechaEntrega != orden.fechaEntrega ||
      ordenActual.horaEntrega.hour != orden.horaEntrega.hour ||
      ordenActual.horaEntrega.minute != orden.horaEntrega.minute
    );
    
    print('🔄 Estado cambió: $estadoCambio');
    print('🔄 Fecha/hora cambió: $fechaCambio');
    print('🔄 Notificaciones habilitadas: $_notificationsEnabled');
    
    // Reprogramar notificaciones si está habilitado y cambió el estado, fecha o hora
    if (_notificationsEnabled && (estadoCambio || fechaCambio)) {
      print('🔄 Reprogramando notificaciones...');
      await NotificationService.updateOrderNotifications(orden);
      
      // Si cambió fecha u hora, mostrar notificación informativa
      if (fechaCambio && orden.estado == 'en_proceso') {
        final fechaStr = _formatDate(orden.fechaEntrega);
        final horaStr = _formatTimeOfDay(orden.horaEntrega);
        
        print('🔄 Mostrando notificación informativa de cambio de fecha/hora');
        await NotificationService.showImmediateNotification(
          title: 'Fecha de entrega actualizada',
          body: 'Orden #${orden.id.substring(0, 8)} - Nueva fecha: $fechaStr a las $horaStr',
          payload: orden.id,
        );
      }
      
      // Mostrar notificación inmediata para cambios importantes de estado
      if (estadoCambio && orden.estado == 'terminado') {
        await NotificationService.showImmediateNotification(
          title: 'Orden terminada',
          body: 'Orden #${orden.id.substring(0, 8)} para ${orden.cliente.nombre} está lista para entrega',
          payload: orden.id,
        );
      }
      
      // Mostrar notificación cuando se pone en proceso
      if (estadoCambio && orden.estado == 'en_proceso') {
        await NotificationService.showImmediateNotification(
          title: 'Orden en proceso',
          body: 'Orden #${orden.id.substring(0, 8)} para ${orden.cliente.nombre} está ahora en proceso',
          payload: orden.id,
        );
      }
    } else {
      print('🔄 No se reprograman notificaciones - Condiciones no cumplidas');
    }
    
    notifyListeners();
    print('🔄 updateOrden: Actualización completada');
  }

  // Método auxiliar para formatear fechas
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Método auxiliar para formatear horas
  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<void> addArchivosAOrden(OrdenTrabajo orden, List<ArchivoAdjunto> archivos) async {
    orden.archivos.addAll(archivos);
    await updateOrden(orden, 'Se agregaron ${archivos.length} archivo(s) adjunto(s)');
  }

  Future<void> removeArchivoDeOrden(OrdenTrabajo orden, ArchivoAdjunto archivo) async {
    orden.archivos.removeWhere((a) => a.id == archivo.id);
    await ArchivoService.eliminarArchivo(archivo);
    await updateOrden(orden, 'Se eliminó el archivo adjunto: ${archivo.nombre}');
  }
  
  Future<void> addTrabajo(Trabajo trabajo) async {
    await _trabajosBox.put(trabajo.id, trabajo);
    notifyListeners();
  }
  
  Future<void> updateTrabajo(Trabajo trabajo) async {
    await trabajo.save();
    notifyListeners();
  }

  Future<void> deleteTrabajo(Trabajo trabajo) async {
    trabajo.eliminadoEn = DateTime.now();
    await trabajo.save();
    notifyListeners();
  }
  
  Future<void> restoreTrabajo(Trabajo trabajo) async {
    trabajo.eliminadoEn = null;
    await trabajo.save();
    notifyListeners();
  }

  Future<void> addCliente(Cliente cliente) async {
    await _clientesBox.put(cliente.id, cliente);
    notifyListeners();
  }
  
  Future<void> updateCliente(Cliente cliente) async {
    await cliente.save();
    notifyListeners();
  }

  Future<void> deleteCliente(Cliente cliente) async {
    cliente.eliminadoEn = DateTime.now();
    await cliente.save();
    notifyListeners();
  }

  Future<void> restoreCliente(Cliente cliente) async {
    cliente.eliminadoEn = null;
    await cliente.save();
    notifyListeners();
  }
  
  Future<void> addUsuario(Usuario usuario) async {
    await _usuariosBox.put(usuario.id, usuario);
    notifyListeners();
  }
  
  Future<void> updateUsuario(Usuario usuario) async {
    await usuario.save();
    notifyListeners();
  }

  Future<void> deleteUsuario(Usuario usuario) async {
    if (usuario.id == _currentUser?.id) return; 
    usuario.eliminadoEn = DateTime.now();
    await usuario.save();
    notifyListeners();
  }
  
  Future<void> restoreUsuario(Usuario usuario) async {
    usuario.eliminadoEn = null;
    await usuario.save();
    notifyListeners();
  }
}

// -------------------
// --- APP ENTRY POINT ---
// -------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar datos de localización para español
  await initializeDateFormatting('es_ES', null);
  
  await Hive.initFlutter();

  // Registering Hive Adapters
  Hive.registerAdapter(TrabajoAdapter());
  Hive.registerAdapter(ClienteAdapter());
  Hive.registerAdapter(UsuarioAdapter());
  Hive.registerAdapter(OrdenTrabajoTrabajoAdapter());
  Hive.registerAdapter(OrdenHistorialAdapter());
  Hive.registerAdapter(OrdenTrabajoAdapter());
  Hive.registerAdapter(ArchivoAdjuntoAdapter());
  Hive.registerAdapter(TimeOfDayAdapter()); // *** FIX: Now this adapter is defined ***

  // Opening Hive Boxes
  await Hive.openBox<Trabajo>('trabajos');
  await Hive.openBox<Cliente>('clientes');
  await Hive.openBox<Usuario>('usuarios');
  await Hive.openBox<OrdenTrabajo>('ordenes');
  
  final appState = AppState();
  await appState.init(); // Initialize state after boxes are open

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const CotizadorApp(),
    ),
  );
}

class CotizadorApp extends StatelessWidget {
  const CotizadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cotizador Pro',
      theme: _buildTheme(),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      // Configuración de localización
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
      ],
      locale: const Locale('es', 'ES'),
    );
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF98CA3F); // Verde Platzi
    const backgroundColor = Color(0xFFFAFAFA); // Fondo claro
    const surfaceColor = Color(0xFFFFFFFF); // Blanco
    const cardColor = Color(0xFFFFFFFF); // Cards blancos
    const textColor = Color(0xFF1A1D29); // Texto oscuro
    const subtitleColor = Color(0xFF6B7280); // Gris subtítulos
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        onBackground: textColor,
      ),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        shadowColor: Colors.black12,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: subtitleColor),
        hintStyle: const TextStyle(color: subtitleColor),
      ),
      
      // Drawer theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      
      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        labelStyle: const TextStyle(color: textColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF9CA3AF),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF3F4F6),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

// -------------------
// --- IMAGE VIEWER ---
// -------------------

class ImageViewer extends StatefulWidget {
  final List<ArchivoAdjunto> imagenes;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.imagenes,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} de ${widget.imagenes.length}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.open_in_new,
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
            onPressed: () => _abrirEnAplicacionExterna(),
            tooltip: 'Abrir con app externa',
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
            onPressed: () => _mostrarInfo(),
            tooltip: 'Información',
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.imagenes.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(widget.imagenes[index].rutaArchivo)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * (isMobile ? 2.5 : 3),
                heroAttributes: PhotoViewHeroAttributes(tag: widget.imagenes[index].id),
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: isMobile ? 48 : 64,
                            color: Colors.white54,
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          Text(
                            'Error al cargar la imagen',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) {
              if (event == null) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: isMobile ? 2 : 4,
                  ),
                );
              }
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: isMobile ? 2 : 4,
                  value: event.expectedTotalBytes != null
                      ? event.cumulativeBytesLoaded / event.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
          // Controles de navegación
          if (widget.imagenes.length > 1)
            Positioned(
              bottom: isMobile ? 60 : 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: isMobile ? 18 : 24,
                          ),
                          onPressed: _currentIndex > 0
                              ? () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                        Text(
                          '${_currentIndex + 1} / ${widget.imagenes.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: isMobile ? 18 : 24,
                          ),
                          onPressed: _currentIndex < widget.imagenes.length - 1
                              ? () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 6.0 : 8.0,
          horizontal: isMobile ? 12.0 : 16.0,
        ),
        child: SafeArea(
          child: Text(
            widget.imagenes[_currentIndex].nombre,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 14 : 16,
            ),
            textAlign: TextAlign.center,
            maxLines: isMobile ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _abrirEnAplicacionExterna() async {
    try {
      await ArchivoService.abrirArchivo(widget.imagenes[_currentIndex]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir archivo: $e')),
      );
    }
  }

  void _mostrarInfo() {
    final archivo = widget.imagenes[_currentIndex];
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Información del archivo',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Nombre:', archivo.nombre),
              _buildInfoRow('Tipo:', archivo.tipoArchivo),
              _buildInfoRow('Tamaño:', archivo.tamanoFormateado),
              _buildInfoRow('Subido por:', archivo.subidoPorUsuarioNombre),
              _buildInfoRow('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(archivo.fechaSubida)),
              if (archivo.descripcion != null)
                _buildInfoRow('Descripción:', archivo.descripcion!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 6.0 : 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 80 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------
// --- ARCHIVO WIDGETS ---
// -------------------

class ArchivosAdjuntosWidget extends StatefulWidget {
  final OrdenTrabajo orden;
  final bool isReadOnly;

  const ArchivosAdjuntosWidget({
    super.key,
    required this.orden,
       this.isReadOnly = false,
  });

  @override
  State<ArchivosAdjuntosWidget> createState() => _ArchivosAdjuntosWidgetState();
}

class _ArchivosAdjuntosWidgetState extends State<ArchivosAdjuntosWidget> {
  bool _isLoading = false;

  Future<void> _adjuntarArchivos() async {
    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = appState.currentUser!;
      
      final archivos = await ArchivoService.seleccionarArchivos(
        user.id,
        user.nombre,
      );

      if (archivos.isNotEmpty) {
        await appState.addArchivosAOrden(widget.orden, archivos);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Se agregaron ${archivos.length} archivo(s) adjunto(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al adjuntar archivos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminarArchivo(ArchivoAdjunto archivo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de que desea eliminar el archivo "${archivo.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.removeArchivoDeOrden(widget.orden, archivo);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Archivo eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar archivo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _abrirArchivo(ArchivoAdjunto archivo) async {
    try {
      if (archivo.tipoMime.startsWith('image/')) {
        // Para imágenes, abrir el visor de galería
        final imagenes = widget.orden.archivos
            .where((a) => a.tipoMime.startsWith('image/'))
            .toList();
        final initialIndex = imagenes.indexOf(archivo);
        
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ImageViewer(
                imagenes: imagenes,
                initialIndex: initialIndex >= 0 ? initialIndex : 0,
              ),
            ),
          );
        }
      } else {
        // Para otros tipos de archivos, abrir con aplicación externa
        final success = await ArchivoService.abrirArchivo(archivo);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el archivo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDetallesArchivo(ArchivoAdjunto archivo) async {
    final existeArchivo = await archivo.exists();
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(archivo.icono, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  archivo.nombre,
                  style: TextStyle(fontSize: isMobile ? 16 : 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetalleRow('Tipo:', archivo.tipoArchivo),
                _buildDetalleRow('Tamaño:', archivo.tamanoFormateado),
                _buildDetalleRow('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(archivo.fechaSubida)),
                _buildDetalleRow('Subido por:', archivo.subidoPorUsuarioNombre),
                _buildDetalleRow('Estado:', existeArchivo ? 'Disponible' : 'Archivo no encontrado'),
                if (archivo.descripcion != null && archivo.descripcion!.isNotEmpty)
                  _buildDetalleRow('Descripción:', archivo.descripcion!),
              ],
            ),
          ),
          actions: [
            if (existeArchivo)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _abrirArchivo(archivo);
                },
                icon: Icon(Icons.open_in_new, size: isMobile ? 16 : 20),
                label: Text(
                  'Abrir',
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getFileTypeColor(String tipoMime) {
    if (tipoMime.startsWith('image/')) {
      return Colors.purple;
    } else if (tipoMime.startsWith('video/')) {
      return Colors.red;
    } else if (tipoMime.startsWith('audio/')) {
      return Colors.orange;
    } else if (tipoMime.contains('pdf')) {
      return Colors.red.shade700;
    } else if (tipoMime.contains('word') || tipoMime.contains('document')) {
      return Colors.blue;
    } else if (tipoMime.contains('excel') || tipoMime.contains('spreadsheet')) {
      return Colors.green;
    } else if (tipoMime.contains('presentation')) {
      return Colors.orange.shade700;
    } else if (tipoMime.startsWith('text/')) {
      return Colors.grey.shade700;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildDetalleRow(String label, String value) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 6.0 : 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 80 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Archivos Adjuntos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 18 : null,
                    ),
                  ),
                ),
                if (!widget.isReadOnly)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _adjuntarArchivos,
                    icon: _isLoading 
                      ? SizedBox(
                          width: isMobile ? 14 : 16,
                          height: isMobile ? 14 : 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.attach_file_rounded, size: isMobile ? 16 : 20),
                    label: Text(isMobile ? 'Adjuntar' : 'Adjuntar'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 8,
                      ),
                      textStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            
            if (widget.orden.archivos.isEmpty)
              Container(
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: isMobile ? 48 : 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'No hay archivos adjuntos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isMobile ? 14 : null,
                      ),
                    ),
                    if (!widget.isReadOnly) ...[
                      SizedBox(height: isMobile ? 6 : 8),
                      Text(
                        'Haga clic en "Adjuntar" para agregar archivos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 12 : null,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Column(
                children: widget.orden.archivos.map((archivo) {
                  return Container(
                    margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: isMobile ? 4 : 8,
                      ),
                      leading: archivo.tipoMime.startsWith('image/') 
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: isMobile ? 40 : 50,
                                height: isMobile ? 40 : 50,
                                child: Image.file(
                                  File(archivo.rutaArchivo),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      child: Icon(
                                        archivo.icono,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: isMobile ? 18 : 24,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                          : CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              radius: isMobile ? 20 : 25,
                              child: Icon(
                                archivo.icono,
                                color: Theme.of(context).colorScheme.primary,
                                size: isMobile ? 18 : 24,
                              ),
                            ),
                      title: Text(
                        archivo.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 13 : 14,
                        ),
                        maxLines: isMobile ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isMobile ? 2 : 4),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 6 : 8,
                                  vertical: isMobile ? 1 : 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getFileTypeColor(archivo.tipoMime).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  archivo.tipoArchivo,
                                  style: TextStyle(
                                    color: _getFileTypeColor(archivo.tipoMime),
                                    fontSize: isMobile ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: isMobile ? 4 : 8),
                              Text(
                                archivo.tamanoFormateado,
                                style: TextStyle(fontSize: isMobile ? 11 : 12),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 1 : 2),
                          Text(
                            'Subido por ${archivo.subidoPorUsuarioNombre} • ${DateFormat('dd/MM/yyyy HH:mm').format(archivo.fechaSubida)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: isMobile
                          ? PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, size: 18),
                              onSelected: (value) {
                                switch (value) {
                                  case 'open':
                                    _abrirArchivo(archivo);
                                    break;
                                  case 'info':
                                    _mostrarDetallesArchivo(archivo);
                                    break;
                                  case 'delete':
                                    if (!widget.isReadOnly) {
                                      _eliminarArchivo(archivo);
                                    }
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'open',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility_rounded, size: 16),
                                      SizedBox(width: 8),
                                      Text('Abrir'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'info',
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 16),
                                      SizedBox(width: 8),
                                      Text('Detalles'),
                                    ],
                                  ),
                                ),
                                if (!widget.isReadOnly)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_rounded),
                                  onPressed: () => _abrirArchivo(archivo),
                                  tooltip: 'Abrir archivo',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.info_outline_rounded),
                                  onPressed: () => _mostrarDetallesArchivo(archivo),
                                  tooltip: 'Ver detalles',
                                ),
                                if (!widget.isReadOnly)
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                    onPressed: () => _eliminarArchivo(archivo),
                                    tooltip: 'Eliminar',
                                  ),
                              ],
                            ),
                      onTap: () => _abrirArchivo(archivo),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// -------------------
// --- WRAPPERS AND MAIN SCREENS ---
// -------------------

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (appState.currentUser != null) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}


class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _testMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Notificaciones'),
        backgroundColor: const Color(0xFF98CA3F),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activar/Desactivar notificaciones
                Card(
                  child: SwitchListTile(
                    title: const Text('Activar Notificaciones'),
                    subtitle: const Text('Recibir notificaciones de entregas pendientes'),
                    value: appState.notificationsEnabled,
                    onChanged: (bool value) {
                      appState.setNotificationsEnabled(value);
                      if (!value) {
                        // Cancelar todas las notificaciones si se desactiva
                        NotificationService.cancelAllNotifications();
                      } else {
                        // Reprogramar notificaciones para órdenes en proceso
                        _reprogramarNotificaciones();
                      }
                    },
                    activeColor: const Color(0xFF98CA3F),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Información sobre el funcionamiento
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cómo funcionan las notificaciones',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          Icons.today,
                          'Entregas de hoy',
                          '15 minutos antes de la hora de entrega',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          Icons.event,
                          'Entregas futuras',
                          '2 horas y 1 hora antes de la entrega',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          Icons.work,
                          'Solo órdenes en proceso',
                          'Solo se notifican órdenes con estado "En Proceso"',
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Notificaciones pendientes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notificaciones Programadas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<PendingNotificationRequest>>(
                          future: NotificationService.getPendingNotifications(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('No hay notificaciones programadas');
                            }
                            
                            return Column(
                              children: snapshot.data!.map((notification) {
                                return ListTile(
                                  leading: const Icon(Icons.notifications),
                                  title: Text(notification.title ?? 'Sin título'),
                                  subtitle: Text(notification.body ?? 'Sin descripción'),
                                  trailing: Text('ID: ${notification.id}'),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Sección de pruebas
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pruebas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _testNotification(),
                                icon: const Icon(Icons.notification_add),
                                label: const Text('Notificación de Prueba'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF98CA3F),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _reprogramarNotificaciones(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reprogramar Todas'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _cancelarTodas(),
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancelar Todas'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF98CA3F)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _testNotification() {
    NotificationService.showImmediateNotification(
      title: 'Notificación de Prueba',
      body: 'Esta es una notificación de prueba del sistema de cotización',
      payload: 'test_notification',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificación de prueba enviada')),
    );
  }

  void _reprogramarNotificaciones() {
    final appState = Provider.of<AppState>(context, listen: false);
    final ordenesEnProceso = appState.ordenes.where((o) => o.estado == 'en_proceso').toList();
    
    for (final orden in ordenesEnProceso) {
      NotificationService.scheduleOrderNotifications(orden);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reprogramadas ${ordenesEnProceso.length} notificaciones')),
    );
    
    setState(() {}); // Refrescar lista de notificaciones pendientes
  }

  void _cancelarTodas() {
    NotificationService.cancelAllNotifications();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todas las notificaciones canceladas')),
    );
    
    setState(() {}); // Refrescar lista de notificaciones pendientes
  }
}


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final success = await Provider.of<AppState>(context, listen: false)
        .login(_emailController.text, _passwordController.text);
    
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos.')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo y título
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF98CA3F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.print_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cotizador Pro',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1D29),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestión profesional de gigantografías',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Formulario de login
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person_rounded),
                            hintText: 'Ingresa tu usuario',
                          ),
                          keyboardType: TextInputType.text,
                        ),
                        FormSpacing.verticalLarge(),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_rounded),
                            hintText: 'Ingresa tu contraseña',
                          ),
                          obscureText: true,
                        ),
                        FormSpacing.verticalExtraLarge(),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 56),
                                ),
                                onPressed: _login,
                                child: const Text('Iniciar Sesión'),
                              ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                // Información de demo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Credenciales de demo',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Usuario: admin\nContraseña: admin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const CotizarScreen(),
    const OrdenesTrabajoScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppState>(context).currentUser;
    final bool isAdmin = user?.rol == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Nueva Cotización' : 'Órdenes de Trabajo'),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          // Botón de prueba de notificaciones
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFF98CA3F)),
            onPressed: () async {
              await NotificationService.testNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📧 Notificación de prueba enviada'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Probar notificación',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF98CA3F),
              child: Text(
                user?.nombre.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, user, isAdmin),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_business_rounded),
            label: 'Cotizar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'Órdenes',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, Usuario? user, bool isAdmin) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Color(0xFF98CA3F),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.nombre.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Color(0xFF98CA3F),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.nombre ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? 'email@test.com',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user?.rol.toUpperCase() ?? 'EMPLEADO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                if (isAdmin)
                  _buildDrawerItem(
                    icon: Icons.work_rounded,
                    title: 'Gestión de Trabajos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionTrabajosScreen()));
                    },
                  ),
                _buildDrawerItem(
                  icon: Icons.people_rounded,
                  title: 'Clientes',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionClientesScreen()));
                  },
                ),
                if (isAdmin)
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Usuarios',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionUsuariosScreen()));
                    },
                  ),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Configuración',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implementar configuración
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications,
                  title: 'Notificaciones',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_rounded,
                  title: 'Ayuda',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implementar ayuda
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar Sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Provider.of<AppState>(context, listen: false).logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B7280)),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class CotizarScreen extends StatefulWidget {
  const CotizarScreen({super.key});

  @override
  _CotizarScreenState createState() => _CotizarScreenState();
}

class _CotizarScreenState extends State<CotizarScreen> {
  final _formKey = GlobalKey<FormState>();
  List<OrdenTrabajoTrabajo> _trabajosEnOrden = [];
  Trabajo? _trabajoSeleccionado;
  Cliente? _clienteSeleccionado;
  double _ancho = 1.0;
  double _alto = 1.0;
  int _cantidad = 1;
  double _adicional = 0.0;
  
  // Controllers are the single source of truth for TextFields
  late TextEditingController _totalPersonalizadoController;
  late TextEditingController _adelantoController;
  late TextEditingController _notasController;

  DateTime _fechaEntrega = DateTime.now();
  TimeOfDay _horaEntrega = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _totalPersonalizadoController = TextEditingController();
    _adelantoController = TextEditingController();
    _notasController = TextEditingController();
  }

  @override
  void dispose() {
    _totalPersonalizadoController.dispose();
    _adelantoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  double get _subtotalActual {
    if (_trabajoSeleccionado == null) return 0.0;
    return _trabajoSeleccionado!.calcularPrecio(_ancho, _alto, _cantidad, _adicional);
  }

  double get _totalOrden {
    final totalPersonalizadoValue = double.tryParse(_totalPersonalizadoController.text);
    if (totalPersonalizadoValue != null) {
      return totalPersonalizadoValue;
    }
    return _trabajosEnOrden.fold(0.0, (p, e) => p + e.precioFinal);
  }

  void _addTrabajoAOrden() {
    if (_trabajoSeleccionado == null) return;
    
    setState(() {
      _trabajosEnOrden.add(OrdenTrabajoTrabajo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        trabajo: _trabajoSeleccionado!,
        ancho: _ancho,
        alto: _alto,
        cantidad: _cantidad,
        adicional: _adicional,
      ));
      // Reset fields
      _trabajoSeleccionado = null;
      _ancho = 1.0;
      _alto = 1.0;
      _cantidad = 1;
      _adicional = 0.0;
    });
  }

  void _editTrabajoEnOrden(int index) {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => TrabajoFormDialog(
        trabajoEnOrden: _trabajosEnOrden[index],
        availableTrabajos: appState.trabajos,
        onSave: (editedTrabajo) {
          setState(() {
            _trabajosEnOrden[index] = editedTrabajo;
          });
        },
      ),
    );
  }

  void _guardarOrden() {
    if (_formKey.currentState!.validate()) {
      if (_clienteSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, seleccione un cliente')),
        );
        return;
      }
      if (_trabajosEnOrden.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, añada al menos un trabajo a la orden')),
        );
        return;
      }

      final appState = Provider.of<AppState>(context, listen: false);
      
      final totalPersonalizadoValue = double.tryParse(_totalPersonalizadoController.text);
      final adelantoValue = double.tryParse(_adelantoController.text) ?? 0.0;
      final notasValue = _notasController.text;

      final newOrden = OrdenTrabajo(
        id: Random().nextDouble().toString(),
        cliente: _clienteSeleccionado!,
        trabajos: _trabajosEnOrden,
        historial: [
          OrdenHistorial(
            id: Random().nextDouble().toString(),
            cambio: 'Creación de la orden.',
            usuarioId: appState.currentUser!.id,
            usuarioNombre: appState.currentUser!.nombre,
            timestamp: DateTime.now()
          )
        ],
        adelanto: adelantoValue,
        totalPersonalizado: totalPersonalizadoValue,
        notas: notasValue.isNotEmpty ? notasValue : null,
        fechaEntrega: _fechaEntrega,
        horaEntrega: _horaEntrega,
        creadoEn: DateTime.now(),
        creadoPorUsuarioId: appState.currentUser!.id,
      );
      
      appState.addOrden(newOrden);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orden guardada con éxito')),
      );
      
      // Reset the entire screen
      setState(() {
        _trabajosEnOrden = [];
        _clienteSeleccionado = null;
        _trabajoSeleccionado = null; // Resetear también el trabajo seleccionado
        
        // Clear controllers to update UI
        _totalPersonalizadoController.clear();
        _adelantoController.clear();
        _notasController.clear();

        _formKey.currentState?.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Column(
            children: [
              _buildAddWorkSection(appState),
              const SizedBox(height: 16),
              _buildWorkList(),
              const SizedBox(height: 16),
              _buildSummaryAndClientSection(appState),
              const SizedBox(height: 20),
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.save_rounded),
      label: const Text('Guardar Orden de Trabajo'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
      onPressed: _guardarOrden,
    );
  }

  Card _buildAddWorkSection(AppState appState) {
    // Filtrar trabajos únicos manualmente
    final uniqueTrabajos = <String, Trabajo>{};
    for (var trabajo in appState.trabajos) {
      uniqueTrabajos[trabajo.id] = trabajo;
    }
    final trabajosUnicos = uniqueTrabajos.values.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown para tipo de trabajo
            DropdownButtonFormField<Trabajo>(
              value: _trabajoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Tipo de Trabajo',
                prefixIcon: Icon(Icons.work_rounded),
              ),
              items: trabajosUnicos.asMap().entries.map((entry) {
                int index = entry.key;
                Trabajo trabajo = entry.value;
                return DropdownMenuItem<Trabajo>(
                  key: Key('trabajo_${trabajo.id}_$index'), // Key único con índice
                  value: trabajo,
                  child: Text(trabajo.nombre),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _trabajoSeleccionado = newValue;
                });
              },
            ),
            FormSpacing.verticalLarge(),
            
            // Fila con dimensiones - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  _buildInputField(
                    label: 'Ancho (m)',
                    icon: Icons.straighten_rounded,
                    initialValue: _ancho.toString(),
                    onChanged: (v) => setState(() => _ancho = double.tryParse(v) ?? 1.0),
                  ),
                  FormSpacing.verticalMedium(),
                  _buildInputField(
                    label: 'Alto (m)',
                    icon: Icons.height_rounded,
                    initialValue: _alto.toString(),
                    onChanged: (v) => setState(() => _alto = double.tryParse(v) ?? 1.0),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Ancho (m)',
                      icon: Icons.straighten_rounded,
                      initialValue: _ancho.toString(),
                      onChanged: (v) => setState(() => _ancho = double.tryParse(v) ?? 1.0),
                    ),
                  ),
                  FormSpacing.horizontalMedium(),
                  Expanded(
                    child: _buildInputField(
                      label: 'Alto (m)',
                      icon: Icons.height_rounded,
                      initialValue: _alto.toString(),
                      onChanged: (v) => setState(() => _alto = double.tryParse(v) ?? 1.0),
                    ),
                  ),
                ],
              ),
            ),
            FormSpacing.verticalLarge(),
            
            // Fila con cantidad y adicional - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  _buildInputField(
                    label: 'Cantidad',
                    icon: Icons.numbers_rounded,
                    initialValue: _cantidad.toString(),
                    onChanged: (v) => setState(() => _cantidad = int.tryParse(v) ?? 1),
                  ),
                  FormSpacing.verticalMedium(),
                  _buildInputField(
                    label: 'Adicional (Bs)',
                    icon: Icons.attach_money_rounded,
                    initialValue: _adicional.toString(),
                    onChanged: (v) => setState(() => _adicional = double.tryParse(v) ?? 0.0),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Cantidad',
                      icon: Icons.numbers_rounded,
                      initialValue: _cantidad.toString(),
                      onChanged: (v) => setState(() => _cantidad = int.tryParse(v) ?? 1),
                    ),
                  ),
                  FormSpacing.horizontalMedium(),
                  Expanded(
                    child: _buildInputField(
                      label: 'Adicional (Bs)',
                      icon: Icons.attach_money_rounded,
                      initialValue: _adicional.toString(),
                      onChanged: (v) => setState(() => _adicional = double.tryParse(v) ?? 0.0),
                    ),
                  ),
                ],
              ),
            ),
            FormSpacing.verticalLarge(),
            
            // Subtotal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE0F2FE),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Subtotal:",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D29),
                    ),
                  ),
                  Text(
                    "Bs ${_subtotalActual.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF98CA3F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Botón agregar
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir a la Orden'),
                onPressed: _trabajoSeleccionado != null ? _addTrabajoAOrden : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _buildWorkList() {
    if (_trabajosEnOrden.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.work_off_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aún no hay trabajos en esta orden',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega trabajos usando el formulario superior',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lista de trabajos
            ...List.generate(_trabajosEnOrden.length, (index) {
              final item = _trabajosEnOrden[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.work_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    '${item.trabajo.nombre} (${item.cantidad}x)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Dimensiones: ${item.ancho}m x ${item.alto}m'),
                      if (item.adicional > 0)
                        Text('Adicional: Bs ${item.adicional.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Bs ${item.precioFinal.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.ancho * item.alto} m²',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _trabajosEnOrden.removeAt(index);
                          });
                        },
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                  onTap: () => _editTrabajoEnOrden(index),
                ),
              );
            }),
            
            // Total de trabajos
            if (_trabajosEnOrden.isNotEmpty) ...[
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total de Trabajos:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Bs ${_trabajosEnOrden.fold(0.0, (sum, item) => sum + item.precioFinal).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryAndClientSection(AppState appState) {
    double totalBruto = _trabajosEnOrden.fold(0.0, (p, e) => p + e.precioFinal);
    final totalPersonalizado = double.tryParse(_totalPersonalizadoController.text);
    double rebaja = 0.0;
    if (totalPersonalizado != null && totalPersonalizado < totalBruto) {
      rebaja = totalBruto - totalPersonalizado;
    }

    // Filtrar clientes únicos manualmente
    final uniqueClientes = <String, Cliente>{};
    for (var cliente in appState.clientes) {
      uniqueClientes[cliente.id] = cliente;
    }
    final clientesUnicos = uniqueClientes.values.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selección de cliente
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<Cliente>(
                value: _clienteSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  prefixIcon: Icon(Icons.person_rounded),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: clientesUnicos.asMap().entries.map((entry) {
                  int index = entry.key;
                  Cliente cliente = entry.value;
                  return DropdownMenuItem<Cliente>(
                    key: Key('cliente_${cliente.id}_$index'), // Key único con índice
                    value: cliente,
                    child: Text(cliente.nombre),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _clienteSeleccionado = newValue;
                  });
                },
                validator: (value) => value == null ? 'Seleccione un cliente' : null,
              ),
            ),
            FormSpacing.verticalLarge(),
            
            // Campos financieros - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _totalPersonalizadoController,
                      decoration: const InputDecoration(
                        labelText: 'Total Personalizado (Bs)',
                        prefixIcon: Icon(Icons.edit_rounded),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintText: 'Opcional',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  FormSpacing.verticalMedium(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _adelantoController,
                      decoration: const InputDecoration(
                        labelText: 'Adelanto (Bs)',
                        prefixIcon: Icon(Icons.payment_rounded),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintText: '0.00',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _totalPersonalizadoController,
                        decoration: const InputDecoration(
                          labelText: 'Total Personalizado (Bs)',
                          prefixIcon: Icon(Icons.edit_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          hintText: 'Opcional',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                  ),
                  FormSpacing.horizontalMedium(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _adelantoController,
                        decoration: const InputDecoration(
                          labelText: 'Adelanto (Bs)',
                          prefixIcon: Icon(Icons.payment_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          hintText: '0.00',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FormSpacing.verticalLarge(),
            
            // Notas
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _notasController,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  prefixIcon: Icon(Icons.note_rounded),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: 'Información adicional...',
                ),
                maxLines: 3,
              ),
            ),
            FormSpacing.verticalLarge(),
            
            // Fecha y hora de entrega - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  // Fecha en móvil
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fechaEntrega,
                          firstDate: DateTime(2020, 1, 1), // Permite fechas desde 2020
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('es', 'ES'), // Español
                          // Configurar el primer día de la semana como lunes
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                datePickerTheme: DatePickerThemeData(
                                  // Configurar que la semana inicie con lunes
                                  dayOverlayColor: MaterialStateProperty.all(Colors.transparent),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) setState(() => _fechaEntrega = picked);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, 
                            color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha de Entrega',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(_fechaEntrega),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FormSpacing.verticalMedium(),
                  // Hora en móvil
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _horaEntrega,
                        );
                        if (picked != null) setState(() => _horaEntrega = picked);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, 
                            color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hora de Entrega',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _horaEntrega.format(context),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaEntrega,
                            firstDate: DateTime(2020, 1, 1), // Permite fechas desde 2020
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            locale: const Locale('es', 'ES'), // Español
                            // Configurar el primer día de la semana como lunes
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  datePickerTheme: DatePickerThemeData(
                                    // Configurar que la semana inicie con lunes
                                    dayOverlayColor: MaterialStateProperty.all(Colors.transparent),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setState(() => _fechaEntrega = picked);
                        },
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, 
                              color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha de Entrega',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(_fechaEntrega),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  FormSpacing.horizontalMedium(),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _horaEntrega,
                          );
                          if (picked != null) setState(() => _horaEntrega = picked);
                        },
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, 
                              color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hora de Entrega',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _horaEntrega.format(context),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FormSpacing.verticalLarge(),
            
            // Resumen financiero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Bruto:', 'Bs ${totalBruto.toStringAsFixed(2)}'),
                  if (rebaja > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow('Rebaja:', '-Bs ${rebaja.toStringAsFixed(2)}', 
                      color: Colors.orange),
                  ],
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Total Final:', 'Bs ${_totalOrden.toStringAsFixed(2)}', 
                    isTotal: true),
                  if (double.tryParse(_adelantoController.text) != null && 
                      double.tryParse(_adelantoController.text)! > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow('Adelanto:', 'Bs ${_adelantoController.text}', 
                      color: Colors.green),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Saldo:', 'Bs ${(_totalOrden - (double.tryParse(_adelantoController.text) ?? 0)).toStringAsFixed(2)}', 
                      color: Colors.blue),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Widget de archivos adjuntos para nueva orden
            if (_trabajosEnOrden.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Archivos Adjuntos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.attach_file_rounded),
                        label: const Text("Adjuntar Archivos"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Los archivos se pueden adjuntar después de guardar la orden. "
                                "Podrá acceder a esta funcionalidad desde la pantalla de detalle de la orden.",
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? (isTotal ? Theme.of(context).colorScheme.primary : null),
              fontSize: isTotal ? 18 : null,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class OrdenesTrabajoScreen extends StatefulWidget {
  const OrdenesTrabajoScreen({super.key});

  @override
  _OrdenesTrabajoScreenState createState() => _OrdenesTrabajoScreenState();
}

class _OrdenesTrabajoScreenState extends State<OrdenesTrabajoScreen> {
  String _searchQuery = '';
  String? _selectedFilter; // null = mostrar todas, 'pendiente', 'en_proceso', 'terminado', 'por_entregar'

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    var ordenes = appState.ordenes.where((orden) {
      return orden.cliente.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Aplicar filtro por estado
    if (_selectedFilter != null) {
      switch (_selectedFilter) {
        case 'pendiente':
          ordenes = ordenes.where((o) => o.estado == 'pendiente').toList();
          break;
        case 'en_proceso':
          ordenes = ordenes.where((o) => o.estado == 'en_proceso').toList();
          break;
        case 'terminado':
          ordenes = ordenes.where((o) => o.estado == 'terminado').toList();
          break;
        case 'por_entregar':
          ordenes = ordenes.where((o) => o.estado == 'terminado' && o.estado != 'entregado').toList();
          break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          children: [
            _buildStatsCards(appState.ordenes), // Pasamos todas las órdenes para el conteo
            if (_selectedFilter != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = null;
                      });
                    },
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: const Text('Limpiar filtros'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            FormSpacing.verticalMedium(),
            // Barra de búsqueda
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por cliente...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            FormSpacing.verticalSmall(),
            // Lista de órdenes
            if (ordenes.isEmpty)
              _buildEmptyState()
            else
              ...ordenes.map((orden) => _buildOrderCard(orden)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(List<OrdenTrabajo> ordenes) {
    final pendientes = ordenes.where((o) => o.estado == 'pendiente').length;
    final enProceso = ordenes.where((o) => o.estado == 'en_proceso').length;
    final terminadas = ordenes.where((o) => o.estado == 'terminado').length;
    final porEntregar = ordenes.where((o) => o.estado == 'terminado' && o.estado != 'entregado').length;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final spacing = isMobile ? 4.0 : 6.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Pendientes', pendientes.toString(), Colors.orange.shade600, 'pendiente')),
            SizedBox(width: spacing),
            Expanded(child: _buildStatCard('En Proceso', enProceso.toString(), Colors.blue.shade600, 'en_proceso')),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: _buildStatCard('Terminadas', terminadas.toString(), Colors.green.shade600, 'terminado')),
            SizedBox(width: spacing),
            Expanded(child: _buildStatCard('Por Entregar', porEntregar.toString(), Colors.red.shade600, 'por_entregar')),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, String filterKey) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSelected = _selectedFilter == filterKey;
    
    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = _selectedFilter == filterKey ? null : filterKey;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected ? Border.all(color: color, width: 2) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? color : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.filter_alt_rounded,
                        size: 16,
                        color: color,
                      ),
                  ],
                ),
                SizedBox(height: isMobile ? 4 : 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrdenTrabajo orden) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrdenDetalleScreen(orden: orden)),
          );
          if (result == true) {
            setState(() {});
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orden.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(orden.estado),
                      color: _getStatusColor(orden.estado),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden #${orden.id.substring(0, isMobile ? 6 : 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          orden.cliente.nombre,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Botón PDF
                  PopupMenuButton<String>(
                    icon: Icon(Icons.picture_as_pdf, color: Colors.red[600]),
                    tooltip: "Generar PDF",
                    onSelected: (String result) async {
                      await _generateOrderPDF(orden, result);
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'orden_trabajo',
                        child: Row(
                          children: [
                            Icon(Icons.work_outline, size: 16),
                            SizedBox(width: 8),
                            Text('Orden de Trabajo', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'proforma',
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Proforma', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'nota_venta',
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Nota de Venta', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orden.estado),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(orden.estado),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Información financiera - Responsive
              ResponsiveLayout(
                mobile: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Bs ${orden.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Saldo',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Bs ${orden.saldo.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: orden.saldo > 0 ? Colors.orange : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Entrega: ${DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(orden.fechaEntrega)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          orden.horaEntrega.format(context),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                tablet: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Bs ${orden.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Saldo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Bs ${orden.saldo.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: orden.saldo > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Entrega',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${orden.fechaEntrega.day}/${orden.fechaEntrega.month}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          orden.horaEntrega.format(context),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateOrderPDF(OrdenTrabajo orden, String type) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      Uint8List pdfBytes;
      String fileName;

      switch (type) {
        case 'orden_trabajo':
          pdfBytes = await PDFGenerator.generateOrdenTrabajo(orden);
          fileName = 'orden_trabajo_${orden.id.substring(0, 8)}.pdf';
          break;
        case 'proforma':
          pdfBytes = await PDFGenerator.generateProforma(orden);
          fileName = 'proforma_${orden.id.substring(0, 8)}.pdf';
          break;
        case 'nota_venta':
          pdfBytes = await PDFGenerator.generateNotaVenta(orden);
          fileName = 'nota_venta_${orden.id.substring(0, 8)}.pdf';
          break;
        default:
          Navigator.pop(context); // Cerrar loading
          return;
      }

      Navigator.pop(context); // Cerrar loading

      // Compartir el PDF usando la funcionalidad nativa de Android
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (e) {
      Navigator.pop(context); // Cerrar loading en caso de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron órdenes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una nueva orden desde la pestaña Cotizar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String estado) {
    switch (estado) {
      case 'pendiente': return 'PENDIENTE';
      case 'en_proceso': return 'EN PROCESO';
      case 'terminado': return 'TERMINADO';
      case 'entregado': return 'ENTREGADO';
      default: return estado.toUpperCase();
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'pendiente': return Icons.hourglass_empty_rounded;
      case 'en_proceso': return Icons.work_rounded;
      case 'terminado': return Icons.check_circle_rounded;
      case 'entregado': return Icons.local_shipping_rounded;
      default: return Icons.help_rounded;
    }
  }
  
  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'pendiente': return Colors.orange;
      case 'en_proceso': return Colors.blue;
      case 'terminado': return Colors.green;
      case 'entregado': return Colors.grey;
      default: return Colors.black;
    }
  }
}


// -------------------
// --- WORK ORDER DETAIL AND EDIT SCREEN ---
// -------------------

class OrdenDetalleScreen extends StatefulWidget {
  final OrdenTrabajo orden;
  const OrdenDetalleScreen({super.key, required this.orden});

  @override
  _OrdenDetalleScreenState createState() => _OrdenDetalleScreenState();
}

class _OrdenDetalleScreenState extends State<OrdenDetalleScreen> {
  late OrdenTrabajo _ordenEditable;
  final List<String> _estados = ['pendiente', 'en_proceso', 'terminado', 'entregado'];
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to update TextFields when state changes
  late TextEditingController _totalPersonalizadoController;
  late TextEditingController _adelantoController;

  @override
  void initState() {
    super.initState();
    // Clone the order for local editing to avoid modifying the original object directly
    // NOTE: NO clonamos archivos porque se manejan directamente por el widget ArchivosAdjuntosWidget
    _ordenEditable = OrdenTrabajo(
      id: widget.orden.id,
      cliente: widget.orden.cliente,
      trabajos: List<OrdenTrabajoTrabajo>.from(widget.orden.trabajos.map((t) => OrdenTrabajoTrabajo(id: t.id, trabajo: t.trabajo, ancho: t.ancho, alto: t.alto, cantidad: t.cantidad, adicional: t.adicional))),
      historial: List<OrdenHistorial>.from(widget.orden.historial),
      adelanto: widget.orden.adelanto,
      totalPersonalizado: widget.orden.totalPersonalizado,
      notas: widget.orden.notas,
      estado: widget.orden.estado,
      fechaEntrega: widget.orden.fechaEntrega,
      horaEntrega: widget.orden.horaEntrega,
      creadoEn: widget.orden.creadoEn,
      creadoPorUsuarioId: widget.orden.creadoPorUsuarioId,
      archivos: widget.orden.archivos, // Referencia directa, no copia
    );

    _totalPersonalizadoController = TextEditingController(text: _ordenEditable.totalPersonalizado?.toString() ?? '');
    _adelantoController = TextEditingController(text: _ordenEditable.adelanto.toString());
  }
  
  @override
  void dispose() {
    _totalPersonalizadoController.dispose();
    _adelantoController.dispose();
    super.dispose();
  }

  void _guardarCambios() {
    if (_formKey.currentState!.validate()){
      _formKey.currentState!.save();
      
      // Update the original order with the edited values
      // NOTE: NO actualizamos archivos porque se manejan directamente por el widget ArchivosAdjuntosWidget
      widget.orden.cliente = _ordenEditable.cliente;
      widget.orden.trabajos = _ordenEditable.trabajos;
      widget.orden.adelanto = _ordenEditable.adelanto;
      widget.orden.totalPersonalizado = _ordenEditable.totalPersonalizado;
      widget.orden.notas = _ordenEditable.notas;
      widget.orden.estado = _ordenEditable.estado;
      widget.orden.fechaEntrega = _ordenEditable.fechaEntrega;
      widget.orden.horaEntrega = _ordenEditable.horaEntrega;
      // widget.orden.archivos = _ordenEditable.archivos; // REMOVIDO: No sobreescribir archivos
      
      Provider.of<AppState>(context, listen: false).updateOrden(widget.orden, "Orden actualizada.");
      Navigator.pop(context, true); // Return true to indicate changes were made
    }
  }

  Future<void> _generatePDF(String type) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      Uint8List pdfBytes;
      String fileName;

      switch (type) {
        case 'orden_trabajo':
          pdfBytes = await PDFGenerator.generateOrdenTrabajo(_ordenEditable);
          fileName = 'orden_trabajo_${_ordenEditable.id.substring(0, 8)}.pdf';
          break;
        case 'proforma':
          pdfBytes = await PDFGenerator.generateProforma(_ordenEditable);
          fileName = 'proforma_${_ordenEditable.id.substring(0, 8)}.pdf';
          break;
        case 'nota_venta':
          pdfBytes = await PDFGenerator.generateNotaVenta(_ordenEditable);
          fileName = 'nota_venta_${_ordenEditable.id.substring(0, 8)}.pdf';
          break;
        default:
          Navigator.pop(context); // Cerrar loading
          return;
      }

      Navigator.pop(context); // Cerrar loading

      // Compartir el PDF usando la funcionalidad nativa de Android
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (e) {
      Navigator.pop(context); // Cerrar loading en caso de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
    }
  }

  void _showEditTrabajoDialog(OrdenTrabajoTrabajo trabajo, int index) {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => TrabajoFormDialog(
        trabajoEnOrden: trabajo,
        availableTrabajos: appState.trabajos,
        onSave: (editedTrabajo) {
          setState(() {
            _ordenEditable.trabajos[index] = editedTrabajo;
            _ordenEditable.totalPersonalizado = null;
            _totalPersonalizadoController.clear();
          });
        },
      )
    );
  }
  
  void _showAddTrabajoDialog() {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => TrabajoFormDialog(
        onSave: (nuevoTrabajo) {
          setState(() {
            _ordenEditable.trabajos.add(nuevoTrabajo);
            _ordenEditable.totalPersonalizado = null;
            _totalPersonalizadoController.clear();
          });
        },
        availableTrabajos: appState.trabajos,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detalle Orden #${_ordenEditable.id.substring(0, 4)}'),
          actions: [
            // Menú de PDF
            PopupMenuButton<String>(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: "Generar PDF",
              onSelected: (String result) async {
                await _generatePDF(result);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'orden_trabajo',
                  child: Row(
                    children: [
                      Icon(Icons.work_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Orden de Trabajo'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'proforma',
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Proforma'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'nota_venta',
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Nota de Venta'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarCambios,
              tooltip: "Guardar Cambios",
            )
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.edit_document), text: "Detalles"),
              Tab(icon: Icon(Icons.history), text: "Historial"),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            children: [
              _buildDetallesTab(appState),
              _buildHistorialTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetallesTab(AppState appState) {
    // Filtrar clientes únicos manualmente
    final uniqueClientes = <String, Cliente>{};
    for (var cliente in appState.clientes) {
      uniqueClientes[cliente.id] = cliente;
    }
    final clientesUnicos = uniqueClientes.values.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- CLIENT AND STATUS SECTION ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<Cliente>(
                  value: clientesUnicos.firstWhere((c) => c.id == _ordenEditable.cliente.id, orElse: () => _ordenEditable.cliente),
                  decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
                  items: clientesUnicos.asMap().entries.map((entry) {
                    int index = entry.key;
                    Cliente c = entry.value;
                    return DropdownMenuItem(
                      key: Key('cliente_edit_${c.id}_$index'), // Key único con índice
                      value: c, 
                      child: Text(c.nombre)
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _ordenEditable.cliente = val);
                  },
                ),
                FormSpacing.verticalMedium(),
                DropdownButtonFormField<String>(
                  value: _ordenEditable.estado,
                  decoration: const InputDecoration(labelText: 'Estado de la Orden', border: OutlineInputBorder()),
                  items: _estados.asMap().entries.map((entry) {
                    int index = entry.key;
                    String e = entry.value;
                    return DropdownMenuItem(
                      key: Key('estado_${e}_$index'), // Key único con índice
                      value: e, 
                      child: Text(e.toUpperCase())
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _ordenEditable.estado = val);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // --- JOBS SECTION ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Trabajos', style: Theme.of(context).textTheme.titleLarge),
                ),
                ..._ordenEditable.trabajos.map((trabajo) {
                  int index = _ordenEditable.trabajos.indexOf(trabajo);
                  return ListTile(
                    title: Text(trabajo.trabajo.nombre),
                    subtitle: Text('${trabajo.ancho}x${trabajo.alto}m - ${trabajo.cantidad} uds.'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Bs ${trabajo.precioFinal.toStringAsFixed(2)}'),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _ordenEditable.trabajos.removeAt(index);
                              _ordenEditable.totalPersonalizado = null;
                              _totalPersonalizadoController.clear();
                            });
                          },
                        )
                      ],
                    ),
                    onTap: () => _showEditTrabajoDialog(trabajo, index),
                  );
                }).toList(),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(Icons.add),
                    label: Text("Añadir Trabajo"),
                    onPressed: _showAddTrabajoDialog,
                  ),
                )
              ],
            ),
          )
        ),
        const SizedBox(height: 16),
        // --- FINANCIAL SECTION ---
        _buildFinancialDetails(),
        const SizedBox(height: 16),
        // --- DELIVERY DATE AND TIME SECTION ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha y Hora de Entrega',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                // Fecha y hora de entrega - Responsive
                ResponsiveLayout(
                  mobile: Column(
                    children: [
                      // Fecha en móvil
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _ordenEditable.fechaEntrega,
                              firstDate: DateTime(2020, 1, 1), // Permite fechas desde 2020
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              locale: const Locale('es', 'ES'), // Español
                              // Configurar el primer día de la semana como lunes
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    datePickerTheme: DatePickerThemeData(
                                      // Configurar que la semana inicie con lunes
                                      dayOverlayColor: MaterialStateProperty.all(Colors.transparent),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _ordenEditable.fechaEntrega = picked);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, 
                                color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha de Entrega',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(_ordenEditable.fechaEntrega),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      FormSpacing.verticalMedium(),
                      // Hora en móvil
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _ordenEditable.horaEntrega,
                            );
                            if (picked != null) {
                              setState(() => _ordenEditable.horaEntrega = picked);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, 
                                color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hora de Entrega',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _ordenEditable.horaEntrega.format(context),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  tablet: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _ordenEditable.fechaEntrega,
                                firstDate: DateTime(2020, 1, 1), // Permite fechas desde 2020
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                locale: const Locale('es', 'ES'), // Español
                                // Configurar el primer día de la semana como lunes
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      datePickerTheme: DatePickerThemeData(
                                        // Configurar que la semana inicie con lunes
                                        dayOverlayColor: MaterialStateProperty.all(Colors.transparent),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _ordenEditable.fechaEntrega = picked);
                              }
                            },
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, 
                                  color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fecha de Entrega',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(_ordenEditable.fechaEntrega),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      FormSpacing.horizontalMedium(),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _ordenEditable.horaEntrega,
                              );
                              if (picked != null) {
                                setState(() => _ordenEditable.horaEntrega = picked);
                              }
                            },
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded, 
                                  color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hora de Entrega',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        _ordenEditable.horaEntrega.format(context),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // --- NOTES SECTION ---
        TextFormField(
          initialValue: _ordenEditable.notas,
          decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()),
          maxLines: 3,
          onSaved: (value) => _ordenEditable.notas = value,
        ),
        FormSpacing.verticalLarge(),
        
        // --- ARCHIVOS ADJUNTOS SECTION ---
        ArchivosAdjuntosWidget(orden: widget.orden),
        FormSpacing.verticalLarge(),
        
        // --- SAVE BUTTON ---
        ElevatedButton.icon(
          icon: const Icon(Icons.save_rounded),
          label: const Text('Guardar Cambios'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          onPressed: _guardarCambios,
        ),
        FormSpacing.verticalMedium(),
      ],
    );
  }
  
  Widget _buildHistorialTab() {
    if (_ordenEditable.historial.isEmpty) {
      return Center(child: Text("No hay historial para esta orden."));
    }
    return ListView.builder(
      itemCount: _ordenEditable.historial.length,
      itemBuilder: (context, index) {
        final evento = _ordenEditable.historial.reversed.toList()[index]; // Show newest first
        return ListTile(
          leading: Icon(Icons.info_outline),
          title: Text(evento.cambio),
          subtitle: Text('Por: ${evento.usuarioNombre}'),
          // Formatear fecha y hora en español
          trailing: Text(DateFormat('d/M/y H:mm', 'es_ES').format(evento.timestamp.toLocal())),
        );
      },
    );
  }

  Card _buildFinancialDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _financialRow('Total Bruto:', '\$${_ordenEditable.totalBruto.toStringAsFixed(2)}'),
            FormSpacing.verticalMedium(),
            TextFormField(
              controller: _totalPersonalizadoController,
              decoration: const InputDecoration(labelText: 'Total Personalizado (\$)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  _ordenEditable.totalPersonalizado = double.tryParse(value);
                });
              },
              onSaved: (value) {
                 _ordenEditable.totalPersonalizado = double.tryParse(value ?? '');
              },
            ),
            FormSpacing.verticalSmall(),
            _financialRow('Rebaja:', '\$${_ordenEditable.rebaja > 0 ? _ordenEditable.rebaja.toStringAsFixed(2) : '0.00'}'),
            const Divider(height: 24),
            _financialRow('Total Final:', '\$${_ordenEditable.total.toStringAsFixed(2)}', isTotal: true),
            FormSpacing.verticalMedium(),
            TextFormField(
              controller: _adelantoController,
              decoration: const InputDecoration(labelText: 'Adelanto (\$)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  _ordenEditable.adelanto = double.tryParse(value) ?? 0.0;
                });
              },
              onSaved: (value) {
                _ordenEditable.adelanto = double.tryParse(value!) ?? 0.0;
              },
            ),
            FormSpacing.verticalSmall(),
            _financialRow('Saldo Pendiente:', '\$${_ordenEditable.saldo.toStringAsFixed(2)}', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _financialRow(String label, String value, {bool isTotal = false}) {
    final style = isTotal 
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold) 
        : Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}


// -------------------
// --- MANAGEMENT SCREENS (Drawer) ---
// -------------------

abstract class GestionScreen<T extends HiveObject> extends StatefulWidget {
  const GestionScreen({super.key});
}

abstract class GestionScreenState<T extends HiveObject> extends State<GestionScreen<T>> {
  bool _showArchived = false;

  Widget buildScaffold(BuildContext context, {
    required String title,
    required List<T> items,
    required List<T> archivedItems,
    required Widget Function(T item) buildTile,
    required void Function() onFabPressed,
  }) {
    final displayItems = _showArchived ? archivedItems : items;
    return Scaffold(
      appBar: AppBar(
        title: Text(_showArchived ? '$title (Archivados)' : title),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.inventory_2_outlined : Icons.archive_outlined),
            tooltip: _showArchived ? 'Ver Activos' : 'Ver Archivados',
            onPressed: () => setState(() => _showArchived = !_showArchived),
          )
        ],
      ),
      body: displayItems.isEmpty
        ? Center(child: Text(_showArchived ? 'No hay elementos archivados.' : 'No hay elementos.'))
        : ListView.builder(
            itemCount: displayItems.length,
            itemBuilder: (context, index) => buildTile(displayItems[index]),
          ),
      floatingActionButton: _showArchived ? null : FloatingActionButton(
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
    showDialog(context: context, builder: (_) => TrabajoFormDialog(trabajo: trabajo));
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
        trailing: _showArchived 
          ? IconButton(icon: Icon(Icons.unarchive), onPressed: () => appState.restoreTrabajo(trabajo), tooltip: "Restaurar",)
          : IconButton(icon: const Icon(Icons.edit), onPressed: () => _showTrabajoDialog(context, trabajo: trabajo)),
      ),
    );
  }
}

class GestionClientesScreen extends GestionScreen<Cliente> {
  const GestionClientesScreen({super.key});
  @override
  _GestionClientesScreenState createState() => _GestionClientesScreenState();
}

class _GestionClientesScreenState extends GestionScreenState<Cliente> {
  void _showClienteDialog(BuildContext context, {Cliente? cliente}) {
    showDialog(context: context, builder: (_) => ClienteFormDialog(cliente: cliente));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return buildScaffold(
      context,
      title: 'Gestionar Clientes',
      items: appState.clientes,
      archivedItems: appState.clientesArchivados,
      onFabPressed: () => _showClienteDialog(context),
      buildTile: (cliente) => ListTile(
        title: Text(cliente.nombre),
        subtitle: Text('Contacto: ${cliente.contacto}'),
        trailing: _showArchived 
          ? IconButton(icon: Icon(Icons.unarchive), onPressed: () => appState.restoreCliente(cliente), tooltip: "Restaurar",)
          : IconButton(icon: const Icon(Icons.edit), onPressed: () => _showClienteDialog(context, cliente: cliente)),
        onTap: () {
          if (!_showArchived) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ClienteDetalleScreen(cliente: cliente)));
          }
        },
      ),
    );
  }
}

class GestionUsuariosScreen extends GestionScreen<Usuario> {
  const GestionUsuariosScreen({super.key});
  @override
  _GestionUsuariosScreenState createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends GestionScreenState<Usuario> {
  void _showUsuarioDialog(BuildContext context, {Usuario? usuario}) {
    showDialog(context: context, builder: (_) => UsuarioFormDialog(usuario: usuario));
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return buildScaffold(
      context,
      title: 'Gestionar Usuarios',
      items: appState.usuarios,
      archivedItems: appState.usuariosArchivados,
      buildTile: (usuario) => ListTile(
        leading: CircleAvatar(child: Text(usuario.rol.substring(0,1).toUpperCase())),
        title: Text(usuario.nombre),
        subtitle: Text(usuario.email),
        trailing: _showArchived
          ? IconButton(icon: Icon(Icons.unarchive), onPressed: () => appState.restoreUsuario(usuario), tooltip: "Restaurar",)
          : (usuario.id != appState.currentUser?.id 
              ? IconButton(icon: const Icon(Icons.edit), onPressed: () => _showUsuarioDialog(context, usuario: usuario))
              : null),
      ),
      onFabPressed: () => _showUsuarioDialog(context),
    );
  }
}


// -------------------
// --- CLIENT DETAIL SCREEN ---
// -------------------

class ClienteDetalleScreen extends StatelessWidget {
  final Cliente cliente;
  const ClienteDetalleScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final ordenesCliente = appState.ordenes.where((o) => o.cliente.id == cliente.id).toList();

    return Scaffold(
      appBar: AppBar(title: Text(cliente.nombre)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Órdenes de Trabajo Asociadas", style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: ordenesCliente.isEmpty 
            ? Center(child: Text("Este cliente no tiene órdenes de trabajo."))
            : ListView.builder(
              itemCount: ordenesCliente.length,
              itemBuilder: (context, index) {
                final orden = ordenesCliente[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text("Orden #${orden.id.substring(0,4)}"),
                    subtitle: Text("Total: \$${orden.total.toStringAsFixed(2)}"),
                    trailing: Chip(
                      label: Text(orden.estado, style: TextStyle(color: Colors.white)),
                      backgroundColor: _getStatusColor(orden.estado),
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => OrdenDetalleScreen(orden: orden)));
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
      case 'pendiente': return Colors.orange;
      case 'en_proceso': return Colors.blue;
      case 'terminado': return Colors.green;
      case 'entregado': return Colors.grey;
      default: return Colors.black;
    }
  }
}


// -------------------
// --- FORM DIALOGS (CRUD) ---
// -------------------

class TrabajoFormDialog extends StatefulWidget {
  final Trabajo? trabajo;
  final OrdenTrabajoTrabajo? trabajoEnOrden;
  final Function(OrdenTrabajoTrabajo)? onSave;
  final List<Trabajo>? availableTrabajos;

  const TrabajoFormDialog({
    super.key, 
    this.trabajo, 
    this.trabajoEnOrden,
    this.onSave,
    this.availableTrabajos,
  });

  @override
  _TrabajoFormDialogState createState() => _TrabajoFormDialogState();
}

class _TrabajoFormDialogState extends State<TrabajoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // For new/editing job types
  late String _nombre;
  late double _precioM2;
  
  // For jobs within an order
  Trabajo? _selectedTrabajo;
  late double _ancho;
  late double _alto;
  late int _cantidad;
  late double _adicional;

  bool get isOrderJob => widget.trabajoEnOrden != null || widget.onSave != null;

  @override
  void initState() {
    super.initState();
    if (isOrderJob) {
      _selectedTrabajo = widget.trabajoEnOrden?.trabajo;
      _ancho = widget.trabajoEnOrden?.ancho ?? 1.0;
      _alto = widget.trabajoEnOrden?.alto ?? 1.0;
      _cantidad = widget.trabajoEnOrden?.cantidad ?? 1;
      _adicional = widget.trabajoEnOrden?.adicional ?? 0.0;
    } else {
      _nombre = widget.trabajo?.nombre ?? '';
      _precioM2 = widget.trabajo?.precioM2 ?? 0.0;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (isOrderJob) {
        final newOrderJob = OrdenTrabajoTrabajo(
          id: widget.trabajoEnOrden?.id ?? Random().nextDouble().toString(),
          trabajo: _selectedTrabajo!,
          ancho: _ancho,
          alto: _alto,
          cantidad: _cantidad,
          adicional: _adicional,
        );
        widget.onSave!(newOrderJob);

      } else {
        final appState = Provider.of<AppState>(context, listen: false);
        final newTrabajo = Trabajo(
          id: widget.trabajo?.id ?? Random().nextDouble().toString(),
          nombre: _nombre,
          precioM2: _precioM2,
          negocioId: appState.currentUser!.negocioId,
          creadoEn: widget.trabajo?.creadoEn ?? DateTime.now()
        );

        if (widget.trabajo == null) {
          appState.addTrabajo(newTrabajo);
        } else {
          appState.updateTrabajo(newTrabajo);
        }
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isOrderJob 
        ? (widget.trabajoEnOrden == null ? 'Añadir Trabajo a Orden' : 'Editar Trabajo de Orden')
        : (widget.trabajo == null ? 'Nuevo Tipo de Trabajo' : 'Editar Tipo de Trabajo')),
      content: Form(
        key: _formKey,
        child: isOrderJob ? _buildOrderJobForm() : _buildJobTypeForm(),
      ),
      actions: [
        if (!isOrderJob && widget.trabajo != null)
          TextButton(
            child: Text('Archivar', style: TextStyle(color: Colors.redAccent)),
            onPressed: (){
              Provider.of<AppState>(context, listen: false).deleteTrabajo(widget.trabajo!);
              Navigator.of(context).pop();
            },
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }

  Widget _buildJobTypeForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          initialValue: _nombre,
          decoration: const InputDecoration(labelText: 'Nombre del Trabajo'),
          validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
          onSaved: (v) => _nombre = v!,
        ),
        FormSpacing.verticalMedium(),
        TextFormField(
          initialValue: _precioM2.toString(),
          decoration: const InputDecoration(labelText: 'Precio por m²'),
          keyboardType: TextInputType.number,
          validator: (v) => (double.tryParse(v!) == null) ? 'Número inválido' : null,
          onSaved: (v) => _precioM2 = double.parse(v!),
        ),
      ],
    );
  }

  Widget _buildOrderJobForm() {
    // Filtrar trabajos únicos manualmente
    final uniqueTrabajos = <String, Trabajo>{};
    if (widget.availableTrabajos != null) {
      for (var trabajo in widget.availableTrabajos!) {
        uniqueTrabajos[trabajo.id] = trabajo;
      }
    }
    final trabajosUnicos = uniqueTrabajos.values.toList();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Trabajo>(
            value: _selectedTrabajo,
            items: trabajosUnicos.asMap().entries.map((entry) {
              int index = entry.key;
              Trabajo t = entry.value;
              return DropdownMenuItem(
                key: Key('trabajo_dialog_${t.id}_$index'), // Key único con índice
                value: t, 
                child: Text(t.nombre)
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedTrabajo = val),
            decoration: InputDecoration(labelText: 'Tipo de Trabajo'),
            validator: (v) => v == null ? 'Seleccione un trabajo' : null,
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _ancho.toString(),
            decoration: const InputDecoration(labelText: 'Ancho (m)'),
            keyboardType: TextInputType.number,
            validator: (v) => (double.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _ancho = double.parse(v!),
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _alto.toString(),
            decoration: const InputDecoration(labelText: 'Alto (m)'),
            keyboardType: TextInputType.number,
            validator: (v) => (double.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _alto = double.parse(v!),
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _cantidad.toString(),
            decoration: const InputDecoration(labelText: 'Cantidad'),
            keyboardType: TextInputType.number,
            validator: (v) => (int.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _cantidad = int.parse(v!),
          ),
          FormSpacing.verticalMedium(),
          TextFormField(
            initialValue: _adicional.toString(),
            decoration: const InputDecoration(labelText: 'Adicional (\$)'),
            keyboardType: TextInputType.number,
            validator: (v) => (double.tryParse(v!) == null) ? 'Número inválido' : null,
            onSaved: (v) => _adicional = double.parse(v!),
          ),
        ],
      ),
    );
  }
}


class ClienteFormDialog extends StatefulWidget {
  final Cliente? cliente;
  const ClienteFormDialog({super.key, this.cliente});

  @override
  _ClienteFormDialogState createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre;
  late String _contacto;

  @override
  void initState() {
    super.initState();
    _nombre = widget.cliente?.nombre ?? '';
    _contacto = widget.cliente?.contacto ?? '';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final appState = Provider.of<AppState>(context, listen: false);
      final newCliente = Cliente(
        id: widget.cliente?.id ?? Random().nextDouble().toString(),
        nombre: _nombre,
        contacto: _contacto,
        negocioId: appState.currentUser!.negocioId,
        creadoEn: widget.cliente?.creadoEn ?? DateTime.now(),
      );

      if (widget.cliente == null) {
        appState.addCliente(newCliente);
      } else {
        appState.updateCliente(newCliente);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre del Cliente'),
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              onSaved: (v) => _nombre = v!,
            ),
            FormSpacing.verticalMedium(),
            TextFormField(
              initialValue: _contacto,
              decoration: const InputDecoration(labelText: 'Contacto (Teléfono, Email, etc.)'),
              onSaved: (v) => _contacto = v!,
            ),
          ],
        ),
      ),
      actions: [
         if (widget.cliente != null)
          TextButton(
            child: Text('Archivar', style: TextStyle(color: Colors.redAccent)),
            onPressed: (){
              Provider.of<AppState>(context, listen: false).deleteCliente(widget.cliente!);
              Navigator.of(context).pop();
            },
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}

class UsuarioFormDialog extends StatefulWidget {
  final Usuario? usuario;
  const UsuarioFormDialog({super.key, this.usuario});

  @override
  _UsuarioFormDialogState createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre;
  late String _email;
  late String _rol;
  late String _password;

  @override
  void initState() {
    super.initState();
    _nombre = widget.usuario?.nombre ?? '';
    _email = widget.usuario?.email ?? '';
    _rol = widget.usuario?.rol ?? 'empleado';
    _password = widget.usuario?.password ?? '';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final appState = Provider.of<AppState>(context, listen: false);
      final newUsuario = Usuario(
        id: widget.usuario?.id ?? Random().nextDouble().toString(),
        nombre: _nombre,
        email: _email,
        rol: _rol,
        password: _password, // In a real app, this should be handled more securely
        negocioId: appState.currentUser!.negocioId,
        creadoEn: widget.usuario?.creadoEn ?? DateTime.now(),
      );
      
      if (widget.usuario == null) {
        appState.addUsuario(newUsuario);
      } else {
        appState.updateUsuario(newUsuario);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return AlertDialog(
      title: Text(widget.usuario == null ? 'Nuevo Usuario' : 'Editar Usuario'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              onSaved: (v) => _nombre = v!,
            ),
            TextFormField(
              initialValue: _email,
              decoration: const InputDecoration(labelText: 'Email (login)'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? 'Email inválido' : null,
              onSaved: (v) => _email = v!,
            ),
            TextFormField(
              initialValue: _password,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              onSaved: (v) => _password = v!,
              obscureText: true,
            ),
            DropdownButtonFormField<String>(
              value: _rol,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: ['admin', 'empleado'].asMap().entries.map((entry) {
                int index = entry.key;
                String rol = entry.value;
                return DropdownMenuItem<String>(
                  key: Key('rol_${rol}_$index'), // Key único con índice
                  value: rol,
                  child: Text(rol.toUpperCase()),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _rol = newValue;
                  });
                }
              },
            )
          ],
        ),
      ),
      actions: [
        if (widget.usuario != null && widget.usuario!.id != appState.currentUser!.id)
          TextButton(
            child: Text('Archivar', style: TextStyle(color: Colors.redAccent)),
            onPressed: (){
              Provider.of<AppState>(context, listen: false).deleteUsuario(widget.usuario!);
              Navigator.of(context).pop();
            },
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
