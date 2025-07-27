import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'app_state/app_state.dart';
import 'models/models.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'utils/utils.dart';


import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'services/supabase_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase (crítico)
  await Supabase.initialize(
    url: 'https://umyxvmnnnqhejzpdzcgc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVteXh2bW5ubnFoZWp6cGR6Y2djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNjk3MzUsImV4cCI6MjA2ODk0NTczNX0.rNvdbFz02Bq-VUkQy0VqWtaHPx4xi4pR8BIW4_OAn_s',
  );

  // Crear AppState básico
  final appState = AppState();

  // Ejecutar la app INMEDIATAMENTE
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const CotizadorApp(),
    ),
  );

  // Inicializar todo lo demás después del runApp
  _initializeEverythingElse(appState);
}

// Inicializar todo lo demás después del runApp
Future<void> _initializeEverythingElse(AppState appState) async {
  print('🚀 Iniciando inicialización completa...');
  
  // Inicializar Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TrabajoAdapter());
  Hive.registerAdapter(ClienteAdapter());
  Hive.registerAdapter(UsuarioAdapter());
  Hive.registerAdapter(OrdenTrabajoTrabajoAdapter());
  Hive.registerAdapter(OrdenHistorialAdapter());
  Hive.registerAdapter(OrdenTrabajoAdapter());
  Hive.registerAdapter(ArchivoAdjuntoAdapter());
  Hive.registerAdapter(TimeOfDayAdapter());

  // Abrir boxes
  await Hive.openBox<Trabajo>('trabajos');
  await Hive.openBox<Cliente>('clientes');
  await Hive.openBox<Usuario>('usuarios');
  await Hive.openBox<OrdenTrabajo>('ordenes');

  // Inicializar AppState
  await appState.init();

  // Configurar listeners de autenticación
  _setupAuthListeners(appState);

  // Inicializar servicios no críticos
  await _initializeNonCriticalServices();
  
  print('✅ Inicialización completa terminada');
}

// Configurar listeners de autenticación
void _setupAuthListeners(AppState appState) {
  // Listener unificado para cambios de autenticación
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    final session = data.session;
    final user = session?.user;
    
    print('🔄 Cambio de estado de auth: $event');
    
    // Manejar cierre de sesión y expiración
    if (event == AuthChangeEvent.signedOut || 
        event == AuthChangeEvent.userDeleted ||
        session == null || 
        user == null) {
      
      print('❌ Sesión cerrada/expirada');
      
      // Solo actualizar estado si había un usuario activo
      if (appState.currentUser != null) {
        appState.logout();
        
        // Navegar al login
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
        
        // Mostrar mensaje con el sistema moderno de feedback
        final context = navigatorKey.currentContext;
        if (context != null) {
          // Usar un delay para asegurar que la navegación esté completa
          Future.delayed(Duration(milliseconds: 500), () {
            if (navigatorKey.currentContext != null) {
              AppFeedback.showInfo(
                navigatorKey.currentContext!,
                'Sesión cerrada correctamente',
              );
            }
          });
        }
      }
    } else {
      print('✅ Sesión activa detectada');
    }
  });
}

// Inicializar servicios no críticos
Future<void> _initializeNonCriticalServices() async {
  // Inicializar timezone
  tz.initializeTimeZones();
  await _initializeTimezone();

  // Inicializar formato de fecha
  await initializeDateFormatting('es_ES', null);

  // Inicializar sistema de notificaciones
  await NotificationService.initialize();
}

/// Inicializa el timezone del dispositivo automáticamente
Future<void> _initializeTimezone() async {
  try {
    // Obtener la zona horaria del dispositivo
    final String deviceTimezone = DateTime.now().timeZoneName;
    print('🌍 Timezone del dispositivo: $deviceTimezone');
    
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
        'GFT': 'America/Cayenne',
        'SRT': 'America/Paramaribo',
        'GMT': 'UTC',
        'UTC': 'UTC',
      };
      
      // Primero intentar usar el timezone mapeado
      if (timezoneMap.containsKey(deviceTimezone)) {
        final location = tz.getLocation(timezoneMap[deviceTimezone]!);
        tz.setLocalLocation(location);
        print('✅ Timezone configurado: ${timezoneMap[deviceTimezone]}');
        return;
      }
      
      // Si no está mapeado, intentar detectar automáticamente
      // Usar el offset del dispositivo para encontrar la zona horaria apropiada
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      
      // Mapear offsets comunes a zonas horarias
      final String timezoneId = _getTimezoneFromOffset(offset);
      final location = tz.getLocation(timezoneId);
      tz.setLocalLocation(location);
      print('✅ Timezone configurado automáticamente: $timezoneId (offset: ${offset.inHours}h)');
      
    } catch (e) {
      print('⚠️ Error configurando timezone específico: $e');
      
      // Fallback: usar UTC como zona horaria segura
      tz.setLocalLocation(tz.getLocation('UTC'));
      print('✅ Timezone fallback configurado: UTC');
    }
    
  } catch (e) {
    print('❌ Error inicializando timezone: $e');
    
    // Fallback final: UTC
    tz.setLocalLocation(tz.getLocation('UTC'));
    print('✅ Timezone fallback final configurado: UTC');
  }
}

/// Obtiene la zona horaria basada en el offset del dispositivo
String _getTimezoneFromOffset(Duration offset) {
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

class CotizadorApp extends StatefulWidget {
  const CotizadorApp({super.key});

  @override
  State<CotizadorApp> createState() => _CotizadorAppState();
}

class _CotizadorAppState extends State<CotizadorApp> 
    with SingleTickerProviderStateMixin {
  late AnimationController _themeAnimationController;
  
  @override
  void initState() {
    super.initState();
    _themeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _themeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return AnimatedBuilder(
          animation: _themeAnimationController,
          builder: (context, child) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Cotizador Pro',
              theme: _buildLightTheme(),
              darkTheme: _buildDarkTheme(),
              themeMode: appState.themeMode,
              themeAnimationDuration: const Duration(milliseconds: 300),
              themeAnimationCurve: Curves.easeInOut,
              home: const SplashScreen(),
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('es', 'ES'),
              ],
              locale: const Locale('es', 'ES'),
            );
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    const primaryColor = Color(0xFF0AE98A);
    const secondaryColor = Color(0xFF1292EE);
    const backgroundColor = Colors.white;
    const surfaceColor = Color(0xFFF9FAFB);
    const cardColor = Colors.white;
    const textColor = Color(0xFF1A1D29);
    const subtitleColor = Color(0xFF6B7280);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onPrimary: textColor,
        onSecondary: Colors.white,
        onSurface: textColor,
        background: backgroundColor,
        onBackground: textColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        shadowColor: Colors.black12,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        surfaceTintColor: Colors.transparent,
      ),
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: surfaceColor,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: subtitleColor),
        hintStyle: const TextStyle(color: subtitleColor),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        labelStyle: const TextStyle(color: textColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF9CA3AF),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: subtitleColor,
        thickness: 1,
        space: 1,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFF0AE98A);
    const secondaryColor = Color(0xFF1292EE);
    const backgroundColor = Color(0xFF0F1419);
    const surfaceColor = Color(0xFF1A1D23);
    const surfaceVariantColor = Color(0xFF2A2D36);
    const cardColor = Color(0xFF1A1D23);
    const textColor = Color(0xFFF8F9FA);
    const subtitleColor = Color(0xFF9CA3AF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        surfaceVariant: surfaceVariantColor,
        onPrimary: backgroundColor,
        onSecondary: Colors.white,
        onSurface: textColor,
        onSurfaceVariant: subtitleColor,
        background: backgroundColor,
        onBackground: textColor,
        outline: const Color(0xFF404756),
        shadow: Colors.black.withOpacity(0.3),
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        shadowColor: Colors.black12,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF404756), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: surfaceColor,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: subtitleColor),
        hintStyle: const TextStyle(color: subtitleColor),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: backgroundColor,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        labelStyle: const TextStyle(color: textColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: subtitleColor,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: subtitleColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
}