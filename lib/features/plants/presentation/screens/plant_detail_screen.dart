import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/species_service.dart';
import 'package:planticula/core/services/transplant_calculator.dart';
import 'package:planticula/core/services/watering_calculator.dart';
import 'package:planticula/core/services/weather_service.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/shared/widgets/domain_chip.dart';
import 'package:planticula/shared/widgets/hero_banner.dart';
import 'package:planticula/shared/widgets/phase_timeline.dart';
import 'package:planticula/shared/widgets/section_header.dart';
import 'package:planticula/shared/widgets/weather_strip.dart';

/// Plant detail organized in three blocks:
///   1. "Ahora"      — what to do today (watering CTA + weather)
///   2. "Su crianza" — growth journey, transplant, care history
///   3. "Ficha"      — species data, location, notes
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

  /// Latest version of the plant from the bloc (falls back to widget.plant).
  Plant _currentPlant(PlantsState state) {
    for (final p in state.plants) {
      if (p.id == widget.plant.id) return p;
    }
    return widget.plant;
  }

  Future<void> _loadSpeciesData() async {
    if (widget.plant.speciesId != null) {
      final species = await GetIt.instance<SpeciesService>()
          .getSpeciesById(widget.plant.speciesId!);
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
    return BlocBuilder<PlantsBloc, PlantsState>(
      builder: (context, state) {
        final plant = _currentPlant(state);
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildHeroAppBar(context, plant),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppDimens.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, plant),
                      const SizedBox(height: AppDimens.lg),
                      _buildNowBlock(context, plant),
                      _buildGrowthBlock(context, plant),
                      _buildInfoBlock(context, plant),
                      const SizedBox(height: AppDimens.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Hero image app bar
  // ---------------------------------------------------------------------
  Widget _buildHeroAppBar(BuildContext context, Plant plant) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            plant.imageUrl != null
                ? Image.network(plant.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(context))
                : _buildPlaceholder(context),
            // Gradient so the back button is always readable.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Colors.black38, Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'delete') _showDeleteConfirmation(context);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  SizedBox(width: AppDimens.sm),
                  Text('Eliminar planta'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Plant plant) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plant.name, style: theme.textTheme.displaySmall),
        if (plant.scientificName != null)
          Text(
            plant.scientificName!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: AppDimens.md),
        Wrap(
          spacing: AppDimens.sm,
          runSpacing: AppDimens.sm,
          children: [
            plant.isOutdoor
                ? const DomainChip.sun(label: 'Exterior', emoji: '🌤')
                : const DomainChip.primary(label: 'Interior', emoji: '🏠'),
            DomainChip.primary(
              label: plant.plantGrowthStage.displayName,
              emoji: _stageEmoji(plant.plantGrowthStage),
            ),
            DomainChip.soil(
              label: 'Maceta ${plant.plantPotSize.displayName.toLowerCase()}',
              emoji: '🪴',
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Block 1: NOW
  // ---------------------------------------------------------------------
  Widget _buildNowBlock(BuildContext context, Plant plant) {
    final theme = Theme.of(context);
    final needsWater = plant.needsWatering;
    final amount = _recommendation?.waterMlRange;

    final banner = needsWater
        ? HeroBanner.water(
            emoji: '💧',
            title: 'Riega hoy',
            subtitle: amount != null ? 'Cantidad: $amount' : null,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _onWaterPlant(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.water,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text('La he regado'),
              ),
            ),
          )
        : HeroBanner.success(
            emoji: '✅',
            title: 'Todo en orden',
            subtitle: _nextWateringText(plant),
            child: plant.hasWateringReminder
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _onWaterPlant(context),
                      icon: const Icon(Icons.water_drop_outlined, size: 18),
                      label: const Text('Registrar riego ahora'),
                    ),
                  )
                : null,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        banner,
        const SizedBox(height: AppDimens.sm),
        Text(
          [
            if (plant.hasWateringReminder)
              'Cada ${plant.wateringFrequency} días',
            if (plant.lastWatered != null)
              'Último: ${_formatDate(plant.lastWatered!)}',
          ].join(' · '),
          style: theme.textTheme.labelMedium,
        ),
        if (plant.isOutdoor && _weather != null) ...[
          const SizedBox(height: AppDimens.lg),
          _buildWeatherCard(context),
        ],
      ],
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    final theme = Theme.of(context);
    final weather = _weather!;
    final adjustments = _recommendation?.adjustments ?? const <String>[];

    return Card(
      child: Padding(
        padding: AppDimens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  WeatherStrip.emojiFor(weather.current.weatherCode),
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Text(
                    '${weather.current.temperature.round()}°C · ${weather.currentDescription}',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.md),
            WeatherStrip(
              days: [
                for (final day in weather.daily.take(5))
                  WeatherStripDay(
                    label: _weekdayLabel(day.date),
                    weatherCode: day.weatherCode,
                    maxTemp: day.maxTemp,
                    precipitationMm: day.precipitationMm,
                  ),
              ],
            ),
            if (adjustments.isNotEmpty) ...[
              const Divider(height: AppDimens.xl),
              for (final adj in adjustments)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('• $adj', style: theme.textTheme.bodySmall),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Block 2: GROWTH JOURNEY
  // ---------------------------------------------------------------------
  Widget _buildGrowthBlock(BuildContext context, Plant plant) {
    final theme = Theme.of(context);
    final stage = plant.plantGrowthStage;
    final monthsToAdult = _species?.monthsUntilAdult(stage);
    final transplant = _transplantRecommendation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Su crianza', emoji: '🌱'),
        Card(
          child: Padding(
            padding: AppDimens.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhaseTimeline(
                  currentIndex: GrowthStage.values.indexOf(stage),
                  stageProgress: 0.5,
                ),
                if (monthsToAdult != null && monthsToAdult > 0) ...[
                  const SizedBox(height: AppDimens.md),
                  Text(
                    'Aproximadamente $monthsToAdult ${monthsToAdult == 1 ? 'mes' : 'meses'} para ser adulta 🌳',
                    style: theme.textTheme.labelMedium,
                  ),
                ] else if (stage == GrowthStage.adult) ...[
                  const SizedBox(height: AppDimens.md),
                  Text('Planta adulta y feliz ✨',
                      style: theme.textTheme.labelMedium),
                ],
              ],
            ),
          ),
        ),
        if (transplant != null && transplant.needsAction) ...[
          const SizedBox(height: AppDimens.md),
          _buildTransplantCard(context, transplant),
        ],
        const SizedBox(height: AppDimens.lg),
        _buildHistory(context, plant),
      ],
    );
  }

  Widget _buildTransplantCard(
      BuildContext context, TransplantRecommendation rec) {
    final urgent = rec.isUrgent;
    return HeroBanner(
      accent: urgent ? AppColors.error : AppColors.soil,
      deep: urgent ? AppColors.pestDeep : AppColors.soilDeep,
      soft: urgent ? AppColors.errorSoft : AppColors.soilSoft,
      emoji: '🪴',
      title: urgent ? 'Trasplante urgente' : 'Toca trasplante pronto',
      subtitle: [
        if (rec.reason != null) rec.reason!,
        if (rec.currentPotSize != null && rec.recommendedPotSize != null)
          '${rec.currentPotSize!.displayName} → ${rec.recommendedPotSize!.displayName} (${rec.recommendedPotSize!.litersRange})',
      ].join('\n'),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () => _showTransplantDialog(context),
          style: FilledButton.styleFrom(
            backgroundColor: urgent ? AppColors.error : AppColors.soil,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.compost_rounded, size: 18),
          label: const Text('Registrar trasplante'),
        ),
      ),
    );
  }

  Widget _buildHistory(BuildContext context, Plant plant) {
    final theme = Theme.of(context);
    final events = <(String, String)>[
      if (plant.lastWatered != null)
        ('💧', 'Regada — ${_relativeDate(plant.lastWatered!)}'),
      if (plant.lastTransplanted != null)
        (
          '🪴',
          'Trasplantada a ${plant.plantPotSize.displayName.toLowerCase()} — ${_formatDate(plant.lastTransplanted!)}'
        ),
      if (plant.acquiredDate != null || plant.createdAt != null)
        ('🌱', 'Añadida — ${_formatDate(plant.acquiredDate ?? plant.createdAt!)}'),
    ];
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historial', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppDimens.sm),
        for (final (emoji, text) in events)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Text(text, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Block 3: INFO SHEET
  // ---------------------------------------------------------------------
  Widget _buildInfoBlock(BuildContext context, Plant plant) {
    final theme = Theme.of(context);
    final rows = <(String, String)>[
      if (_recommendation != null)
        ('☀️', 'Luz: ${_recommendation!.sunlightDescription}'),
      if (_species != null)
        (
          '🌡',
          'Temperatura: ${_species!.minTemperature}°C - ${_species!.maxTemperature}°C'
        ),
      if (_species?.droughtTolerant == true)
        ('🌵', 'Tolerante a la sequía'),
      if (_species?.humidityLoving == true)
        ('💨', 'Le encanta la humedad ambiental'),
      if (plant.location != null) ('📍', 'Ubicación: ${plant.location}'),
      if (plant.notes != null && plant.notes!.isNotEmpty)
        ('📝', plant.notes!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Ficha', emoji: '📋'),
        Card(
          child: Padding(
            padding: AppDimens.cardPadding,
            child: Column(
              children: [
                for (final (emoji, text) in rows)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppDimens.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: AppDimens.md),
                        Expanded(
                          child:
                              Text(text, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Helpers & actions
  // ---------------------------------------------------------------------
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Center(child: Text('🪴', style: TextStyle(fontSize: 72))),
    );
  }

  String _stageEmoji(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seedling:
        return '🌱';
      case GrowthStage.juvenile:
        return '🌿';
      case GrowthStage.adult:
        return '🌳';
    }
  }

  String _nextWateringText(Plant plant) {
    if (plant.nextWatering == null) return 'Sin recordatorio de riego';
    final diff = plant.nextWatering!.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Riega hoy';
    if (diff == 1) return 'Riega mañana';
    return 'Riega en $diff días';
  }

  String _formatDate(DateTime date) => DateFormat('d MMM yyyy', 'es').format(date);

  String _weekdayLabel(DateTime date) {
    final label = DateFormat.E('es').format(date);
    return label[0].toUpperCase() + label.substring(1);
  }

  String _relativeDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'hoy';
    if (days == 1) return 'ayer';
    if (days < 30) return 'hace $days días';
    return _formatDate(date);
  }

  void _onWaterPlant(BuildContext context) {
    context.read<PlantsBloc>().add(PlantWaterRequested(widget.plant.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('¡${widget.plant.name} regada! 💧')),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar planta?'),
        content: Text(
            '¿Eliminar "${widget.plant.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              context
                  .read<PlantsBloc>()
                  .add(PlantDeleteRequested(widget.plant.id));
              Navigator.pop(ctx);
              context.pop();
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
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
              Text('🪴', style: TextStyle(fontSize: 22)),
              SizedBox(width: AppDimens.sm),
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
              const SizedBox(height: AppDimens.md),
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
                        const DomainChip.primary(label: 'Recomendada'),
                      ],
                    ],
                  ),
                  subtitle: Text(pot.litersRange,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<PlantsBloc>().add(PlantTransplantRequested(
                      id: widget.plant.id,
                      newPotSize: selectedPot.dbValue,
                    ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Trasplante registrado! 🪴')),
                );
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
