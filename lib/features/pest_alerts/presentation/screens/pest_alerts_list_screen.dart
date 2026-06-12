import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/presentation/bloc/pest_alerts_bloc.dart';
import 'package:planticula/features/pest_alerts/presentation/screens/pest_alert_detail_screen.dart';
import 'package:planticula/features/pest_alerts/presentation/widgets/pest_alert_card.dart';
import 'package:planticula/features/pest_alerts/presentation/widgets/pest_alerts_filter_sheet.dart';
import 'package:geolocator/geolocator.dart';

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
        title: const Text('Alertas de Plagas'),
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
          return TabBarView(
            controller: _tabController,
            children: [
              _buildNearbyTab(state),
              _buildMyAlertsTab(state),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pest-alerts/report'),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Se requiere ubicación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Necesitamos tu ubicación para mostrar alertas cercanas',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getLocationAndLoad,
                child: const Text('Permitir Ubicación'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isNearbyEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No hay alertas cercanas',
        subtitle: 'No se encontraron plagas reportadas en ${state.filterRadiusKm.toStringAsFixed(0)} km',
        action: ElevatedButton(
          onPressed: _showFiltersDialog,
          child: const Text('Ajustar Filtros'),
        ),
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
      return _buildEmptyState(
        icon: Icons.notification_add,
        title: 'No has reportado plagas',
        subtitle: 'Ayuda a la comunidad reportando plagas que observes',
        action: ElevatedButton(
          onPressed: () => context.push('/pest-alerts/report'),
          child: const Text('Reportar Plaga'),
        ),
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
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
