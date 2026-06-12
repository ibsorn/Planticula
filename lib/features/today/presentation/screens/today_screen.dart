import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/species_service.dart';
import 'package:planticula/core/services/transplant_calculator.dart';
import 'package:planticula/core/services/watering_calculator.dart';
import 'package:planticula/core/services/weather_service.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/shared/widgets/empty_state.dart';
import 'package:planticula/shared/widgets/hero_banner.dart';
import 'package:planticula/shared/widgets/section_header.dart';
import 'package:planticula/shared/widgets/task_tile.dart';
import 'package:planticula/shared/widgets/weather_strip.dart';

/// "Hoy" dashboard: weather + actionable care tasks for today and a preview
/// of the coming days. This is the app's home screen.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  WeatherData? _weather;
  final Map<String, PlantSpecies> _speciesByPlantId = {};
  final Set<String> _wateredNow = {};
  final Set<String> _transplantedNow = {};

  @override
  void initState() {
    super.initState();
    final plantsState = context.read<PlantsBloc>().state;
    if (plantsState.status == PlantsStatus.initial) {
      context.read<PlantsBloc>().add(PlantsLoadRequested());
    } else {
      _loadAuxData(plantsState.plants);
    }
  }

  Future<void> _loadAuxData(List<Plant> plants) async {
    // Weather from the first outdoor plant with coordinates.
    Plant? outdoorPlant;
    for (final p in plants) {
      if (p.isOutdoor && p.latitude != null && p.longitude != null) {
        outdoorPlant = p;
        break;
      }
    }
    if (outdoorPlant != null && _weather == null) {
      try {
        final weather = await GetIt.instance<WeatherService>()
            .getWeather(outdoorPlant.latitude!, outdoorPlant.longitude!);
        if (mounted) setState(() => _weather = weather);
      } catch (_) {}
    }

    // Species data (needed for transplant + water amount).
    final speciesService = GetIt.instance<SpeciesService>();
    for (final plant in plants) {
      if (plant.speciesId == null ||
          _speciesByPlantId.containsKey(plant.id)) {
        continue;
      }
      final species = await speciesService.getSpeciesById(plant.speciesId!);
      if (species != null && mounted) {
        setState(() => _speciesByPlantId[plant.id] = species);
      }
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 7) return 'Buenas noches';
    if (hour < 13) return '¡Buenos días';
    if (hour < 21) return '¡Buenas tardes';
    return 'Buenas noches';
  }

  String? _waterAmountFor(Plant plant) {
    final species = _speciesByPlantId[plant.id];
    if (species == null) return null;
    final rec = WateringCalculator.calculate(
      species: species,
      environment: plant.plantEnvironment,
      growthStage: plant.plantGrowthStage,
      potSize: plant.plantPotSize,
      weather: plant.isOutdoor ? _weather : null,
    );
    return rec.waterMlRange;
  }

  TransplantRecommendation? _transplantFor(Plant plant) {
    final species = _speciesByPlantId[plant.id];
    if (species == null) return null;
    final rec = TransplantCalculator.evaluate(
      species: species,
      currentPotSize: plant.plantPotSize,
      currentStage: plant.plantGrowthStage,
      plantedDate: plant.acquiredDate ?? plant.createdAt,
      lastTransplanted: plant.lastTransplanted,
    );
    return rec.isDue ? rec : null;
  }

  void _waterPlant(Plant plant) {
    setState(() => _wateredNow.add(plant.id));
    context.read<PlantsBloc>().add(PlantWaterRequested(plant.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('¡${plant.name} regada! 💧')),
    );
  }

  void _transplantPlant(Plant plant, TransplantRecommendation rec) {
    final newSize = rec.recommendedPotSize;
    if (newSize == null) return;
    setState(() => _transplantedNow.add(plant.id));
    context.read<PlantsBloc>().add(
          PlantTransplantRequested(id: plant.id, newPotSize: newSize.dbValue),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡${plant.name} trasplantada a ${newSize.displayName.toLowerCase()}! 🪴'),
      ),
    );
  }

  void _openPlant(Plant plant) {
    context.push('/plants/${plant.id}', extra: plant);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<PlantsBloc, PlantsState>(
          listener: (context, state) {
            if (state.status == PlantsStatus.loaded) {
              _loadAuxData(state.plants);
            }
          },
          builder: (context, state) {
            if (state.isLoading || state.status == PlantsStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<PlantsBloc>().add(PlantsLoadRequested()),
              child: ListView(
                padding: AppDimens.screenPadding,
                children: _buildContent(context, state),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, PlantsState state) {
    final theme = Theme.of(context);
    final plants = state.plants;

    final userName = context.select<AuthBloc, String?>(
      (bloc) => bloc.state.user?.email.split('@').first,
    );

    final header = Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.lg),
      child: Text(
        userName != null ? '$_greeting, $userName! 👋' : '$_greeting! 👋',
        style: theme.textTheme.displaySmall,
      ),
    );

    if (plants.isEmpty) {
      return [
        header,
        const SizedBox(height: AppDimens.xxl),
        EmptyState(
          emoji: '🌱',
          title: 'Empieza tu jardín',
          message:
              'Añade tu primera planta y te diré cuándo regarla y cómo cuidarla.',
          actionLabel: 'Añadir mi primera planta',
          onAction: () => context.go(AppConstants.routePlants),
        ),
      ];
    }

    // --- Today's tasks ---
    final waterToday = plants
        .where((p) => p.needsWatering && !_wateredNow.contains(p.id))
        .toList();
    final transplantToday = <(Plant, TransplantRecommendation)>[];
    for (final plant in plants) {
      if (_transplantedNow.contains(plant.id)) continue;
      final rec = _transplantFor(plant);
      if (rec != null) transplantToday.add((plant, rec));
    }
    final taskCount = waterToday.length + transplantToday.length;

    // --- Upcoming (next 7 days) ---
    final now = DateTime.now();
    final upcoming = plants.where((p) {
      if (p.nextWatering == null || p.needsWatering) return false;
      if (_wateredNow.contains(p.id)) return false;
      return p.nextWatering!.difference(now).inDays < 7;
    }).toList()
      ..sort((a, b) => a.nextWatering!.compareTo(b.nextWatering!));

    final hasOutdoor = plants.any((p) => p.isOutdoor);

    return [
      header,
      if (_weather != null) _buildWeatherBanner(context, hasOutdoor),
      SectionHeader(
        title: 'Para hoy',
        emoji: '💪',
        trailing: taskCount == 0
            ? null
            : '$taskCount ${taskCount == 1 ? 'pendiente' : 'pendientes'}',
      ),
      if (taskCount == 0)
        HeroBanner.success(
          emoji: '🎉',
          title: '¡Todo listo por hoy!',
          subtitle: upcoming.isNotEmpty
              ? 'Próximo riego: ${_dayLabel(upcoming.first.nextWatering!)} (${upcoming.first.name})'
              : 'Tus plantas están felices.',
        )
      else ...[
        for (final plant in waterToday)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: TaskTile.water(
              emoji: '💧',
              title: 'Regar ${plant.name}',
              subtitle: _waterAmountFor(plant),
              onCheck: () => _waterPlant(plant),
              onTap: () => _openPlant(plant),
            ),
          ),
        for (final (plant, rec) in transplantToday)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: TaskTile.transplant(
              emoji: '🪴',
              title: 'Trasplantar ${plant.name}',
              subtitle:
                  '${rec.currentPotSize?.displayName ?? ''} → ${rec.recommendedPotSize?.displayName ?? ''}',
              onCheck: () => _transplantPlant(plant, rec),
              onTap: () => _openPlant(plant),
            ),
          ),
      ],
      if (upcoming.isNotEmpty) ...[
        const SectionHeader(title: 'Próximamente', emoji: '📅'),
        for (final plant in upcoming.take(5))
          _UpcomingRow(
            plant: plant,
            dayLabel: _dayLabel(plant.nextWatering!),
            postponedByRain: _mayBePostponedByRain(plant),
            onTap: () => _openPlant(plant),
          ),
      ],
      const SizedBox(height: AppDimens.xxl),
    ];
  }

  Widget _buildWeatherBanner(BuildContext context, bool hasOutdoor) {
    final weather = _weather!;
    final current = weather.current;
    final insight = _weatherInsight(weather, hasOutdoor);

    return HeroBanner.weather(
      emoji: WeatherStrip.emojiFor(current.weatherCode),
      title: '${current.temperature.round()}°C · ${weather.currentDescription}',
      subtitle: insight ?? 'Humedad ${current.humidity.round()}%',
      child: WeatherStrip(
        days: [
          for (final day in weather.daily.take(5))
            WeatherStripDay(
              label: _dayLabel(day.date),
              weatherCode: day.weatherCode,
              maxTemp: day.maxTemp,
              precipitationMm: day.precipitationMm,
            ),
        ],
      ),
    );
  }

  String? _weatherInsight(WeatherData weather, bool hasOutdoor) {
    if (!hasOutdoor) return null;
    if (weather.willRainSoon()) {
      return '💡 Lloverá pronto: tus plantas de exterior pueden esperar';
    }
    if (weather.avgMaxTempNextDays(3) > AppConstants.tempHighThresholdC) {
      return '💡 Días de mucho calor: vigila el riego de tus plantas';
    }
    return null;
  }

  bool _mayBePostponedByRain(Plant plant) {
    final weather = _weather;
    if (weather == null || !plant.isOutdoor || plant.nextWatering == null) {
      return false;
    }
    for (final day in weather.daily) {
      if (_isSameDay(day.date, plant.nextWatering!)) {
        return day.precipitationMm > AppConstants.rainLightMm;
      }
    }
    return false;
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Hoy';
    if (_isSameDay(date, now.add(const Duration(days: 1)))) return 'Mañana';
    final label = DateFormat.E('es').format(date);
    return label[0].toUpperCase() + label.substring(1);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _UpcomingRow extends StatelessWidget {
  final Plant plant;
  final String dayLabel;
  final bool postponedByRain;
  final VoidCallback onTap;

  const _UpcomingRow({
    required this.plant,
    required this.dayLabel,
    required this.postponedByRain,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimens.buttonRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                dayLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Text('💧', style: TextStyle(fontSize: 16)),
            const SizedBox(width: AppDimens.sm),
            Expanded(
              child: Text(plant.name, style: theme.textTheme.bodyLarge),
            ),
            if (postponedByRain)
              Text(
                '☔ puede posponerse',
                style: theme.textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}
