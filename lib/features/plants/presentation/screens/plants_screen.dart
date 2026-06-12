import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/core/constants/app_strings.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/features/plants/presentation/screens/create_plant_screen.dart';
import 'package:planticula/features/plants/presentation/screens/plant_detail_screen.dart';
import 'package:planticula/shared/widgets/empty_state.dart';
import 'package:planticula/shared/widgets/status_ring.dart';

enum _GardenFilter { all, indoor, outdoor, thirsty }

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  final _searchController = TextEditingController();
  bool _searchVisible = false;
  bool _gridMode = true;
  _GardenFilter _filter = _GardenFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<PlantsBloc>().add(PlantsLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<PlantsBloc>().add(PlantsSearchRequested(query));
  }

  void _onAddPlant() {
    final bloc = context.read<PlantsBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const CreatePlantScreen(),
        ),
      ),
    );
  }

  void _onPlantTap(Plant plant) {
    context.read<PlantsBloc>().add(PlantSelectRequested(plant.id));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlantDetailScreen(plant: plant),
      ),
    );
  }

  List<Plant> _applyFilter(List<Plant> plants) {
    final filtered = switch (_filter) {
      _GardenFilter.all => plants,
      _GardenFilter.indoor => plants.where((p) => !p.isOutdoor).toList(),
      _GardenFilter.outdoor => plants.where((p) => p.isOutdoor).toList(),
      _GardenFilter.thirsty => plants.where((p) => p.needsWatering).toList(),
    };
    // Most urgent watering first.
    final sorted = [...filtered]..sort((a, b) {
        final da = a.daysUntilWatering ?? 9999;
        final db = b.daysUntilWatering ?? 9999;
        return da.compareTo(db);
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Jardín 🌿'),
        actions: [
          IconButton(
            icon: Icon(_searchVisible
                ? Icons.search_off_rounded
                : Icons.search_rounded),
            onPressed: () {
              setState(() => _searchVisible = !_searchVisible);
              if (!_searchVisible && _searchController.text.isNotEmpty) {
                _searchController.clear();
                _onSearch('');
              }
            },
          ),
          IconButton(
            icon: Icon(
                _gridMode ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _gridMode = !_gridMode),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchVisible)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.lg, 0, AppDimens.lg, AppDimens.sm),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppStrings.plantsSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
                onChanged: _onSearch,
              ),
            ),
          _buildFilterChips(),
          Expanded(
            child: BlocConsumer<PlantsBloc, PlantsState>(
              listener: (context, state) {
                if (state.errorMessage != null && !state.isLoading) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.hasError) {
                  return EmptyState(
                    emoji: '🥀',
                    title: 'Algo no ha ido bien',
                    message: state.errorMessage ?? AppStrings.unknownError,
                    actionLabel: AppStrings.plantsErrorRetry,
                    actionIcon: Icons.refresh_rounded,
                    onAction: () =>
                        context.read<PlantsBloc>().add(PlantsLoadRequested()),
                  );
                }
                if (state.isEmpty) {
                  return EmptyState(
                    emoji: '🌱',
                    title: AppStrings.plantsEmptyTitle,
                    message: AppStrings.plantsEmptySubtitle,
                    actionLabel: AppStrings.plantsAddPlantButton,
                    onAction: _onAddPlant,
                  );
                }

                final plants = _applyFilter(state.plants);
                if (plants.isEmpty) {
                  return const EmptyState(
                    emoji: '🔍',
                    title: 'Nada por aquí',
                    message: 'Ninguna planta coincide con este filtro.',
                  );
                }
                return _gridMode
                    ? _buildPlantGrid(plants)
                    : _buildPlantList(plants);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddPlant,
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.plantsAddButton),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = {
      _GardenFilter.all: 'Todas',
      _GardenFilter.indoor: '🏠 Interior',
      _GardenFilter.outdoor: '🌤 Exterior',
      _GardenFilter.thirsty: '💧 Con sed',
    };

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
        children: [
          for (final entry in filters.entries)
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.sm),
              child: FilterChip(
                label: Text(entry.value),
                selected: _filter == entry.key,
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = entry.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlantGrid(List<Plant> plants) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.lg, AppDimens.sm, AppDimens.lg, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimens.md,
        crossAxisSpacing: AppDimens.md,
        childAspectRatio: 0.78,
      ),
      itemCount: plants.length,
      itemBuilder: (context, index) => _PlantGridCard(
        plant: plants[index],
        onTap: () => _onPlantTap(plants[index]),
      ),
    );
  }

  Widget _buildPlantList(List<Plant> plants) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.lg, AppDimens.sm, AppDimens.lg, 96),
      itemCount: plants.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.md),
      itemBuilder: (context, index) => _PlantListCard(
        plant: plants[index],
        onTap: () => _onPlantTap(plants[index]),
      ),
    );
  }
}

/// Watering progress 0 (just watered) → 1 (due now or overdue).
double _wateringProgress(Plant plant) {
  final frequency = plant.wateringFrequency;
  if (frequency == null || frequency <= 0 || plant.nextWatering == null) {
    return 0;
  }
  if (plant.needsWatering) return 1;
  final remaining = plant.nextWatering!.difference(DateTime.now()).inHours / 24;
  return (1 - remaining / frequency).clamp(0.0, 1.0);
}

String _wateringLabel(Plant plant) {
  if (plant.needsWatering) return '¡Riega hoy!';
  final days = plant.daysUntilWatering;
  if (days == null) return 'Sin recordatorio';
  if (days == 0) return 'Riega hoy';
  if (days == 1) return 'Riego mañana';
  return 'Riego en $days días';
}

class _PlantGridCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const _PlantGridCard({required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PlantImage(plant: plant),
                  Positioned(
                    top: AppDimens.sm,
                    right: AppDimens.sm,
                    child: _RingBadge(plant: plant),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plant.isOutdoor ? '🌤' : '🏠'} ${_wateringLabel(plant)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: plant.needsWatering
                          ? AppColors.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          plant.needsWatering ? FontWeight.w700 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantListCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const _PlantListCard({required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: _PlantImage(plant: plant),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plant.isOutdoor ? '🌤 Exterior' : '🏠 Interior'}'
                    '${plant.location != null ? ' · ${plant.location}' : ''}',
                    style: theme.textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _wateringLabel(plant),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: plant.needsWatering
                          ? AppColors.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          plant.needsWatering ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.md),
              child: _RingBadge(plant: plant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingBadge extends StatelessWidget {
  final Plant plant;

  const _RingBadge({required this.plant});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: StatusRing(
        progress: _wateringProgress(plant),
        size: 36,
        strokeWidth: 3.5,
        child: const Text('💧', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _PlantImage extends StatelessWidget {
  final Plant plant;

  const _PlantImage({required this.plant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (plant.imageUrl != null) {
      return Image.network(
        plant.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(theme),
      );
    }
    return _placeholder(theme);
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: const Text('🪴', style: TextStyle(fontSize: 40)),
    );
  }
}
