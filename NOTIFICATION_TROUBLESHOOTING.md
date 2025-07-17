# Solución de Problemas de Notificaciones

## Problemas Identificados y Soluciones

### 1. Configuración de SDK Android
**Problema:** Los plugins requieren Android SDK 35 o superior, pero el proyecto estaba configurado con SDK 34.
**Solución:** Actualizado `compileSdk = 35` y `targetSdk = 35` en build.gradle.kts.

### 2. Archivo XML de Canales de Notificación
**Problema:** El archivo `notification_channels.xml` tenía formato incorrecto causando errores de compilación.
**Solución:** Eliminado el archivo XML ya que los canales se crean desde código Dart.

### 3. Configuración de Timezone
**Problema:** El timezone `America/La_Paz` puede no estar disponible en todos los dispositivos.
**Solución:** Implementado fallback a UTC si el timezone no está disponible.

### 4. Permisos de Android
**Problema:** Faltan permisos críticos para notificaciones exactas en Android 12+.
**Solución:** Agregados permisos adicionales en AndroidManifest.xml:
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- `FOREGROUND_SERVICE`
- `SYSTEM_ALERT_WINDOW`
- `USE_FULL_SCREEN_INTENT`

### 5. Configuración de Canales de Notificación
**Problema:** Los canales de notificación no se crean correctamente.
**Solución:** Implementado método `_createNotificationChannels()` con configuración explícita desde código Dart.

### 6. Permisos de Alarma Exacta
**Problema:** Android 12+ requiere permisos específicos para alarmas exactas.
**Solución:** Agregado `requestExactAlarmsPermission()` en la inicialización.

### 7. Programación de Notificaciones
**Problema:** `androidAllowWhileIdle` está deprecado.
**Solución:** Cambiado a `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle`.

### 8. Manejo de Errores
**Problema:** Errores en programación no se manejan correctamente.
**Solución:** Implementado try-catch con fallback a notificación inmediata.

## Pruebas de Verificación

### 1. Verificar Configuración del Sistema
```dart
await NotificationService.checkSystemConfiguration();
```

### 2. Probar Notificación Inmediata
```dart
await NotificationService.testNotification();
```

### 3. Probar Notificación Programada (30 segundos)
```dart
await NotificationService.testScheduledNotification();
```

### 4. Probar Notificación Programada (2 minutos)
```dart
await NotificationService.testScheduledNotification2Minutes();
```

### 5. Verificar Notificaciones Pendientes
```dart
final pending = await NotificationService.getPendingNotifications();
print('Notificaciones pendientes: ${pending.length}');
```

## Configuración Manual del Dispositivo

### Android 12+
1. **Permisos de Notificación:**
   - Configuración → Aplicaciones → Cotizador → Notificaciones → Permitir

2. **Alarmas Exactas:**
   - Configuración → Aplicaciones → Acceso especial → Alarmas y recordatorios → Cotizador → Permitir

3. **Optimización de Batería:**
   - Configuración → Batería → Optimización de batería → Cotizador → No optimizar

4. **Aplicaciones en Segundo Plano:**
   - Configuración → Aplicaciones → Cotizador → Batería → Sin restricciones

### Verificación con ADB
```bash
# Ejecutar script de verificación
./scripts/check_notifications.sh
```

## Logs de Debugging

Los logs del sistema de notificaciones incluyen:
- 🔍 Verificación del sistema
- 📅 Programación de notificaciones
- 🔔 Estado de notificaciones
- ⚠️ Errores y warnings
- ✅ Confirmaciones de éxito

## Errores de Compilación Conocidos

### Error: "Plugin requires Android SDK version 35 or higher"
**Problema:** Los plugins de Flutter requieren SDK 35 pero el proyecto está configurado con una versión menor.
**Solución:** 
```kotlin
android {
    compileSdk = 35
    defaultConfig {
        targetSdk = 35
    }
}
```

### Error: "Android resource linking failed - notification_channels.xml"
**Problema:** El archivo XML de canales de notificación tiene formato incorrecto.
**Solución:** Eliminar el archivo XML y crear los canales desde código Dart.

### Error: "attribute android:enableVibration not found"
**Problema:** Atributos incorrectos en el archivo XML de notificaciones.
**Solución:** Los canales se crean programáticamente desde NotificationService.

## Solución de Problemas Comunes

### Notificaciones No Llegan
1. Verificar permisos de notificación
2. Verificar permisos de alarma exacta
3. Revisar configuración de optimización de batería
4. Verificar que la orden esté en estado "en_proceso"
5. Verificar que la fecha/hora de entrega sea futura

### Notificaciones Llegan Tarde
1. Verificar permisos de alarma exacta
2. Revisar configuración de optimización de batería
3. Verificar que no haya restricciones de background

### Workmanager No Funciona
1. Verificar permisos de RECEIVE_BOOT_COMPLETED
2. Verificar que Workmanager esté inicializado
3. Revisar configuración en AndroidManifest.xml

## Configuración Óptima

### Compilación
- compileSdk = 35
- targetSdk = 35
- minSdk = 23

### Dependencias
- flutter_local_notifications: ^17.2.3
- timezone: ^0.9.2
- workmanager: ^0.7.0

### Permisos Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```

### Inicialización
```dart
await NotificationService.initialize();
```

### Programación
```dart
await NotificationService.scheduleOrderNotifications(orden);
```
