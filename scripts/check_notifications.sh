#!/bin/bash

# Script de prueba para verificar el sistema de notificaciones
echo "🔍 Verificando sistema de notificaciones..."

# Verificar que el dispositivo esté conectado
adb devices

# Verificar permisos de notificación
echo "📱 Verificando permisos de notificación..."
adb shell dumpsys notification | grep -i "notification access"

# Verificar alarmas programadas
echo "⏰ Verificando alarmas programadas..."
adb shell dumpsys alarm | grep -i "cotizador"

# Verificar configuración de batería
echo "🔋 Verificando optimización de batería..."
adb shell dumpsys deviceidle whitelist | grep -i "cotizador"

# Verificar notificaciones activas
echo "🔔 Verificando notificaciones activas..."
adb shell dumpsys notification | grep -i "posted"

echo "✅ Verificación completada"
