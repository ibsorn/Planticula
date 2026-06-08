import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/presentation/bloc/pest_alerts_bloc.dart';
import 'package:planticula/features/pest_alerts/presentation/screens/pest_alert_detail_screen.dart';
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

      if (permission == LocationPermission.authorized ||
          permission == LocationPermission.authorizedAlways) {
        final position = await Geolocator.getCurrentPosition();
        context.read<PestAlertsBloc>().add(PestAlertsUpdateUserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ));
      } else {
        // Sin permiso, intentar cargar sin ubicación precisa
        context.read<PestAlertsBloc>().add(PestAlertsLoadNearby());
      }
    } catch (e) {
      // Cargar de todos modos
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

class PestAlertCard extends StatelessWidget {
  final PestAlert alert;
  final bool showDistance;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onMarkResolved;
  final VoidCallback? onDelete;

  const PestAlertCard({
    super.key,
    required this.alert,
    required this.showDistance,
    required this.onTap,
    this.onConfirm,
    this.onMarkResolved,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con foto o placeholder
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: Color(alert.severity.colorValue).withOpacity(0.1),
                  child: alert.photoUrl != null
                      ? Image.network(
                          alert.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                // Badge de severidad
                Positioned(
                  top: 8,
                  left: 8,
                  child: _SeverityBadge(severity: alert.severity),
                ),
                // Badge de distancia
                if (showDistance && alert.distanceDisplay != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            alert.distanceDisplay!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.pestTypeDisplay,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (alert.confirmedByCount != null && alert.confirmedByCount! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${alert.confirmedByCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.locationDisplay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(alert.reportedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (alert.isResolved) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        const Text(
                          'Resuelta',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Acciones
                  if (onConfirm != null || onMarkResolved != null || onDelete != null)
                    Row(
                      children: [
                        if (onConfirm != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onConfirm,
                              icon: const Icon(Icons.thumb_up, size: 16),
                              label: const Text('Confirmar'),
                            ),
                          ),
                        if (onMarkResolved != null) ...[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onMarkResolved,
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Resuelta'),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline),
                            color: colorScheme.error,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bug_report,
            size: 48,
            color: Color(alert.severity.colorValue).withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Sin foto',
            style: TextStyle(
              color: Color(alert.severity.colorValue).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SeverityBadge extends StatelessWidget {
  final Severity severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(severity.colorValue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PestAlertsFiltersSheet extends StatefulWidget {
  const PestAlertsFiltersSheet({super.key});

  @override
  State<PestAlertsFiltersSheet> createState() => _PestAlertsFiltersSheetState();
}

class _PestAlertsFiltersSheetState extends State<PestAlertsFiltersSheet> {
  double _radiusKm = 10.0;
  int _daysLimit = 30;
  List<PestType> _selectedTypes = [];
  List<Severity> _selectedSeverities = [];
  bool _includeResolved = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<PestAlertsBloc>().state;
    _radiusKm = state.filterRadiusKm;
    _daysLimit = state.filterDaysLimit;
    _selectedTypes = List.from(state.filterPestTypes);
    _selectedSeverities = List.from(state.filterSeverities);
    _includeResolved = state.includeResolved;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _radiusKm = 10.0;
                        _daysLimit = 30;
                        _selectedTypes = [];
                        _selectedSeverities = [];
                        _includeResolved = false;
                      });
                    },
                    child: const Text('Reiniciar'),
                  ),
                ],
              ),
              const Divider(),

              // Contenido scrollable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Radio de distancia
                    Text(
                      'Distancia máxima: ${_radiusKm.toStringAsFixed(0)} km',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '${_radiusKm.toStringAsFixed(0)} km',
                      onChanged: (value) => setState(() => _radiusKm = value),
                    ),
                    const SizedBox(height: 16),

                    // Días límite
                    Text(
                      'Alertas de los últimos $_daysLimit días',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _daysLimit.toDouble(),
                      min: 1,
                      max: 90,
                      divisions: 89,
                      label: '$_daysLimit días',
                      onChanged: (value) => setState(() => _daysLimit = value.toInt()),
                    ),
                    const SizedBox(height: 16),

                    // Tipos de plaga
                    Text(
                      'Tipos de plaga',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PestType.values.map((type) {
                        final isSelected = _selectedTypes.contains(type);
                        return FilterChip(
                          label: Text(type.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTypes.add(type);
                              } else {
                                _selectedTypes.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Severidades
                    Text(
                      'Gravedad',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Severity.values.map((severity) {
                        final isSelected = _selectedSeverities.contains(severity);
                        return FilterChip(
                          label: Text(severity.displayName),
                          selected: isSelected,
                          selectedColor: Color(severity.colorValue).withOpacity(0.2),
                          checkmarkColor: Color(severity.colorValue),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSeverities.add(severity);
                              } else {
                                _selectedSeverities.remove(severity);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Incluir resueltas
                    SwitchListTile(
                      title: const Text('Incluir alertas resueltas'),
                      value: _includeResolved,
                      onChanged: (value) => setState(() => _includeResolved = value),
                    ),
                  ],
                ),
              ),

              // Botón aplicar
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.read<PestAlertsBloc>().add(PestAlertsFilterChanged(
                      radiusKm: _radiusKm,
                      daysLimit: _daysLimit,
                      pestTypes: _selectedTypes.isEmpty ? null : _selectedTypes,
                      severities: _selectedSeverities.isEmpty ? null : _selectedSeverities,
                      includeResolved: _includeResolved,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
