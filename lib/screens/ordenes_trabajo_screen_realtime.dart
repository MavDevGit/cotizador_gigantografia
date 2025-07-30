import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

class OrdenesTrabajoScreenRealtime extends StatefulWidget {
  const OrdenesTrabajoScreenRealtime({super.key});

  @override
  _OrdenesTrabajoScreenRealtimeState createState() => _OrdenesTrabajoScreenRealtimeState();
}

class _OrdenesTrabajoScreenRealtimeState extends State<OrdenesTrabajoScreenRealtime> 
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFilter;
  bool _isLoading = false;
  Timer? _debounceTimer;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Datos locales
  List<OrdenTrabajo>? _ordenesData;
  
  // Set para rastrear órdenes eliminadas localmente
  final Set<String> _deletedOrderIds = <String>{};
  
  // Subscription de Realtime
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.defaultCurve,
    ));
    
    _searchController.addListener(() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text;
          });
        }
      });
    });
    
    // Cargar datos iniciales
    _loadInitialData();
    
    // Configurar Realtime
    _setupRealtime();
    
    _animationController.forward();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final ordenes = await appState.ordenes;
      
      if (mounted) {
        setState(() {
          _ordenesData = ordenes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtime() {
    final supabase = Supabase.instance.client;
    
    _realtimeChannel = supabase
        .channel('ordenes_trabajo_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ordenes_trabajo',
          callback: _handleRealtimeEvent,
        )
        .subscribe();
    
    print('🔴 Realtime configurado para tabla ordenes_trabajo');
  }

  void _handleRealtimeEvent(PostgresChangePayload payload) {
    print('🔴 Evento Realtime recibido: ${payload.eventType}');
    
    if (!mounted) return;
    
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _handleInsert(payload.newRecord);
        break;
      case PostgresChangeEvent.update:
        _handleUpdate(payload.newRecord);
        break;
      case PostgresChangeEvent.delete:
        _handleDelete(payload.oldRecord);
        break;
    }
  }

  void _handleInsert(Map<String, dynamic> record) {
    try {
      // Convertir el record a OrdenTrabajo
      // Nota: Necesitarás adaptar esto según tu estructura de datos
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Recargar datos para obtener la nueva orden con todas las relaciones
      _refreshData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nueva orden añadida'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error procesando inserción: $e');
    }
  }

  void _handleUpdate(Map<String, dynamic> record) {
    try {
      final orderId = record['id'] as String;
      
      if (_ordenesData != null) {
        final index = _ordenesData!.indexWhere((o) => o.id == orderId);
        
        if (index != -1) {
          // Recargar datos para obtener la orden actualizada con todas las relaciones
          _refreshData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Orden ${orderId.substring(0, 8)} actualizada'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error procesando actualización: $e');
    }
  }

  void _handleDelete(Map<String, dynamic> record) {
    try {
      final orderId = record['id'] as String;
      
      if (_ordenesData != null) {
        setState(() {
          _ordenesData!.removeWhere((o) => o.id == orderId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Orden ${orderId.substring(0, 8)} eliminada'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error procesando eliminación: $e');
    }
  }

  Future<void> _refreshData() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.clearOrdenesCache(); // Limpiar cache
      final ordenes = await appState.ordenes;
      
      if (mounted) {
        setState(() {
          _ordenesData = ordenes;
        });
      }
    } catch (e) {
      print('❌ Error refrescando datos: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    
    // Limpiar subscription de Realtime
    _realtimeChannel?.unsubscribe();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _ordenesData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return _buildScaffoldWithData(context, _ordenesData ?? []);
  }

  Widget _buildScaffoldWithData(BuildContext context, List<OrdenTrabajo> ordenesData) {
    // Filtrar órdenes eliminadas localmente
    var ordenes = ordenesData.where((orden) => !_deletedOrderIds.contains(orden.id)).where((orden) {
      final searchLower = _searchQuery.toLowerCase();
      return orden.cliente.nombre.toLowerCase().contains(searchLower) ||
             orden.id.toLowerCase().contains(searchLower) ||
             (orden.notas?.toLowerCase().contains(searchLower) ?? false);
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
        case 'entregado':
          ordenes = ordenes.where((o) => o.estado == 'entregado').toList();
          break;
        case 'por_entregar':
          ordenes = ordenes.where((o) => o.estado == 'terminado').toList();
          break;
      }
    }

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              // Stats cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _buildStatsCards(ordenesData),
                ),
              ),
              
              // Indicador de Realtime activo
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Actualización en tiempo real activa',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
              
              // Search bar y filtros (mantener igual que en la versión original)
              // ... resto del código igual
              
              // Orders list
              if (ordenes.isEmpty)
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No hay órdenes de trabajo',
                    subtitle: 'Las órdenes que crees aparecerán aquí',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final orden = ordenes[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: _buildOrderCard(orden),
                      );
                    },
                    childCount: ordenes.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(List<OrdenTrabajo> ordenes) {
    final pendientes = ordenes.where((o) => o.estado == 'pendiente').length;
    final enProceso = ordenes.where((o) => o.estado == 'en_proceso').length;
    final terminadas = ordenes.where((o) => o.estado == 'terminado').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Pendientes', pendientes.toString(), AppColors.getWarning(context)),
        ),
        AppSpacing.horizontalSM,
        Expanded(
          child: _buildStatCard('En Proceso', enProceso.toString(), AppColors.getInfo(context)),
        ),
        AppSpacing.horizontalSM,
        Expanded(
          child: _buildStatCard('Terminadas', terminadas.toString(), AppColors.getSuccess(context)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return AppCard(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.heading2(context).copyWith(color: color),
          ),
          AppSpacing.verticalXS,
          Text(
            title,
            style: AppTextStyles.caption(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrdenTrabajo orden) {
    return AppCard(
      isClickable: true,
      onTap: () async {
        AppFeedback.hapticFeedback(HapticType.light);
        
        // Con Realtime, no necesitas refresh manual!
        // Los cambios se actualizarán automáticamente
        await AppNavigator.push(
          context,
          OrdenDetalleScreen(orden: orden),
          type: TransitionType.slide,
        );
        
        // ¡No más código de refresh! Realtime se encarga de todo
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... resto del diseño de tarjeta igual que antes
          Text(
            orden.cliente.nombre,
            style: AppTextStyles.subtitle1(context),
          ),
          Text(
            'Orden #${orden.id.substring(0, 8)}',
            style: AppTextStyles.caption(context),
          ),
          // ... etc
        ],
      ),
    );
  }
}
