# Cotizador Gigantografía

Aplicación Flutter para gestión de órdenes de trabajo de gigantografías.

## 🚀 Características

- ✅ Gestión de clientes
- ✅ Catálogo de trabajos
- ✅ Órdenes de trabajo con cálculos automáticos
- ✅ Generación de PDFs
- ✅ Base de datos Supabase
- ✅ Multi-empresa (cada empresa ve solo sus datos)

## 🛠️ Setup

### 1. Dependencias
```bash
flutter pub get
```

### 2. Configurar Supabase
1. Ve a tu proyecto Supabase Dashboard
2. SQL Editor → Pega el contenido de `fix_rls_simple.sql`
3. Ejecutar para habilitar RLS

### 3. Ejecutar
```bash
flutter run
```

## 📱 Pantallas

- **Dashboard**: Resumen de estadísticas
- **Clientes**: Gestión de clientes
- **Trabajos**: Catálogo de servicios
- **Órdenes**: Crear y gestionar órdenes de trabajo

## 🔧 Tecnologías

- **Flutter** - UI Framework
- **Supabase** - Backend y Base de datos
- **PDF** - Generación de documentos
- **Provider** - Gestión de estado

## 🔒 Seguridad

Row Level Security (RLS) habilitado - cada empresa solo ve sus propios datos.

## 📄 Archivos Importantes

- `fix_rls_simple.sql` - SQL para habilitar RLS en Supabase
- `lib/` - Código fuente de la aplicación
- **Selectores de Fecha/Hora**: Configurados con semana iniciando el lunes

### 📱 Plataformas Soportadas
- Android
- iOS
- Web
- Windows
- macOS
- Linux

## 🛠️ Tecnologías Utilizadas

- **Flutter**: Framework de desarrollo multiplataforma
- **Dart**: Lenguaje de programación
- **Hive**: Base de datos local NoSQL
- **Provider**: Gestión de estado
- **Material Design**: Sistema de diseño
- **Intl**: Internacionalización y localización

## 🚀 Instalación

### Prerrequisitos
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Git

### Pasos para instalar

1. **Clonar el repositorio**
```bash
git clone https://github.com/MavDevGit/cotizador_gigantografia.git
cd cotizador_gigantografia
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Generar archivos de código**
```bash
flutter pub run build_runner build
```

4. **Ejecutar la aplicación**
```bash
flutter run
```

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  provider: ^6.0.5
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  hive_generator: ^2.0.1
```

## 📚 Estructura del Proyecto

```
lib/
├── main.dart                 # Archivo principal de la aplicación
├── main.g.dart              # Archivos generados por Hive
└── models/                   # Modelos de datos
    ├── cliente.dart
    ├── trabajo.dart
    ├── orden_trabajo.dart
    └── usuario.dart
```

## 🔧 Configuración

### Base de Datos
La aplicación utiliza Hive para almacenamiento local. Los datos se guardan automáticamente en:
- **Clientes**: Información de contacto y datos del cliente
- **Trabajos**: Tipos de trabajos y precios por m²
- **Órdenes**: Órdenes de trabajo completas con historial
- **Usuarios**: Sistema de autenticación local

### Localización
- Idioma: Español (es_ES)
- Formato de fecha: DD/MM/YYYY
- Moneda: Bolivianos (Bs)
- Semana inicia: Lunes

## 👥 Uso

### Primer Uso
1. Al iniciar la aplicación por primera vez, se creará un usuario administrador por defecto
2. Email: `admin@admin.com`
3. Contraseña: `admin123`

### Flujo de Trabajo
1. **Configurar Trabajos**: Definir tipos de trabajos y precios
2. **Agregar Clientes**: Registrar información de clientes
3. **Crear Cotizaciones**: Generar cotizaciones con cálculos automáticos
4. **Gestionar Órdenes**: Dar seguimiento a órdenes de trabajo
5. **Generar Reportes**: Visualizar estadísticas y reportes

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Para contribuir:

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 📧 Contacto

**MavDevGit** - [mavdevgit@gmail.com](mailto:mavdevgit@gmail.com)

Enlace del proyecto: [https://github.com/MavDevGit/cotizador_gigantografia](https://github.com/MavDevGit/cotizador_gigantografia)

---

⭐ ¡Dale una estrella si este proyecto te ha sido útil!
