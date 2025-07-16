import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// You need to generate these files with 'flutter pub run build_runner build'
part 'main.g.dart';

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
  });
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

  AppState() {
    // Initialization is now async and happens in main()
  }

  Future<void> init() async {
    _clientesBox = Hive.box<Cliente>('clientes');
    _trabajosBox = Hive.box<Trabajo>('trabajos');
    _ordenesBox = Hive.box<OrdenTrabajo>('ordenes');
    _usuariosBox = Hive.box<Usuario>('usuarios');
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
    notifyListeners();
  }
  
  Future<void> updateOrden(OrdenTrabajo orden, String cambio) async {
    orden.historial.add(OrdenHistorial(
      id: Random().nextDouble().toString(),
      cambio: cambio,
      usuarioId: _currentUser!.id,
      usuarioNombre: _currentUser!.nombre,
      timestamp: DateTime.now(),
    ));
    
    // Ensure the order is saved to Hive
    await _ordenesBox.put(orden.id, orden);
    notifyListeners();
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

  double get _subtotalActual => _trabajoSeleccionado != null
      ? (_ancho * _alto * _trabajoSeleccionado!.precioM2 * _cantidad) + _adicional
      : 0.0;

  double get _totalOrden {
      double sum = _trabajosEnOrden.fold(0.0, (prev, item) => prev + item.precioFinal);
      final totalPersonalizado = double.tryParse(_totalPersonalizadoController.text);
      if (totalPersonalizado != null) return totalPersonalizado;
      return sum;
  }
  
  void _addTrabajoAOrden() {
    if (_trabajoSeleccionado != null) {
      setState(() {
        _trabajosEnOrden.add(OrdenTrabajoTrabajo(
          id: Random().nextDouble().toString(),
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
            
            // Botón de archivos
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text("Adjuntar Archivos"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Funcionalidad no implementada.")),
                );
              },
            ),
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
      creadoPorUsuarioId: widget.orden.creadoPorUsuarioId
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
      widget.orden.cliente = _ordenEditable.cliente;
      widget.orden.trabajos = _ordenEditable.trabajos;
      widget.orden.adelanto = _ordenEditable.adelanto;
      widget.orden.totalPersonalizado = _ordenEditable.totalPersonalizado;
      widget.orden.notas = _ordenEditable.notas;
      widget.orden.estado = _ordenEditable.estado;
      widget.orden.fechaEntrega = _ordenEditable.fechaEntrega;
      widget.orden.horaEntrega = _ordenEditable.horaEntrega;
      
      Provider.of<AppState>(context, listen: false).updateOrden(widget.orden, "Orden actualizada.");
      Navigator.pop(context, true); // Return true to indicate changes were made
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
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: (){
                 // TODO: Implement PDF generation using a package like 'pdf' and 'printing'.
                 // This would gather the data from _ordenEditable and format it into a PDF document.
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Funcionalidad de exportar a PDF no implementada.")));
              },
              tooltip: "Exportar a PDF",
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
