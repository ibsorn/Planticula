import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/presentation/bloc/pest_alerts_bloc.dart';
import 'package:planticula/features/pest_alerts/presentation/screens/pest_alert_detail_screen.dart';
import 'package:planticula/features/pest_alerts/presentation/widgets/pest_alert_card.dart';
import 'package:planticula/features/pest_alerts/presentation/widgets/pest_alerts_filter_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/shared/widgets/community_switcher.dart';
import 'package:planticula/shared/widgets/empty_state.dart';

class PestAlertsListScreen extends StatefulWidget {
  const PestAlertsListScreen({super.key});

  @override
  State<PestAlertsListScreen> createState() => _PestAlertsListScreenState();
}

class _PestAlertsListScreenState extends State<PestAlertsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _getLocationAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final bloc = context.read<PestAlertsBloc>();
      if (_tabController.index == 0) {
        bloc.add(PestAlertsLoadNearby());
      } else {
        bloc.add(PestAlertsLoadMyAlerts());
      }
    }
  }

  Future<void> _getLocationAndLoad() async {
    setState(() => _isGettingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (!mounted) return;
        context.read<PestAlertsBloc>().add(PestAlertsUpdateUserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ));
      } else {
        // Sin permiso, intentar cargar sin ubicación precisa
        if (!mounted) return;
        context.read<PestAlertsBloc>().add(PestAlertsLoadNearby());
      }
    } catch (e) {
      // Cargar de todos modos
      if (!mounted) return;
      context.read<PestAlertsBloc>().add(PestAlertsLoadNearby());
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const PestAlertsFiltersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad 👥'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.near_me), text: 'Cercanas'),
            Tab(icon: Icon(Icons.person), text: 'Mis Alertas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PestAlertsBloc>().add(PestAlertsRefresh());
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: BlocConsumer<PestAlertsBloc, PestAlertsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              const CommunitySwitcher(selected: 0),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNearbyTab(state),
                    _buildMyAlertsTab(state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pest-alerts/report'),
        backgroundColor: AppColors.pest,
        icon: const Icon(Icons.add_alert),
        label: const Text('Reportar'),
      ),
    );
  }

  Widget _buildNearbyTab(PestAlertsState state) {
    if (_isGettingLocation || state.isNearbyLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasLocation) {
      return EmptyState(
        emoji: '📍',
        title: 'Se requiere ubicación',
        message: 'Necesitamos tu ubicación para mostrar alertas cercanas',
        actionLabel: 'Permitir ubicación',
        actionIcon: Icons.my_location_rounded,
        onAction: _getLocationAndLoad,
      );
    }

    if (state.isNearbyEmpty) {
      return EmptyState(
        emoji: '🔍',
        title: '¡Buenas noticias!',
        message:
            'Ninguna plaga reportada en ${state.filterRadiusKm.toStringAsFixed(0)} km a la redonda.',
        actionLabel: 'Ajustar filtros',
        actionIcon: Icons.tune_rounded,
        onAction: _showFiltersDialog,
      );
    }

    return _buildAlertsList(
      state.nearbyAlerts,
      showDistance: true,
      onConfirm: (alert) {
        context.read<PestAlertsBloc>().add(PestAlertsConfirmAlert(alert.id));
      },
    );
  }

  Widget _buildMyAlertsTab(PestAlertsState state) {
    if (state.isMyAlertsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isMyAlertsEmpty) {
      return EmptyState(
        emoji: '🐛',
        title: 'No has reportado plagas',
        message: 'Ayuda a la comunidad reportando plagas que observes',
        actionLabel: 'Reportar plaga',
        actionIcon: Icons.add_alert_rounded,
        onAction: () => context.push('/pest-alerts/report'),
      );
    }

    return _buildAlertsList(
      state.myAlerts,
      showDistance: false,
      onMarkResolved: (alert) {
        context.read<PestAlertsBloc>().add(PestAlertsMarkResolved(alert.id));
      },
      onDelete: (alert) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar alerta'),
            content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  context.read<PestAlertsBloc>().add(PestAlertsDeleteAlert(alert.id));
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsList(
    List<PestAlert> alerts, {
    required bool showDistance,
    void Function(PestAlert)? onConfirm,
    void Function(PestAlert)? onMarkResolved,
    void Function(PestAlert)? onDelete,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return PestAlertCard(
          alert: alert,
          showDistance: showDistance,
          onTap: () => _showAlertDetail(alert),
          onConfirm: onConfirm != null ? () => onConfirm(alert) : null,
          onMarkResolved: onMarkResolved != null ? () => onMarkResolved(alert) : null,
          onDelete: onDelete != null ? () => onDelete(alert) : null,
        );
      },
    );
  }

  void _showAlertDetail(PestAlert alert) {
    context.read<PestAlertsBloc>().add(PestAlertsAlertSelected(alert.id));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PestAlertDetailScreen(alert: alert),
      ),
    );
  }
}
