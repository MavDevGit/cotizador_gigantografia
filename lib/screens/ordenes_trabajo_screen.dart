import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../app_state/app_state.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

class OrdenesTrabajoScreen extends StatefulWidget {
  const OrdenesTrabajoScreen({super.key});

  @override
  _OrdenesTrabajoScreenState createState() => _OrdenesTrabajoScreenState();
}

class _OrdenesTrabajoScreenState extends State<OrdenesTrabajoScreen> 
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFilter;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrders() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    AppFeedback.hapticFeedback(HapticType.light);
    
    await Future.delayed(const Duration(milliseconds: 1200));
    
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
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    var ordenes = appState.ordenes.where((orden) {
      return orden.cliente.nombre
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
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
          ordenes = ordenes
              .where((o) => o.estado == 'terminado' && o.estado != 'entregado')
              .toList();
          break;
      }
    }

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshOrders,
          child: CustomScrollView(
            slivers: [
              // Stats cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _buildStatsCards(appState.ordenes),
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
                    hint: 'Buscar por cliente...',
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
                            confirmDismiss: (direction) => _confirmDelete(orden),
                            onDismissed: (direction) {
                              appState.deleteOrden(orden.id);
                              AppFeedback.hapticFeedback(HapticType.medium);
                              AppFeedback.showToast(
                                context,
                                message: 'Orden eliminada',
                                type: ToastType.info,
                              );
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
      onTap: () {
        AppFeedback.hapticFeedback(HapticType.light);
        AppNavigator.push(
          context,
          OrdenDetalleScreen(orden: orden),
          type: TransitionType.slide,
        );
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
