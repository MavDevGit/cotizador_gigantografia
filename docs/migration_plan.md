# 📋 Plan de Migración Completa: Hive → Supabase

## 🎯 Resumen del Plan

Este documento describe el plan completo para migrar el sistema "Cotizador Gigantografía" de Hive (base de datos local) a Supabase (base de datos en la nube) manteniendo la funcionalidad existente durante la transición.

## 📂 Archivos Creados/Modificados

### ✅ Nuevos Modelos (Supabase)
- `lib/models/cliente_new.dart` - Modelo Cliente adaptado para Supabase
- `lib/models/trabajo_new.dart` - Modelo Trabajo adaptado para Supabase  
- `lib/models/usuario_new.dart` - Modelo Usuario adaptado para Supabase
- `lib/models/orden_trabajo_new.dart` - Modelo OrdenTrabajo adaptado para Supabase
- `lib/models/orden_trabajo_item_new.dart` - Modelo para ítems de órdenes

### ✅ Servicios y Adaptadores
- `lib/services/supabase_service.dart` - ⚡ **AMPLIADO** - Servicio completo para CRUD con Supabase
- `lib/adapters/model_adapters.dart` - Adaptadores para convertir entre modelos Hive y Supabase
- `lib/services/migration_service.dart` - Servicio para ejecutar la migración de datos
- `lib/app_state/app_state_new.dart` - Nuevo AppState que utiliza Supabase

### ✅ Interfaz de Usuario
- `lib/screens/migration_screen.dart` - Pantalla para ejecutar la migración
- `lib/screens/main_screen.dart` - ⚡ **MODIFICADO** - Agregada opción de migración en drawer

### ✅ Configuración
- `pubspec.yaml` - ⚡ **MODIFICADO** - Eliminadas dependencias de Hive, agregada uuid
- `lib/main.dart` - ⚡ **MODIFICADO** - Sistema híbrido Hive/Supabase durante transición
- `docs/supabase_setup.md` - Documentación completa para configurar Supabase

## 🚀 Pasos para Implementar

### 1. Configurar Supabase (⚠️ CRÍTICO)

**Ejecutar en Supabase SQL Editor:**

```sql
-- 1. Crear enum para roles
CREATE TYPE rol_usuario AS ENUM ('admin', 'empleado');

-- 2. Crear todas las tablas (ver docs/supabase_setup.md)
-- 3. Activar RLS y crear políticas (ver docs/supabase_setup.md)
-- 4. Crear funciones RPC (ver docs/supabase_setup.md)
```

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Proceso de Migración

#### Opción A: Migración Manual (Recomendada)
1. **Usuario Admin accede a "Migrar a la Nube"** en el drawer
2. **Ejecuta la migración** desde la pantalla dedicada
3. **Reinicia la aplicación** cuando se complete
4. **La app automáticamente usa Supabase** después del reinicio

#### Opción B: Migración Programática
```dart
// Cambiar esta variable en main.dart cuando quieras forzar Supabase
bool _useSupabaseAppState = true; // Cambiar de false a true
```

### 4. Verificación Post-Migración

1. ✅ Verificar que los datos aparecen correctamente
2. ✅ Probar crear/editar/eliminar clientes
3. ✅ Probar crear/editar/eliminar trabajos (solo admin)
4. ✅ Probar crear/editar órdenes de trabajo
5. ✅ Verificar que RLS funciona (usuarios solo ven datos de su empresa)

## 🔧 Características Implementadas

### ✅ Sistema Híbrido
- La aplicación detecta automáticamente si usar Hive o Supabase
- Transición transparente sin romper funcionalidad existente
- Sistema de cache para mejorar rendimiento con Supabase

### ✅ Migración de Datos
- Migración automática de clientes, trabajos y órdenes
- Preservación de relaciones entre entidades
- Sistema de logs para monitorear el progreso
- Manejo de errores robusto

### ✅ Compatibilidad
- Los modelos nuevos mantienen compatibilidad con código existente
- Adaptadores automáticos entre formatos Hive y Supabase
- Getters de compatibilidad para propiedades renombradas

### ✅ Seguridad
- Row Level Security (RLS) implementado
- Aislamiento completo de datos entre empresas
- Restricciones de rol para gestión de trabajos

## ⚡ Mejoras Adicionales Implementadas

### 1. **Funciones RPC para Transacciones**
```sql
-- Crear órdenes con ítems de forma atómica
SELECT crear_orden_con_items(cliente_id, items_json, ...);

-- Obtener órdenes con todos los detalles
SELECT * FROM obtener_ordenes_completas();
```

### 2. **Sistema de Cache Inteligente**
- Cache automático de datos de Supabase
- Invalidación selectiva de cache
- Mejora significativa en rendimiento

### 3. **Interfaz de Migración Amigable**
- Progreso en tiempo real
- Logs detallados de la migración
- Manejo visual de errores
- Estadísticas de datos a migrar

### 4. **Orden Personalizado de Trabajos**
- Preservación del orden personalizado durante la migración
- Sistema de reordenamiento mantenido en Supabase

## 🎛️ Configuración de Variables

### Archivo: `lib/main.dart`
```dart
// Variable para controlar el estado de migración
bool _useSupabaseAppState = false; // Cambia automáticamente después de migración
```

### SharedPreferences
```dart
// Clave para marcar migración completada
'migration_completed': true/false
```

## 📊 Estructura de Base de Datos

### Tablas Principales
- **empresas** - Información de empresas
- **usuarios** - Perfiles de usuario vinculados a auth.users
- **clientes** - Clientes por empresa (con RLS)
- **trabajos** - Catálogo de servicios por empresa (con RLS)
- **ordenes_trabajo** - Órdenes principales (con RLS)
- **orden_trabajo_items** - Ítems/trabajos dentro de cada orden

### Políticas RLS
- ✅ **Aislamiento por empresa**: Usuarios solo ven datos de su empresa
- ✅ **Control de roles**: Solo admins pueden gestionar trabajos
- ✅ **Seguridad de cascada**: Ítems heredan permisos de sus órdenes

## 🚨 Puntos Críticos

### ⚠️ ANTES DE MIGRAR
1. **Configurar completamente Supabase** con todas las tablas y políticas
2. **Verificar conectividad** a internet estable
3. **Hacer backup** de datos actuales (automático en la migración)

### ⚠️ DURANTE LA MIGRACIÓN
1. **No cerrar la aplicación** durante el proceso
2. **Mantener conexión estable** a internet
3. **Revisar logs** por posibles errores

### ⚠️ DESPUÉS DE LA MIGRACIÓN
1. **Reiniciar la aplicación** para activar Supabase
2. **Verificar datos** en todas las pantallas
3. **Probar funcionalidades críticas** (crear/editar/eliminar)

## 🎉 Beneficios Obtenidos

### 🌐 **Sincronización Multi-dispositivo**
- Datos accesibles desde cualquier dispositivo
- Actualizaciones en tiempo real
- Backup automático en la nube

### 🏢 **Multi-empresa Seguro**
- Aislamiento completo de datos entre empresas
- Gestión de usuarios y roles centralizada
- Escalabilidad para múltiples empresas

### ⚡ **Rendimiento Mejorado**
- Sistema de cache inteligente
- Consultas optimizadas con índices
- Funciones RPC para operaciones complejas

### 🔒 **Seguridad Empresarial**
- Autenticación robusta con Supabase Auth
- Políticas de seguridad a nivel de base de datos
- Control granular de permisos

## 📞 Siguiente Pasos

1. **Ejecutar configuración de Supabase** (docs/supabase_setup.md)
2. **Probar migración en entorno de desarrollo**
3. **Ejecutar migración en producción**
4. **Verificar funcionamiento completo**
5. **Opcional: Remover código de Hive** una vez confirmada la migración

---

**💡 Nota:** Este sistema mantiene compatibilidad completa durante la transición, permitiendo rollback si es necesario. La migración es segura y reversible hasta que se decida eliminar definitivamente el código de Hive.
