import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/species_service.dart';
import 'package:planticula/core/services/watering_calculator.dart';
import 'package:planticula/core/services/weather_service.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';

class CreatePlantScreen extends StatefulWidget {
  const CreatePlantScreen({super.key});

  @override
  State<CreatePlantScreen> createState() => _CreatePlantScreenState();
}

class _CreatePlantScreenState extends State<CreatePlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _speciesService = SpeciesService();

  // Step tracking
  int _currentStep = 0;

  // Selected data
  PlantSpecies? _selectedSpecies;
  PlantEnvironment _environment = PlantEnvironment.indoor;
  GrowthStage _growthStage = GrowthStage.adult;

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
    _speciesService.dispose();
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
      final weather = await WeatherService().getWeather(_latitude!, _longitude!);
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

  void _updateRecommendation() {
    if (_selectedSpecies == null) return;
    final rec = WateringCalculator.calculate(
      species: _selectedSpecies!,
      environment: _environment,
      growthStage: _growthStage,
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
            ? 'Que planta tienes?'
            : _currentStep == 2
                ? 'Elige variedad'
                : 'Cuentanos mas'),
        leading: IconButton(
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
      ),
      body: BlocConsumer<PlantsBloc, PlantsState>(
        listener: (context, state) {
          if (state.isOperationSuccess) {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Planta añadida correctamente'),
                behavior: SnackBarBehavior.floating,
              ),
            );
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
          } else {
            return _buildConfiguration(theme, state);
          }
        },
      ),
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
                      return _SpeciesCard(
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
              return _VarietyCard(
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
                  child: _OptionCard(
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
                  child: _OptionCard(
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

            // Smart recommendation preview
            if (_recommendation != null) ...[
              Text('Asi la vamos a cuidar', style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Calculado segun la especie, ubicacion y tamaño',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(128))),
              const SizedBox(height: 8),
              _RecommendationCard(recommendation: _recommendation!),

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
        _OptionCard(
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
        _OptionCard(
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
        _OptionCard(
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
        _OptionCard(
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
        _OptionCard(
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
        _OptionCard(
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
      _OptionCard(
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
      _OptionCard(
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
      _OptionCard(
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

// ===================== Sub-Widgets =====================

class _SpeciesCard extends StatelessWidget {
  final PlantSpecies species;
  final VoidCallback onTap;

  const _SpeciesCard({required this.species, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.local_florist,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(species.commonName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        if (species.hasVarieties) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${species.varieties.length} var.',
                                style: TextStyle(fontSize: 10, color: theme.colorScheme.tertiary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(species.scientificName,
                        style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface.withAlpha(153))),
                  ],
                ),
              ),
              if (species.hasVarieties)
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withAlpha(128)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VarietyCard extends StatelessWidget {
  final PlantSpecies variety;
  final VoidCallback onTap;

  const _VarietyCard({required this.variety, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(variety.commonName,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                  ),
                  // Watering info
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop, size: 14, color: Colors.blue.shade300),
                      const SizedBox(width: 2),
                      Text('${variety.wateringFrequencyIndoor}d',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      Icon(Icons.wb_sunny, size: 14, color: Colors.orange.shade300),
                      const SizedBox(width: 2),
                      Text('${variety.sunlightHoursMin.round()}-${variety.sunlightHoursMax.round()}h',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              if (variety.description != null) ...[
                const SizedBox(height: 6),
                Text(variety.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(179)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              // Temperature range chip
              Wrap(
                spacing: 6,
                children: [
                  _MiniChip(
                    icon: Icons.thermostat,
                    label: '${variety.minTemperature}-${variety.maxTemperature}C',
                    color: Colors.deepOrange,
                  ),
                  if (variety.growthPhases.isNotEmpty && variety.growthPhases.last.description != null)
                    _MiniChip(
                      icon: Icons.timer,
                      label: variety.growthPhases.last.description!,
                      color: Colors.teal,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface.withAlpha(153),
                size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  fontSize: 13,
                )),
            if (subtitle != null)
              Text(subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer.withAlpha(179)
                          : theme.colorScheme.onSurface.withAlpha(102),
                      fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final WateringRecommendation recommendation;

  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Watering frequency
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.water_drop, color: Colors.blue.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riego',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(153))),
                      Text(recommendation.frequencyDescription,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Sunlight
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.wb_sunny, color: Colors.orange.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sol necesario',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(153))),
                      Text(recommendation.sunlightDescription,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
