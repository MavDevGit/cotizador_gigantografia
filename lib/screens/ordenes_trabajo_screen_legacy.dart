import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

class OrdenesTrabajoScreen extends StatefulWidget {
  const OrdenesTrabajoScreen({super.key});

  @override
  _OrdenesTrabajoScreenState createState() => _OrdenesTrabajoScreenState();
}

class _OrdenesTrabajoScreenState extends State<OrdenesTrabajoScreen> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFilter;
  bool _isLoading = false;
  Timer? _debounceTimer;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Memoización de datos para evitar reconstrucciones innecesarias
  List<OrdenTrabajo>? _cachedOrdenesData;
  Future<List<OrdenTrabajo>>? _memoizedFuture;
  
  // Set para rastrear órdenes eliminadas localmente
  final Set<String> _deletedOrderIds = <String>{};
  
  // Flag para detectar si acabamos de editar una orden
  bool _justEditedOrder = false;
  
  // Timestamp de la última actualización
  DateTime? _lastUpdateTime;
  
  // Retry counter para manejar errores de red
  int _retryCount = 0;
  
  // Orden específica que se está editando (para tracking)
  String? _editingOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
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
    
    // Memoizar el Future al inicializar
    final appState = Provider.of<AppState>(context, listen: false);
    _memoizedFuture = appState.ordenes;
    
    _searchController.addListener(() {
      // Cancelar el timer anterior si existe
      _debounceTimer?.cancel();
      
      // Crear un nuevo timer con retraso de 300ms
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text;
          });
        }
      });
    });
    
    _animationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Solo refrescar si la app vuelve a primer plano después de un largo tiempo
    // y si acabamos de editar una orden (como plan de emergencia)
    if (state == AppLifecycleState.resumed && _justEditedOrder && mounted) {
      print('📱 App resumed - ejecutando refresh de emergencia');
      _justEditedOrder = false;
      
      // Pequeño delay para verificar si realmente necesitamos actualizar
      Timer(const Duration(seconds: 1), () {
        if (mounted && _cachedOrdenesData != null) {
          // Solo actualizar si han pasado más de 10 segundos desde la última actualización
          final now = DateTime.now();
          final timeSinceLastUpdate = _lastUpdateTime != null 
            ? now.difference(_lastUpdateTime!).inSeconds 
            : 999;
            
          if (timeSinceLastUpdate > 10) {
            print('⏰ Ejecutando refresh de emergencia - ${timeSinceLastUpdate}s desde última actualización');
            _forceRefreshData();
          } else {
            print('⏭️ Saltando refresh - solo ${timeSinceLastUpdate}s desde última actualización');
          }
        }
      });
    }
  }

  Future<void> _forceRefreshData() async {
    if (!mounted) return;
    
    print('🔄 Forzando actualización de datos...');
    
    final appState = Provider.of<AppState>(context, listen: false);
    appState.clearOrdenesCache();
    
    setState(() {
      _isLoading = true;
      _cachedOrdenesData = null;
      _memoizedFuture = null;
    });
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      setState(() {
        _memoizedFuture = appState.ordenes;
      });
    }
  }

  // Método mejorado con retry y validación específica
  Future<void> _forceRefreshWithRetry() async {
    if (!mounted) return;
    
    const maxRetries = 3;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 Intento $attempt/$maxRetries - Refrescando datos...');
        
        final appState = Provider.of<AppState>(context, listen: false);
        appState.clearOrdenesCache();
        
        setState(() {
          _isLoading = true;
          _cachedOrdenesData = null;
          _memoizedFuture = null;
        });
        
        // Crear nuevo Future con timeout progresivo (más tiempo en cada intento)
        final timeoutDuration = Duration(seconds: 5 + (attempt * 2));
        final freshDataFuture = appState.ordenes.timeout(
          timeoutDuration,
          onTimeout: () {
            throw TimeoutException('Timeout en intento $attempt', timeoutDuration);
          },
        );
        
        setState(() {
          _memoizedFuture = freshDataFuture;
        });
        
        final freshData = await freshDataFuture;
        
        if (mounted) {
          print('✅ Datos recibidos correctamente en intento $attempt: ${freshData.length} órdenes');
          
          // Validar que los datos son consistentes
          bool dataIsValid = freshData.isNotEmpty || _cachedOrdenesData == null;
          
          if (dataIsValid) {
            setState(() {
              _cachedOrdenesData = freshData;
              _isLoading = false;
              _retryCount = 0; // Reset counter en éxito
            });
            _lastUpdateTime = DateTime.now();
            return; // Éxito, salir del loop
          } else {
            throw Exception('Datos inconsistentes recibidos');
          }
        }
        
      } catch (e) {
        print('❌ Error en intento $attempt: $e');
        
        if (attempt == maxRetries) {
          // Último intento fallido
          if (mounted) {
            setState(() {
              _isLoading = false;
              _retryCount++;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error después de $maxRetries intentos. Pull para refrescar.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Reintentar',
                  onPressed: () => _forceRefreshWithRetry(),
                ),
              ),
            );
          }
        } else {
          // Esperar antes del siguiente intento
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
  }

  Future<void> _refreshOrders() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _deletedOrderIds.clear(); // Limpiar órdenes eliminadas localmente
    });
    
    AppFeedback.hapticFeedback(HapticType.light);
    
    try {
      // Limpiar el cache y reestablecer el Future memoizado
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Limpiar cache de órdenes usando el método público
      appState.clearOrdenesCache();
      _cachedOrdenesData = null;
      _memoizedFuture = appState.ordenes; // Esto creará una nueva consulta
      
      // Esperar a que se complete la carga
      await _memoizedFuture;
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        AppFeedback.showToast(
          context,
          message: 'Órdenes actualizadas',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        AppFeedback.showToast(
          context,
          message: 'Error al actualizar órdenes',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solo escuchar cambios específicos, no todo el AppState
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Usar Future memoizado y cachear datos para evitar reconstrucciones
        _memoizedFuture ??= appState.ordenes;
        
        return FutureBuilder<List<OrdenTrabajo>>(
          future: _memoizedFuture,
          builder: (context, snapshot) {
            print('🏗️ FutureBuilder state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, isLoading: $_isLoading');
            
            // Si estamos en loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Si estamos forzando actualización, mostrar siempre el indicador
              if (_isLoading) {
                return _cachedOrdenesData != null 
                  ? _buildScaffoldWithData(context, appState, _cachedOrdenesData!, showRefreshIndicator: true)
                  : const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              // Si tenemos datos cached y NO estamos forzando actualización
              else if (_cachedOrdenesData != null) {
                return _buildScaffoldWithData(context, appState, _cachedOrdenesData!, showRefreshIndicator: false);
              } 
              // Primera carga
              else {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
            }
            
            // Manejo de errores
            if (snapshot.hasError) {
              print('❌ FutureBuilder error: ${snapshot.error}');
              
              if (_cachedOrdenesData == null) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error al cargar órdenes: ${snapshot.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _memoizedFuture = appState.ordenes;
                              _cachedOrdenesData = null;
                            });
                          },
                          child: Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // Mostrar datos cached con error
                return _buildScaffoldWithData(context, appState, _cachedOrdenesData!, showRefreshIndicator: false);
              }
            }
            
            // Datos disponibles
            if (snapshot.hasData) {
              final freshData = snapshot.data!;
              print('📊 Datos recibidos: ${freshData.length} órdenes');
              
              // SIEMPRE actualizar cache con datos frescos cuando los recibimos
              bool shouldUpdate = false;
              
              if (_cachedOrdenesData == null) {
                print('🆕 Primer conjunto de datos');
                shouldUpdate = true;
              } else if (_cachedOrdenesData!.length != freshData.length) {
                print('📊 Cambio en cantidad de órdenes: ${_cachedOrdenesData!.length} -> ${freshData.length}');
                shouldUpdate = true;
              } else {
                // Verificación detallada de cambios
                for (int i = 0; i < freshData.length; i++) {
                  final fresh = freshData[i];
                  final cached = _cachedOrdenesData![i];
                  
                  if (fresh.id != cached.id ||
                      fresh.total != cached.total ||
                      fresh.trabajos.length != cached.trabajos.length ||
                      fresh.estado != cached.estado) {
                    print('🔄 Detectado cambio en orden ${fresh.id}');
                    shouldUpdate = true;
                    break;
                  }
                }
              }
              
              if (shouldUpdate || _isLoading) {
                print('✅ Actualizando cache y UI');
                
                // Actualizar inmediatamente sin delays innecesarios
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _cachedOrdenesData = freshData;
                      _isLoading = false;
                    });
                  }
                });
              } else if (_isLoading) {
                // Solo limpiar loading flag si no hay cambios pero estamos cargando
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              }
            }
            
            // Usar siempre datos del snapshot si están disponibles, sino usar cache
            final ordenesData = snapshot.data ?? _cachedOrdenesData ?? [];
            return _buildScaffoldWithData(context, appState, ordenesData, showRefreshIndicator: _isLoading);
          },
        );
      },
    );
  }

  Widget _buildScaffoldWithData(BuildContext context, AppState appState, List<OrdenTrabajo> ordenesData, {bool showRefreshIndicator = false}) {
    // Filtrar órdenes eliminadas localmente
    var ordenes = ordenesData.where((orden) => !_deletedOrderIds.contains(orden.id)).where((orden) {
      // Mejorar búsqueda: buscar en nombre del cliente, ID de orden y notas
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
          // Órdenes terminadas pero no entregadas
          ordenes = ordenes
              .where((o) => o.estado == 'terminado')
              .toList();
          break;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _refreshOrders,
              child: CustomScrollView(
                slivers: [
                  // Stats cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: _buildStatsCards(ordenesData),
                    ),
                  ),
                  
                  // Filter chips
                  if (_selectedFilter != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppButton(
                              text: 'Limpiar filtros',
                              icon: Icons.clear_rounded,
                              onPressed: () {
                                setState(() {
                                  _selectedFilter = null;
                                });
                                AppFeedback.hapticFeedback(HapticType.selection);
                              },
                              type: ButtonType.text,
                              size: ButtonSize.small,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Search bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: AppTextField(
                        controller: _searchController,
                        label: 'Buscar órdenes',
                        hint: 'Buscar por cliente, ID de orden o notas...',
                        prefixIcon: Icons.search_rounded,
                        suffixIcon: _searchQuery.isNotEmpty ? Icons.clear : null,
                        onSuffixTap: _searchQuery.isNotEmpty ? () {
                          _searchController.clear();
                          AppFeedback.hapticFeedback(HapticType.selection);
                        } : null,
                      ),
                    ),
                  ),
                  
                  // Filter chips
                  SliverToBoxAdapter(
                    child: _buildFilterChips(),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                  
                  // Orders list
                  if (ordenes.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final orden = ordenes[index];
                          return DelayedAnimation(
                            delay: index * 50,
                            type: AnimationType.slideUp,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              child: Dismissible(
                                key: Key(orden.id),
                                direction: DismissDirection.endToStart,
                                background: _buildDismissBackground(),
                                confirmDismiss: (direction) async {
                                  final shouldDelete = await _confirmDelete(orden);
                                  if (shouldDelete) {
                                    try {
                                      // Agregar la orden a la lista de eliminados localmente inmediatamente
                                      setState(() {
                                        _deletedOrderIds.add(orden.id);
                                      });
                                      
                                      // Eliminar de la base de datos en segundo plano
                                      await appState.deleteOrden(orden.id);
                                      
                                      // Feedback de éxito
                                      if (mounted) {
                                        AppFeedback.hapticFeedback(HapticType.medium);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Orden eliminada exitosamente'),
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Remover de la lista de eliminados si hubo error
                                      setState(() {
                                        _deletedOrderIds.remove(orden.id);
                                      });
                                      
                                      // Manejar errores
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error al eliminar orden: $e'),
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                      return false; // No eliminar el widget si hubo error
                                    }
                                  }
                                  return shouldDelete;
                                },
                                child: _buildOrderCard(orden, appState),
                              ),
                            ),
                          );
                        },
                        childCount: ordenes.length,
                      ),
                    ),
                  
                  // Bottom spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl),
                  ),
                ],
              ),
            ),
          ),
          
          // Indicador sutil de actualización
          if (showRefreshIndicator)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
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
            style: AppTextStyles.heading2(context).copyWith(
              color: color,
            ),
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

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _buildFilterChip('Todas', null),
          _buildFilterChip('Pendientes', 'pendiente'),
          _buildFilterChip('En Proceso', 'en_proceso'),
          _buildFilterChip('Terminadas', 'terminado'),
          _buildFilterChip('Entregadas', 'entregado'),
          _buildFilterChip('Por Entregar', 'por_entregar'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? filterValue) {
    final isSelected = _selectedFilter == filterValue;
    
    return AppStatusChip(
      label: label,
      status: isSelected ? StatusType.info : StatusType.neutral,
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });
        AppFeedback.hapticFeedback(HapticType.selection);
      },
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_rounded,
            color: Colors.white,
            size: AppConstants.iconSizeLarge,
          ),
          AppSpacing.verticalXS,
          Text(
            'Eliminar',
            style: AppTextStyles.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(OrdenTrabajo orden) async {
    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: 'Eliminar orden',
      message: '¿Estás seguro de que deseas eliminar la orden de ${orden.cliente.nombre}?',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmColor: AppColors.getError(context),
      icon: Icons.delete_rounded,
    );
    
    return confirmed ?? false;
  }

  Widget _buildOrderCard(OrdenTrabajo orden, AppState appState) {
    final theme = Theme.of(context);
    final total = orden.total;
    
    return AppCard(
      isClickable: true,
      onTap: () async {
        AppFeedback.hapticFeedback(HapticType.light);
        
        // Guardar estado antes de navegar
        final oldTotal = orden.total;
        final oldTrabajosCount = orden.trabajos.length;
        _editingOrderId = orden.id; // Trackear qué orden se está editando
        
        await AppNavigator.push(
          context,
          OrdenDetalleScreen(orden: orden),
          type: TransitionType.slide,
        );
        
          // SIEMPRE forzar actualización al regresar de la pantalla de detalle
          if (mounted) {
            print('🔄 Regresando de editar orden ${_editingOrderId}');
            
            _justEditedOrder = true;
            
            // Mostrar indicador de carga inmediatamente
            setState(() {
              _isLoading = true;
            });
            
            // Limpiar TODOS los caches de forma agresiva
            final appState = Provider.of<AppState>(context, listen: false);
            appState.clearOrdenesCache();
            
            // Esperar un momento para que los cambios se propaguen en Supabase
            await Future.delayed(const Duration(milliseconds: 300));
            
            // Usar el método mejorado con retry
            try {
              await _forceRefreshWithRetry();
              
              if (mounted) {
                _justEditedOrder = false;
                
                // Verificar cambios específicamente en la orden editada
                final freshData = _cachedOrdenesData ?? [];
                final updatedOrder = freshData.firstWhere(
                  (o) => o.id == _editingOrderId,
                  orElse: () => orden,
                );
                
                bool hasChanges = updatedOrder.total != oldTotal || 
                                updatedOrder.trabajos.length != oldTrabajosCount;
                
                print(hasChanges 
                  ? '✅ Cambios confirmados en orden ${_editingOrderId}' 
                  : 'ℹ️ Sin cambios detectados en orden ${_editingOrderId}');
                
                // Mostrar feedback apropiado
                if (hasChanges) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Orden actualizada: ${updatedOrder.trabajos.length} trabajos, Bs ${updatedOrder.total.toStringAsFixed(2)}'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
                
                _editingOrderId = null; // Limpiar tracking
              }
            } catch (e) {
              print('❌ Error completo al refrescar orden ${_editingOrderId}: $e');
              if (mounted) {
                _justEditedOrder = false;
                _editingOrderId = null;
                setState(() {
                  _isLoading = false;
                });
              }
            }
          }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con cliente y estado
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orden.cliente.nombre,
                      style: AppTextStyles.subtitle1(context),
                    ),
                    AppSpacing.verticalXS,
                    Text(
                      'Orden #${orden.id.substring(0, 8)}',
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
              AppStatusChip(
                label: _getStatusLabel(orden.estado),
                status: _getStatusType(orden.estado),
                icon: _getStatusIcon(orden.estado),
              ),
            ],
          ),
          
          AppSpacing.verticalMD,
          
          // Información de la orden
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.work_rounded,
                  label: 'Trabajos',
                  value: '${orden.trabajos.length}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.attach_money_rounded,
                  label: 'Total',
                  value: 'Bs ${total.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          
          AppSpacing.verticalSM,
          
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Entrega',
                  value: DateTimeUtils.formatDate(orden.fechaEntrega),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.access_time_rounded,
                  label: 'Hora',
                  value: DateTimeUtils.formatTime(orden.horaEntrega),
                ),
              ),
            ],
          ),
          
          if (orden.notas != null) ...[
            AppSpacing.verticalMD,
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note_rounded,
                    size: AppConstants.iconSizeSmall,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.horizontalSM,
                  Expanded(
                    child: Text(
                      orden.notas!,
                      style: AppTextStyles.caption(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: AppConstants.iconSizeSmall,
          color: theme.colorScheme.primary,
        ),
        AppSpacing.horizontalSM,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption(context),
              ),
              Text(
                value,
                style: AppTextStyles.body2(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.pending_rounded;
      case 'en_proceso':
        return Icons.build_rounded;
      case 'terminado':
        return Icons.check_circle_rounded;
      case 'entregado':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getStatusLabel(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En Proceso';
      case 'terminado':
        return 'Terminado';
      case 'entregado':
        return 'Entregado';
      default:
        return 'Desconocido';
    }
  }

  StatusType _getStatusType(String estado) {
    switch (estado) {
      case 'pendiente':
        return StatusType.warning;
      case 'en_proceso':
        return StatusType.info;
      case 'terminado':
        return StatusType.success;
      case 'entregado':
        return StatusType.success;
      default:
        return StatusType.neutral;
    }
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.assignment_outlined,
      title: 'No hay órdenes de trabajo',
      subtitle: 'Las órdenes que crees aparecerán aquí',
    );
  }
}
