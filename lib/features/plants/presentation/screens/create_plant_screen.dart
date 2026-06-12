import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/species_service.dart';
import 'package:planticula/core/services/watering_calculator.dart';
import 'package:planticula/core/services/weather_service.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/features/plants/presentation/widgets/option_card.dart';
import 'package:planticula/features/plants/presentation/widgets/species_card.dart';
import 'package:planticula/features/plants/presentation/widgets/variety_card.dart';
import 'package:planticula/features/plants/presentation/widgets/watering_recommendation_card.dart';

class CreatePlantScreen extends StatefulWidget {
  const CreatePlantScreen({super.key});

  @override
  State<CreatePlantScreen> createState() => _CreatePlantScreenState();
}

class _CreatePlantScreenState extends State<CreatePlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _speciesService = GetIt.instance<SpeciesService>();
  final _weatherService = GetIt.instance<WeatherService>();

  // Step tracking
  int _currentStep = 0;

  // Selected data
  PlantSpecies? _selectedSpecies;
  PlantEnvironment _environment = PlantEnvironment.indoor;
  GrowthStage _growthStage = GrowthStage.adult;
  PotSize _potSize = PotSize.medium;

  // Search state
  List<PlantSpecies> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  // Location
  double? _latitude;
  double? _longitude;

  // Weather & recommendation
  WeatherData? _weather;
  WateringRecommendation? _recommendation;

  @override
  void initState() {
    super.initState();
    _loadDefaultSpecies();
    _getLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    // Note: _speciesService and _weatherService are singletons managed by GetIt,
    // do NOT dispose them here.
    super.dispose();
  }

  Future<void> _loadDefaultSpecies() async {
    final results = await _speciesService.searchSpecies('');
    if (mounted) {
      setState(() => _searchResults = results);
    }
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _latitude = pos.latitude;
            _longitude = pos.longitude;
          });
          _fetchWeather();
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchWeather() async {
    if (_latitude == null || _longitude == null) return;
    try {
      final weather = await _weatherService.getWeather(_latitude!, _longitude!);
      if (mounted) setState(() => _weather = weather);
      _updateRecommendation();
    } catch (_) {}
  }

  void _onSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      final results = await _speciesService.searchSpecies(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSpecies(PlantSpecies species) {
    // If species has varieties, show variety selection step
    if (species.hasVarieties) {
      setState(() {
        _selectedSpecies = species;
        _currentStep = 2; // Variety selection step
      });
      return;
    }
    setState(() {
      _selectedSpecies = species;
      _nameController.text = species.commonName;
      _currentStep = 1;
    });
    _updateRecommendation();
  }



  void _selectVariety(PlantSpecies variety) {
    setState(() {
      _selectedSpecies = variety;
      _nameController.text = variety.commonName;
      _currentStep = 1;
    });
    _updateRecommendation();
  }

  double _potIconSize(PotSize pot) {
    switch (pot) {
      case PotSize.extraSmall:
        return 16;
      case PotSize.small:
        return 20;
      case PotSize.medium:
        return 24;
      case PotSize.large:
        return 28;
      case PotSize.extraLarge:
        return 32;
    }
  }

  void _updateRecommendation() {
    if (_selectedSpecies == null) return;
    final rec = WateringCalculator.calculate(
      species: _selectedSpecies!,
      environment: _environment,
      growthStage: _growthStage,
      potSize: _potSize,
      weather: _environment == PlantEnvironment.outdoor ? _weather : null,
    );
    setState(() => _recommendation = rec);
  }

  void _onSave() {
    if (_selectedSpecies == null) return;

    final name = _nameController.text.trim().isEmpty
        ? _selectedSpecies!.commonName
        : _nameController.text.trim();

    context.read<PlantsBloc>().add(PlantCreateRequested(
          name: name,
          scientificName: _selectedSpecies!.scientificName,
          speciesId: _selectedSpecies!.id,
          speciesCategory: _selectedSpecies!.category,
          wateringFrequency: _recommendation?.frequencyDays ??
              _selectedSpecies!.getBaseWateringDays(_environment),
          environment: _environment.name,
          growthStage: _growthStage.name,
          potSize: _potSize.dbValue,
          latitude: _latitude,
          longitude: _longitude,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0
            ? '¿Qué planta tienes? 🌿'
            : _currentStep == 2
                ? 'Elige variedad 🌱'
                : _currentStep == 3
                    ? '¡Lista! 🎉'
                    : 'Cuéntame de ella 💚'),
        automaticallyImplyLeading: false,
        leading: _currentStep == 3
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (_currentStep == 1) {
                    // From config, go back to search (or variety if it has varieties)
                    if (_selectedSpecies?.isVariety == true) {
                      setState(() => _currentStep = 2);
                    } else {
                      setState(() => _currentStep = 0);
                    }
                  } else if (_currentStep == 2) {
                    setState(() => _currentStep = 0);
                  } else {
                    context.pop();
                  }
                },
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _stepProgress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
            ),
          ),
        ),
      ),
      body: BlocConsumer<PlantsBloc, PlantsState>(
        listener: (context, state) {
          if (state.isOperationSuccess && _currentStep != 3) {
            setState(() => _currentStep = 3);
          }
          if (state.errorMessage != null &&
              state.operationStatus == PlantsOperationStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_currentStep == 0) {
            return _buildSpeciesSearch(theme);
          } else if (_currentStep == 2) {
            return _buildVarietySelection(theme);
          } else if (_currentStep == 3) {
            return _buildCelebration(theme);
          } else {
            return _buildConfiguration(theme, state);
          }
        },
      ),
    );
  }

  double get _stepProgress {
    switch (_currentStep) {
      case 0:
        return 0.33;
      case 2:
        return 0.5;
      case 1:
        return 0.66;
      case 3:
        return 1;
      default:
        return 0.33;
    }
  }

  // ===================== STEP 3: Celebration =====================

  Widget _buildCelebration(ThemeData theme) {
    final name = _nameController.text.trim().isEmpty
        ? (_selectedSpecies?.commonName ?? 'Tu planta')
        : _nameController.text.trim();
    final rec = _recommendation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text('🎉', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            '¡$name ya está en tu jardín!',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Te avisaré cada vez que necesite algo.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          if (rec != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _celebrationRow('💧',
                        'Riego: ${rec.frequencyDescription.toLowerCase()} (${rec.waterMlRange})'),
                    const SizedBox(height: 8),
                    _celebrationRow('☀️', rec.sunlightDescription),
                    if (_environment == PlantEnvironment.outdoor &&
                        rec.hasWeatherAdjustments) ...[
                      const SizedBox(height: 8),
                      _celebrationRow('🌦', 'Ajustaré el riego según el clima de tu zona'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.local_florist_rounded),
            label: const Text('Ver mi jardín'),
          ),
        ],
      ),
    );
  }

  Widget _celebrationRow(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }

  // ===================== STEP 0: Species Search =====================

  Widget _buildSpeciesSearch(ThemeData theme) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar especie (ej: monstera, tomate...)',
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
              ),
            ),
            onChanged: _onSearch,
          ),
        ),

        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48,
                            color: theme.colorScheme.onSurface.withAlpha(77)),
                        const SizedBox(height: 8),
                        const Text('No se encontraron especies'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final species = _searchResults[index];
                      return SpeciesCard(
                        species: species,
                        onTap: () => _selectSpecies(species),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  // ===================== STEP 2: Variety Selection =====================

  Widget _buildVarietySelection(ThemeData theme) {
    final parentSpecies = _selectedSpecies!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent info header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.primaryContainer.withAlpha(51),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(parentSpecies.commonName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(parentSpecies.scientificName,
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              if (parentSpecies.description != null) ...[
                const SizedBox(height: 4),
                Text(parentSpecies.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153))),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Selecciona variedad:',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        // Variety list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: parentSpecies.varieties.length,
            itemBuilder: (context, index) {
              final variety = parentSpecies.varieties[index];
              return VarietyCard(
                variety: variety,
                onTap: () => _selectVariety(variety),
              );
            },
          ),
        ),
        // Option to use generic parent species
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _nameController.text = parentSpecies.commonName;
                _currentStep = 1;
              });
              _updateRecommendation();
            },
            icon: const Icon(Icons.skip_next),
            label: const Text('Usar configuracion generica'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== STEP 1: Configuration =====================

  Widget _buildConfiguration(ThemeData theme, PlantsState state) {
    final species = _selectedSpecies!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selected species header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.local_florist,
                          color: theme.colorScheme.onPrimaryContainer, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(species.commonName,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(species.scientificName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurface.withAlpha(153))),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Custom name (optional)
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Ponle un nombre',
                hintText: 'Ej: Mi monstera del salon',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Opcional - por defecto usa el nombre de la especie',
              ),
            ),
            const SizedBox(height: 24),

            // Environment selection
            Text('Donde la tienes?', style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OptionCard(
                    icon: Icons.home,
                    label: 'Dentro de casa',
                    subtitle: 'Salon, habitacion...',
                    isSelected: _environment == PlantEnvironment.indoor,
                    onTap: () {
                      setState(() => _environment = PlantEnvironment.indoor);
                      _updateRecommendation();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OptionCard(
                    icon: Icons.park,
                    label: 'Fuera',
                    subtitle: 'Terraza, jardin, balcon',
                    isSelected: _environment == PlantEnvironment.outdoor,
                    onTap: () {
                      setState(() => _environment = PlantEnvironment.outdoor);
                      _updateRecommendation();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Adaptive growth stage - human-friendly questions
            ..._buildAdaptiveGrowthQuestion(theme, species),
            const SizedBox(height: 24),

            // Pot size selection
            Text('En que maceta esta?', style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('El tamaño afecta la frecuencia y cantidad de agua por riego',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(128))),
            const SizedBox(height: 8),
            Column(
              children: PotSize.values.map((pot) {
                final isSelected = _potSize == pot;
                return GestureDetector(
                  onTap: () {
                    setState(() => _potSize = pot);
                    _updateRecommendation();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withAlpha(77),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Pot icon with size scale
                        SizedBox(
                          width: 40,
                          child: Text(
                            pot.icon,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: _potIconSize(pot)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + liters range
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pot.displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                pot.litersRange,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer.withAlpha(179)
                                      : theme.colorScheme.onSurface.withAlpha(128),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Selection indicator
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: theme.colorScheme.primary, size: 22)
                        else
                          Icon(Icons.radio_button_unchecked,
                              color: theme.colorScheme.outline.withAlpha(128), size: 22),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Smart recommendation preview
            if (_recommendation != null) ...[
              Text('Asi la vamos a cuidar', style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Calculado segun la especie, ubicacion y tamaño',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(128))),
              const SizedBox(height: 8),
              WateringRecommendationCard(recommendation: _recommendation!),

              // Weather adjustments
              if (_recommendation!.hasWeatherAdjustments &&
                  _environment == PlantEnvironment.outdoor) ...[
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.secondaryContainer.withAlpha(77),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud, size: 18,
                                color: theme.colorScheme.secondary),
                            const SizedBox(width: 8),
                            Text('Ajustes por clima',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.secondary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ..._recommendation!.adjustments.map((adj) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('- $adj',
                                  style: theme.textTheme.bodySmall),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: state.isOperationLoading ? null : _onSave,
              icon: state.isOperationLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(state.isOperationLoading
                  ? 'Guardando...'
                  : 'Añadir planta'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds adaptive growth stage question based on species type
  List<Widget> _buildAdaptiveGrowthQuestion(ThemeData theme, PlantSpecies species) {
    // Succulents & Cacti: skip growth question entirely (not meaningful)
    if (species.isSucculent) {
      // Default to adult, no question needed
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer.withAlpha(51),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Los cactus y suculentas crecen muy lento. Ajustaremos el riego automaticamente.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // Cannabis: specific flowering questions
    if (species.isCannabis) {
      return [
        Text('En que fase esta?', style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OptionCard(
          icon: Icons.grass,
          label: 'Recien plantada / germinando',
          subtitle: 'Semilla o brote reciente',
          isSelected: _growthStage == GrowthStage.seedling,
          onTap: () {
            setState(() => _growthStage = GrowthStage.seedling);
            _updateRecommendation();
          },
        ),
        const SizedBox(height: 8),
        OptionCard(
          icon: Icons.eco,
          label: 'Creciendo (vegetativo)',
          subtitle: 'Tiene tallos y hojas pero no flores',
          isSelected: _growthStage == GrowthStage.juvenile,
          onTap: () {
            setState(() => _growthStage = GrowthStage.juvenile);
            _updateRecommendation();
          },
        ),
        const SizedBox(height: 8),
        OptionCard(
          icon: Icons.filter_vintage,
          label: 'En floracion',
          subtitle: 'Ya tiene cogollos formandose',
          isSelected: _growthStage == GrowthStage.adult,
          onTap: () {
            setState(() => _growthStage = GrowthStage.adult);
            _updateRecommendation();
          },
        ),
      ];
    }

    // Edible plants: ask about fruiting
    if (species.isEdible) {
      return [
        Text('Como esta tu planta?', style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OptionCard(
          icon: Icons.grass,
          label: 'Acaba de brotar',
          subtitle: 'Tiene pocas hojas pequeñas',
          isSelected: _growthStage == GrowthStage.seedling,
          onTap: () {
            setState(() => _growthStage = GrowthStage.seedling);
            _updateRecommendation();
          },
        ),
        const SizedBox(height: 8),
        OptionCard(
          icon: Icons.eco,
          label: 'Creciendo, sin frutos',
          subtitle: 'Tiene hojas pero todavia no da fruto ni flores',
          isSelected: _growthStage == GrowthStage.juvenile,
          onTap: () {
            setState(() => _growthStage = GrowthStage.juvenile);
            _updateRecommendation();
          },
        ),
        const SizedBox(height: 8),
        OptionCard(
          icon: Icons.restaurant,
          label: 'Ya da fruto o esta lista',
          subtitle: 'Tiene flores, frutos o se puede cosechar',
          isSelected: _growthStage == GrowthStage.adult,
          onTap: () {
            setState(() => _growthStage = GrowthStage.adult);
            _updateRecommendation();
          },
        ),
      ];
    }

    // Generic plants (indoor, outdoor): human-friendly size question
    return [
      Text('Que tamaño tiene?', style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('No te preocupes si no lo sabes exacto, es orientativo',
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(128))),
      const SizedBox(height: 8),
      OptionCard(
        icon: Icons.grass,
        label: 'Pequeña / recien comprada',
        subtitle: 'Brote, esqueje o planta muy joven',
        isSelected: _growthStage == GrowthStage.seedling,
        onTap: () {
          setState(() => _growthStage = GrowthStage.seedling);
          _updateRecommendation();
        },
      ),
      const SizedBox(height: 8),
      OptionCard(
        icon: Icons.eco,
        label: 'Mediana, esta creciendo',
        subtitle: 'Ya tiene varias hojas pero aun no es grande',
        isSelected: _growthStage == GrowthStage.juvenile,
        onTap: () {
          setState(() => _growthStage = GrowthStage.juvenile);
          _updateRecommendation();
        },
      ),
      const SizedBox(height: 8),
      OptionCard(
        icon: Icons.park,
        label: 'Grande, ya esta crecida',
        subtitle: 'Planta adulta con buen tamaño',
        isSelected: _growthStage == GrowthStage.adult,
        onTap: () {
          setState(() => _growthStage = GrowthStage.adult);
          _updateRecommendation();
        },
      ),
    ];
  }
}








