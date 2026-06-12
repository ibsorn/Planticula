import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/core/constants/app_strings.dart';
import 'package:planticula/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/features/plants/presentation/screens/create_plant_screen.dart';
import 'package:planticula/features/plants/presentation/screens/plant_detail_screen.dart';

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  final _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.plantsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.plantsSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: _onSearch,
            ),
          ),

          // Contenido principal
          Expanded(
            child: BlocConsumer<PlantsBloc, PlantsState>(
              listener: (context, state) {
                if (state.errorMessage != null && !state.isLoading) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.hasError) {
                  return _buildErrorState(state.errorMessage ?? AppStrings.unknownError);
                }

                if (state.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildPlantList(state.plants);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddPlant,
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.plantsAddButton),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<PlantsBloc>().add(PlantsLoadRequested());
              },
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.plantsErrorRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_florist,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.plantsEmptyTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.plantsEmptySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onAddPlant,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.plantsAddPlantButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantList(List<Plant> plants) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];
        return _PlantCard(
          plant: plant,
          onTap: () => _onPlantTap(plant),
        );
      },
    );
  }
}

class _PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const _PlantCard({
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Imagen o placeholder
            SizedBox(
              width: 100,
              height: 100,
              child: plant.imageUrl != null
                  ? Image.network(
                      plant.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(colorScheme),
                    )
                  : _buildPlaceholder(colorScheme),
            ),

            // Información
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plant.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (plant.needsWatering)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  size: 14,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppStrings.plantWateringBadge,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (plant.scientificName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        plant.scientificName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (plant.location != null) ...[
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              plant.location!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (plant.hasWateringReminder) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop_outlined,
                            size: 16,
                            color: _getWateringColor(colorScheme),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getWateringText(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getWateringColor(colorScheme),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Flecha
            Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer,
      child: Icon(
        Icons.local_florist,
        size: 40,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
      ),
    );
  }

  Color _getWateringColor(ColorScheme colorScheme) {
    if (plant.needsWatering) {
      return colorScheme.error;
    }
    final days = plant.daysUntilWatering;
    if (days == null) return colorScheme.onSurface.withValues(alpha: 0.5);
    if (days <= 1) return Colors.orange;
    return colorScheme.primary;
  }

  String _getWateringText() {
    if (plant.needsWatering) {
      return '¡Necesita riego!';
    }
    final days = plant.daysUntilWatering;
    if (days == null) return '';
    if (days < 0) return 'Atrasado ${days.abs()} días';
    if (days == 0) return 'Riego hoy';
    if (days == 1) return 'Riego mañana';
    return 'Riego en $days días';
  }
}
