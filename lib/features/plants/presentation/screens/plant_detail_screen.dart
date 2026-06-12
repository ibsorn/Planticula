import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/species_service.dart';
import 'package:planticula/core/services/transplant_calculator.dart';
import 'package:planticula/core/services/watering_calculator.dart';
import 'package:planticula/core/services/weather_service.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/features/plants/presentation/widgets/growth_progress_bar.dart';
import 'package:planticula/features/plants/presentation/widgets/plant_chip.dart';
import 'package:planticula/features/plants/presentation/widgets/plant_info_card.dart';
import 'package:planticula/features/plants/presentation/widgets/plant_section_title.dart';
import 'package:planticula/features/plants/presentation/widgets/transplant_banner.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  WeatherData? _weather;
  WateringRecommendation? _recommendation;
  TransplantRecommendation? _transplantRecommendation;
  PlantSpecies? _species;

  @override
  void initState() {
    super.initState();
    _loadSpeciesData();
    _loadWeather();
  }

  Future<void> _loadSpeciesData() async {
    if (widget.plant.speciesId != null) {
      final species = await GetIt.instance<SpeciesService>().getSpeciesById(widget.plant.speciesId!);
      if (mounted && species != null) {
        setState(() => _species = species);
        _updateRecommendation();
      }
    }
  }

  Future<void> _loadWeather() async {
    if (widget.plant.latitude == null || widget.plant.longitude == null) return;
    if (!widget.plant.isOutdoor) return;
    try {
      final weather = await GetIt.instance<WeatherService>().getWeather(
        widget.plant.latitude!,
        widget.plant.longitude!,
      );
      if (mounted) {
        setState(() => _weather = weather);
        _updateRecommendation();
      }
    } catch (_) {}
  }

  void _updateRecommendation() {
    if (_species == null) return;
    final rec = WateringCalculator.calculate(
      species: _species!,
      environment: widget.plant.plantEnvironment,
      growthStage: widget.plant.plantGrowthStage,
      potSize: widget.plant.plantPotSize,
      weather: widget.plant.isOutdoor ? _weather : null,
    );
    final transplantRec = TransplantCalculator.evaluate(
      species: _species!,
      currentPotSize: widget.plant.plantPotSize,
      currentStage: widget.plant.plantGrowthStage,
      plantedDate: widget.plant.acquiredDate ?? widget.plant.createdAt,
      lastTransplanted: widget.plant.lastTransplanted,
    );
    setState(() {
      _recommendation = rec;
      _transplantRecommendation = transplantRec;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plant = widget.plant;
    final monthsToAdult = _species?.monthsUntilAdult(plant.plantGrowthStage);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: plant.imageUrl != null
                  ? Image.network(plant.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(context))
                  : _buildPlaceholder(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(context),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & badge row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plant.name,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            if (plant.scientificName != null)
                              Text(plant.scientificName!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: theme.colorScheme.onSurface.withAlpha(153))),
                          ],
                        ),
                      ),
                      if (plant.needsWatering)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withAlpha(26),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.water_drop, size: 16, color: theme.colorScheme.error),
                              const SizedBox(width: 4),
                              Text('Necesita riego',
                                  style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Environment & growth stage chips
                  Wrap(
                    spacing: 8,
                    children: [
                      PlantChip(
                        icon: plant.isOutdoor ? Icons.park : Icons.home,
                        label: plant.plantEnvironment.displayName,
                        color: plant.isOutdoor ? Colors.green : Colors.indigo,
                      ),
                      PlantChip(
                        icon: _stageIcon(plant.plantGrowthStage),
                        label: plant.plantGrowthStage.displayName,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // === WATERING SECTION ===
                  const PlantSectionTitle(title: 'Riego', icon: Icons.water_drop),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PlantInfoCard(
                          icon: Icons.repeat,
                          title: 'Frecuencia',
                          value: plant.hasWateringReminder
                              ? 'Cada ${plant.wateringFrequency} dias'
                              : 'Sin programar',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PlantInfoCard(
                          icon: plant.needsWatering ? Icons.warning_amber : Icons.event_available,
                          title: 'Proximo riego',
                          value: _formatNextWatering(),
                          color: plant.needsWatering ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PlantInfoCard(
                          icon: Icons.local_drink,
                          title: 'Cantidad',
                          value: _recommendation != null
                              ? _recommendation!.waterMlRange
                              : '---',
                          color: Colors.cyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PlantInfoCard(
                          icon: Icons.yard,
                          title: 'Maceta',
                          value: '${plant.plantPotSize.displayName} (${plant.plantPotSize.litersRange})',
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Water button
                  if (plant.hasWateringReminder)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _onWaterPlant(context),
                        icon: const Icon(Icons.water_drop),
                        label: Text(plant.needsWatering ? 'Regar ahora' : 'Registrar riego'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: plant.needsWatering
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: plant.needsWatering
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),

                  // Weather adjustments for outdoor plants
                  if (plant.isOutdoor && _weather != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: theme.colorScheme.secondaryContainer.withAlpha(77),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cloud, size: 18, color: theme.colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text('Clima actual: ${_weather!.currentDescription}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('${_weather!.current.temperature.round()}C',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (_weather!.willRainSoon()) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Lluvia prevista: ${_weather!.precipitationNextDays(3).toStringAsFixed(1)}mm en 3 dias',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.blue.shade700),
                              ),
                            ],
                            if (_recommendation != null && _recommendation!.hasWeatherAdjustments) ...[
                              const Divider(height: 12),
                              ..._recommendation!.adjustments.map((adj) => Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 14,
                                            color: theme.colorScheme.secondary),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(adj,
                                              style: theme.textTheme.bodySmall),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // === TRANSPLANT SECTION ===
                  if (_transplantRecommendation != null &&
                      _transplantRecommendation!.needsAction) ...[
                    TransplantBanner(
                      recommendation: _transplantRecommendation!,
                      plant: plant,
                      onTransplant: () => _showTransplantDialog(context),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // === SUNLIGHT SECTION ===
                  const PlantSectionTitle(title: 'Sol necesario', icon: Icons.wb_sunny),
                  const SizedBox(height: 8),
                  if (_species != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.wb_sunny, color: Colors.orange.shade600),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_species!.sunlightHoursMin.round()}-${_species!.sunlightHoursMax.round()} horas/dia',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(_species!.sunlightLevel.displayName,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withAlpha(153))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('No hay datos de la especie',
                            style: theme.textTheme.bodyMedium),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // === GROWTH PHASE SECTION ===
                  const PlantSectionTitle(title: 'Crecimiento', icon: Icons.trending_up),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Growth stage progress bar
                          GrowthProgressBar(
                            currentStage: plant.plantGrowthStage,
                          ),
                          const SizedBox(height: 12),
                          if (monthsToAdult != null && monthsToAdult > 0)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer.withAlpha(77),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.timer, size: 18, color: theme.colorScheme.tertiary),
                                  const SizedBox(width: 8),
                                  Text(
                                    monthsToAdult >= 12
                                        ? 'Aprox. ${(monthsToAdult / 12).toStringAsFixed(1)} años hasta adulta'
                                        : 'Aprox. $monthsToAdult meses hasta adulta',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.tertiary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          else if (plant.plantGrowthStage == GrowthStage.adult)
                            Row(
                              children: [
                                const Icon(Icons.check_circle, size: 18, color: Colors.green),
                                const SizedBox(width: 8),
                                Text('Planta adulta',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // === SPECIES INFO ===
                  if (_species != null) ...[
                    const PlantSectionTitle(title: 'Sobre esta especie', icon: Icons.info_outline),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_species!.droughtTolerant)
                          const PlantChip(icon: Icons.water_drop_outlined, label: 'Tolerante a sequia', color: Colors.amber),
                        if (_species!.humidityLoving)
                          const PlantChip(icon: Icons.water, label: 'Necesita humedad', color: Colors.cyan),
                        PlantChip(icon: Icons.thermostat, label: '${_species!.minTemperature}C - ${_species!.maxTemperature}C', color: Colors.deepOrange),
                      ],
                    ),
                  ],

                  // Notes
                  if (plant.notes != null && plant.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const PlantSectionTitle(title: 'Notas', icon: Icons.notes),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(plant.notes!, style: theme.textTheme.bodyMedium),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Icon(Icons.local_florist, size: 80,
            color: Theme.of(context).colorScheme.onPrimaryContainer.withAlpha(128)),
      ),
    );
  }

  String _formatNextWatering() {
    if (widget.plant.nextWatering == null) return 'No programado';
    final diff = widget.plant.nextWatering!.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Atrasado ${diff.abs()} dias';
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Manana';
    return 'En $diff dias';
  }

  IconData _stageIcon(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seedling: return Icons.grass;
      case GrowthStage.juvenile: return Icons.eco;
      case GrowthStage.adult: return Icons.park;
    }
  }

  void _onWaterPlant(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar riego'),
        content: Text('Marcar "${widget.plant.name}" como regada?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PlantsBloc>().add(PlantWaterRequested(widget.plant.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Riego registrado!'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar planta?'),
        content: Text('Eliminar "${widget.plant.name}"? Esta accion no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              context.read<PlantsBloc>().add(PlantDeleteRequested(widget.plant.id));
              Navigator.pop(ctx);
              context.pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showTransplantDialog(BuildContext context) {
    final rec = _transplantRecommendation;
    if (rec == null) return;

    PotSize selectedPot = rec.recommendedPotSize ?? widget.plant.plantPotSize;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.yard, color: Colors.green),
              SizedBox(width: 8),
              Text('Registrar trasplante'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elige el nuevo tamaño de maceta:',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...PotSize.values.map((pot) {
                final isRecommended = pot == rec.recommendedPotSize;
                return RadioListTile<PotSize>(
                  value: pot,
                  // ignore: deprecated_member_use
                  groupValue: selectedPot,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setStateDialog(() => selectedPot = v!),
                  title: Row(
                    children: [
                      Text(pot.displayName),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Recomendada',
                            style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(pot.litersRange,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),
              if (rec.notes != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tips_and_updates, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(rec.notes!,
                            style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Confirmar trasplante'),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<PlantsBloc>().add(PlantTransplantRequested(
                  id: widget.plant.id,
                  newPotSize: selectedPot.dbValue,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Trasplante a maceta ${selectedPot.displayName} registrado!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}






