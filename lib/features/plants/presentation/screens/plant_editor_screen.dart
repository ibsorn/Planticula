import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/location_service.dart';
import 'package:planticula/core/services/plant_identification_service.dart';
import 'package:planticula/core/services/plant_recommendation_service.dart';
import 'package:planticula/core/services/species_service.dart';
import 'package:planticula/core/services/watering_calculator.dart';
import 'package:planticula/core/services/weather_service.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/locations/domain/entities/location.dart';
import 'package:planticula/features/locations/domain/repositories/location_repository.dart';
import 'package:planticula/features/locations/domain/repositories/organization_repository.dart';
import 'package:planticula/features/locations/presentation/widgets/location_icon_mapper.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/presentation/bloc/plants_bloc.dart';
import 'package:planticula/features/plants/presentation/widgets/confidence_indicator.dart';
import 'package:planticula/features/plants/presentation/widgets/environment_selector.dart';
import 'package:planticula/features/plants/presentation/widgets/growth_stage_selector.dart';
import 'package:planticula/features/plants/presentation/widgets/pot_size_selector.dart';
import 'package:planticula/features/plants/presentation/widgets/watering_recommendation_card.dart';

/// Modos de operación del editor
enum PlantEditorMode {
  /// Creación manual - sin datos predefinidos
  manual,

  /// Creación con IA - datos sugeridos con confianza
  aiAssisted,

  /// Edición de planta existente
  edit,
}

/// Pantalla unificada para crear/editar plantas
///
/// Soporta 3 modos:
/// - [manual]: Creación desde cero, todos los valores por defecto
/// - [aiAssisted]: Creación con datos sugeridos por IA, muestra confianza
/// - [edit]: Edición de planta existente, carga datos actuales
///
/// Diseño consistente en todos los modos, solo cambia el origen de los datos.
class PlantEditorScreen extends StatefulWidget {
  /// Modo de operación
  final PlantEditorMode mode;

  /// Planta existente (solo para modo edit)
  final Plant? existingPlant;

  /// Resultado de identificación IA (solo para modo aiAssisted)
  final PlantIdentificationResult? identificationResult;

  /// Imagen capturada (solo para modo aiAssisted)
  final Uint8List? imageBytes;

  const PlantEditorScreen({
    super.key,
    required this.mode,
    this.existingPlant,
    this.identificationResult,
    this.imageBytes,
  }) : assert(
          mode != PlantEditorMode.edit || existingPlant != null,
          'existingPlant is required for edit mode',
        ),
       assert(
          mode != PlantEditorMode.aiAssisted ||
              (identificationResult != null && imageBytes != null),
          'identificationResult and imageBytes are required for aiAssisted mode',
        );

  /// Factory constructor para modo manual
  const PlantEditorScreen.manual({super.key})
      : mode = PlantEditorMode.manual,
        existingPlant = null,
        identificationResult = null,
        imageBytes = null;

  /// Factory constructor para modo IA
  const PlantEditorScreen.aiAssisted({
    super.key,
    required PlantIdentificationResult this.identificationResult,
    required Uint8List this.imageBytes,
  })  : mode = PlantEditorMode.aiAssisted,
        existingPlant = null;

  /// Factory constructor para modo edición
  const PlantEditorScreen.edit({
    super.key,
    required Plant this.existingPlant,
  })  : mode = PlantEditorMode.edit,
        identificationResult = null,
        imageBytes = null;

  @override
  State<PlantEditorScreen> createState() => _PlantEditorScreenState();
}

class _PlantEditorScreenState extends State<PlantEditorScreen> {
  // Services
  final _speciesService = GetIt.instance<SpeciesService>();
  final _weatherService = GetIt.instance<WeatherService>();
  final _locationService = GetIt.instance<LocationService>();
  final _recommendationService = GetIt.instance<PlantRecommendationService>();
  final _organizationRepository = GetIt.instance<OrganizationRepository>();
  final _locationRepository = GetIt.instance<LocationRepository>();

  // Controllers
  final _customNameController = TextEditingController();
  final _searchController = TextEditingController();

  // State
  PlantSpecies? _selectedSpecies;
  PlantEnvironment _environment = PlantEnvironment.indoor;
  GrowthStage _growthStage = GrowthStage.development;
  PotSize _potSize = PotSize.medium;

  // Location assignment (migración 013)
  String? _organizationId;
  List<Location> _locations = const [];
  Location? _selectedLocation;

  // Search
  List<PlantSpecies> _searchResults = [];
  bool _isSearching = false;

  // Location
  double? _latitude;
  double? _longitude;

  // Weather
  WeatherData? _weather;

  // Recommendation
  WateringRecommendation? _recommendation;

  // UI State
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeFromMode();
    _loadSpecies();
    _getLocation();
    _loadLocations();
  }

  /// Inicializa los valores según el modo
  void _initializeFromMode() {
    switch (widget.mode) {
      case PlantEditorMode.manual:
        // Valores por defecto ya establecidos
        break;

      case PlantEditorMode.aiAssisted:
        final result = widget.identificationResult!;
        _selectedSpecies = result.species;
        _environment = result.suggestedEnvironment ?? PlantEnvironment.indoor;
        _growthStage = result.suggestedGrowthStage ?? GrowthStage.development;
        _potSize = result.suggestedPotSize ?? PotSize.medium;
        break;

      case PlantEditorMode.edit:
        final plant = widget.existingPlant!;
        _customNameController.text = plant.customName ?? '';
        _environment = plant.plantEnvironment;
        _growthStage = plant.plantGrowthStage;
        _potSize = plant.plantPotSize;
        // La localización se preselecciona en _loadLocations() una vez
        // disponible el árbol (necesitamos la entidad Location completa).
        break;
    }
  }

  /// Carga el árbol de localizaciones de la organización por defecto y, en
  /// modo edición, preselecciona la localización de la planta existente.
  Future<void> _loadLocations() async {
    final orgResult = await _organizationRepository.getOrCreateDefaultOrganization();
    final org = orgResult.data;
    if (org == null || !mounted) return;
    _organizationId = org.id;

    final result = await _locationRepository.getLocations(org.id);
    if (!mounted) return;
    result.when(
      success: (locations) {
        setState(() => _locations = locations);
        if (widget.mode == PlantEditorMode.edit) {
          final plant = widget.existingPlant!;
          if (plant.locationId != null) {
            final loc =
                locations.where((l) => l.id == plant.locationId).firstOrNull;
            if (loc != null) setState(() => _selectedLocation = loc);
          }
        }
      },
      failure: (_, __, ___) {},
    );
  }

  /// Etiqueta de la ruta completa de una localización (ej. "Vivero A › Zona 2").
  String _locationPath(Location location) {
    final parts = <String>[location.name];
    var current = location;
    while (current.parentId != null) {
      final parent =
          _locations.where((l) => l.id == current.parentId).firstOrNull;
      if (parent == null) break;
      parts.insert(0, parent.name);
      current = parent;
    }
    return parts.join(' › ');
  }

  Future<void> _loadSpecies() async {
    final results = await _speciesService.searchSpecies('');
    if (mounted) {
      setState(() => _searchResults = results);

      // Para modo edición, encontrar la especie actual
      if (widget.mode == PlantEditorMode.edit) {
        final plant = widget.existingPlant!;
        final matchingSpecies = results.where((s) => s.id == plant.speciesId);
        if (matchingSpecies.isNotEmpty) {
          setState(() => _selectedSpecies = matchingSpecies.first);
        }
      }
    }
  }

  Future<void> _getLocation() async {
    if (widget.mode == PlantEditorMode.edit) return; // No necesita ubicación para edición

    final coords = await _locationService.getCurrentCoordinates();
    if (coords == null || !mounted) return;
    setState(() {
      _latitude = coords.latitude;
      _longitude = coords.longitude;
    });
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (_latitude == null || _longitude == null) return;
    try {
      final weather = await _weatherService.getWeather(_latitude!, _longitude!);
      if (mounted) {
        setState(() => _weather = weather);
        _updateRecommendation();
      }
    } catch (_) {}
  }

  void _updateRecommendation() {
    if (_selectedSpecies == null) return;

    setState(() {
      _recommendation = _recommendationService.watering(
        species: _selectedSpecies!,
        environment: _environment,
        growthStage: _growthStage,
        potSize: _potSize,
        weather: _weather,
      );
    });
  }

  Future<void> _save() async {
    if (_selectedSpecies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una especie')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      switch (widget.mode) {
        case PlantEditorMode.manual:
        case PlantEditorMode.aiAssisted:
          // Crear nueva planta
          context.read<PlantsBloc>().add(PlantCreateRequested(
            name: _selectedSpecies!.scientificName ?? _selectedSpecies!.commonName,
            customName: _customNameController.text.trim().isEmpty
                ? null
                : _customNameController.text.trim(),
            speciesId: _selectedSpecies!.id,
            speciesCategory: _selectedSpecies!.category,
            wateringFrequency: _recommendation?.frequencyDays ??
                _selectedSpecies!.getBaseWateringDays(_environment),
            environment: _environment.name,
            growthStage: _growthStage.name,
            potSize: _potSize.dbValue,
            latitude: _latitude,
            longitude: _longitude,
            organizationId: _organizationId,
            locationId: _selectedLocation?.id,
          ));
          break;

        case PlantEditorMode.edit:
          // Actualizar planta existente
          final updatedPlant = widget.existingPlant!.copyWith(
            customName: _customNameController.text.trim().isEmpty
                ? null
                : _customNameController.text.trim(),
            speciesId: _selectedSpecies!.id,
            speciesCategory: _selectedSpecies!.category,
            environment: _environment.name,
            growthStage: _growthStage.name,
            potSize: _potSize.dbValue,
            organizationId: _organizationId,
            locationId: _selectedLocation?.id,
            clearLocationId: _selectedLocation == null,
          );
          context.read<PlantsBloc>().add(PlantUpdateRequested(updatedPlant));
          break;
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.mode == PlantEditorMode.edit
                ? 'Planta actualizada ✏️'
                : '¡Planta añadida! 🌱'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Guardar'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen (solo modo IA)
            if (widget.mode == PlantEditorMode.aiAssisted) ...[
              _buildImagePreview(),
              const SizedBox(height: AppDimens.lg),
            ],

            // Badge de modo IA
            if (widget.mode == PlantEditorMode.aiAssisted) ...[
              _buildAIBadge(),
              const SizedBox(height: AppDimens.lg),
            ],

            // Nombre personalizado
            _buildCustomNameField(),
            const SizedBox(height: AppDimens.lg),

            // Selector de especie
            _buildSpeciesSelector(theme),
            const SizedBox(height: AppDimens.lg),

            // Selector de localización (migración 013)
            _buildLocationSelector(theme),
            const SizedBox(height: AppDimens.lg),

            // Selector de entorno
            _buildEnvironmentSelector(),
            const SizedBox(height: AppDimens.lg),

            // Selector de etapa
            _buildGrowthStageSelector(),
            const SizedBox(height: AppDimens.lg),

            // Selector de maceta
            _buildPotSizeSelector(),
            const SizedBox(height: AppDimens.lg),

            // Recomendación de riego
            if (_recommendation != null) ...[
              _buildRecommendationCard(),
              const SizedBox(height: AppDimens.lg),
            ],

            // Botón guardar grande (al final)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Icon(widget.mode == PlantEditorMode.edit
                        ? Icons.save_outlined
                        : Icons.add_circle_outline),
                label: Text(_getSaveButtonText()),
              ),
            ),

            const SizedBox(height: AppDimens.xl),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.mode) {
      case PlantEditorMode.manual:
        return 'Nueva planta';
      case PlantEditorMode.aiAssisted:
        return 'Revisar identificación';
      case PlantEditorMode.edit:
        return 'Editar planta';
    }
  }

  String _getSaveButtonText() {
    switch (widget.mode) {
      case PlantEditorMode.manual:
      case PlantEditorMode.aiAssisted:
        return 'Añadir planta';
      case PlantEditorMode.edit:
        return 'Guardar cambios';
    }
  }

  // ---------------------------------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.md),
      child: Image.memory(
        widget.imageBytes!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildAIBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.success.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimens.sm),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(
              'La IA ha analizado tu foto. Revisa los datos antes de guardar.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNameField() {
    return TextField(
      controller: _customNameController,
      decoration: const InputDecoration(
        labelText: 'Nombre personalizado (opcional)',
        hintText: 'Ej: Mi tomatera favorita',
        prefixIcon: Icon(Icons.label_outline),
        border: OutlineInputBorder(),
      ),
      maxLength: 50,
    );
  }

  Widget _buildSpeciesSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con indicador de confianza si es modo IA
        Row(
          children: [
            Text(
              'Especie',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.mode == PlantEditorMode.aiAssisted) ...[
              const SizedBox(width: AppDimens.sm),
              ConfidenceIndicator(
                confidence: widget.identificationResult!.speciesConfidence,
                size: ConfidenceSize.small,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimens.sm),

        // Card de especie seleccionada o buscador
        Card(
          child: _selectedSpecies != null
              ? ListTile(
                  leading: _selectedSpecies!.imageUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(_selectedSpecies!.imageUrl!),
                        )
                      : const CircleAvatar(child: Icon(Icons.local_florist)),
                  title: Text(_selectedSpecies!.commonName),
                  subtitle: _selectedSpecies!.scientificName != null
                      ? Text(
                          _selectedSpecies!.scientificName!,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        )
                      : null,
                  trailing: TextButton(
                    onPressed: () => _showSpeciesSearch(),
                    child: const Text('Cambiar'),
                  ),
                )
              : ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.search),
                  ),
                  title: const Text('Buscar especie...'),
                  subtitle: const Text('Selecciona el tipo de planta'),
                  onTap: () => _showSpeciesSearch(),
                ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentSelector() {
    return EnvironmentSelector(
      selectedEnvironment: _environment,
      suggestedEnvironment: widget.mode == PlantEditorMode.aiAssisted
          ? widget.identificationResult!.suggestedEnvironment
          : null,
      suggestionConfidence: widget.mode == PlantEditorMode.aiAssisted
          ? widget.identificationResult!.environmentConfidence
          : null,
      onEnvironmentSelected: (env) {
        setState(() {
          _environment = env;
          _updateRecommendation();
        });
      },
      showConfidenceIndicator: widget.mode == PlantEditorMode.aiAssisted,
    );
  }

  Widget _buildGrowthStageSelector() {
    return GrowthStageSelector(
      selectedStage: _growthStage,
      suggestedStage: widget.mode == PlantEditorMode.aiAssisted
          ? widget.identificationResult!.suggestedGrowthStage
          : null,
      suggestionConfidence: widget.mode == PlantEditorMode.aiAssisted
          ? widget.identificationResult!.growthStageConfidence
          : null,
      onStageSelected: (stage) {
        setState(() {
          _growthStage = stage;
          _updateRecommendation();
        });
      },
      showConfidenceIndicator: widget.mode == PlantEditorMode.aiAssisted,
    );
  }

  Widget _buildPotSizeSelector() {
    return PotSizeSelector(
      selectedSize: _potSize,
      suggestedSize: widget.mode == PlantEditorMode.aiAssisted
          ? widget.identificationResult!.suggestedPotSize
          : null,
      onSizeSelected: (size) {
        setState(() {
          _potSize = size;
          _updateRecommendation();
        });
      },
      showSuggestionIndicator: widget.mode == PlantEditorMode.aiAssisted,
    );
  }

  Widget _buildRecommendationCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendación de riego',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        WateringRecommendationCard(recommendation: _recommendation!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LOCATION SELECTOR
  // ---------------------------------------------------------------------------

  Widget _buildLocationSelector(ThemeData theme) {
    final selected = _selectedLocation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localización (opcional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        Card(
          child: selected != null
              ? ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(selected.colorValue).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LocationIconMapper.forKey(selected.icon),
                      color: Color(selected.colorValue),
                      size: 22,
                    ),
                  ),
                  title: Text(selected.name),
                  subtitle: Text(_locationPath(selected)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'Quitar localización',
                        onPressed: () => setState(() => _selectedLocation = null),
                      ),
                      TextButton(
                        onPressed: _showLocationPicker,
                        child: const Text('Cambiar'),
                      ),
                    ],
                  ),
                )
              : ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    child: Icon(Icons.maps_home_work_outlined,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                  title: const Text('Sin localización'),
                  subtitle: _locations.isEmpty
                      ? const Text('Crea localizaciones desde el menú lateral')
                      : const Text('Selecciona dónde está esta planta'),
                  onTap: _locations.isEmpty ? null : _showLocationPicker,
                ),
        ),
      ],
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            // Lista ordenada en pre-orden (cada nodo seguido de sus hijos) con
            // sangría según la profundidad, para reflejar el árbol.
            final ordered = _orderedLocations();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimens.md),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: AppDimens.md),
                      Text(
                        'Seleccionar localización',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          child: Icon(Icons.close,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5)),
                        ),
                        title: const Text('Sin localización'),
                        subtitle: const Text('La planta quedará sin clasificar'),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _selectedLocation = null);
                        },
                      ),
                      const Divider(height: 1),
                      ...ordered.map((entry) {
                        final loc = entry.location;
                        final isSelected = _selectedLocation?.id == loc.id;
                        return ListTile(
                          contentPadding: EdgeInsets.only(
                            left: AppDimens.md + entry.depth * 20.0,
                            right: AppDimens.md,
                          ),
                          leading: Icon(
                            LocationIconMapper.forKey(loc.icon),
                            color: Color(loc.colorValue),
                          ),
                          title: Text(loc.name,
                              style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400)),
                          subtitle: Text(loc.kind.displayName),
                          trailing: isSelected
                              ? Icon(Icons.check,
                                  color: Theme.of(context).colorScheme.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _selectedLocation = loc);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Devuelve las localizaciones en pre-orden con su profundidad, para
  /// renderizar el árbol como una lista indentada.
  List<({Location location, int depth})> _orderedLocations() {
    final result = <({Location location, int depth})>[];
    void visit(String? parentId, int depth) {
      final children = _locations.where((l) => l.parentId == parentId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final child in children) {
        result.add((location: child, depth: depth));
        visit(child.id, depth + 1);
      }
    }

    visit(null, 0);
    return result;
  }


  // ---------------------------------------------------------------------------
  // SPECIES SEARCH
  // ---------------------------------------------------------------------------

  void _showSpeciesSearch() {
    final searchController = TextEditingController();
    // Pre-cargar con todas las especies ya cargadas (no esperar a que el usuario escriba)
    List<PlantSpecies> results = List.from(_searchResults);
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                // Si al abrir el modal los resultados aún están vacíos (carga lenta),
                // forzar carga desde el servicio.
                if (results.isEmpty && !isSearching) {
                  Future.microtask(() async {
                    setStateDialog(() => isSearching = true);
                    final loaded = await _speciesService.searchSpecies('');
                    if (ctx.mounted) {
                      setStateDialog(() {
                        results = loaded;
                        isSearching = false;
                      });
                    }
                  });
                }

                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(AppDimens.md),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: AppDimens.md),
                          Text(
                            'Seleccionar especie',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar especie...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) async {
                          if (value.isEmpty) {
                            // Sin texto → restaurar lista completa
                            setStateDialog(() => results = List.from(_searchResults));
                            return;
                          }
                          setStateDialog(() => isSearching = true);
                          final found = await _speciesService.searchSpecies(value);
                          setStateDialog(() {
                            results = found;
                            isSearching = false;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: AppDimens.md),

                    // Results
                    Expanded(
                      child: isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : results.isEmpty
                              ? Center(
                                  child: Text(
                                    'No se encontraron especies',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: results.length,
                                  itemBuilder: (context, index) {
                                    final species = results[index];

                                    // Especie con variedades → ExpansionTile expandible
                                    if (species.varieties.isNotEmpty) {
                                      return ExpansionTile(
                                        leading: species.imageUrl != null
                                            ? CircleAvatar(
                                                backgroundImage: NetworkImage(species.imageUrl!),
                                              )
                                            : const CircleAvatar(
                                                child: Icon(Icons.local_florist)),
                                        title: Text(
                                          species.commonName,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text(
                                          '${species.varieties.length} variedades disponibles',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        children: species.varieties.map((variety) {
                                          return ListTile(
                                            contentPadding: const EdgeInsets.only(
                                                left: 72, right: 16),
                                            title: Text(variety.commonName),
                                            subtitle: Text(
                                              variety.scientificName,
                                              style: const TextStyle(
                                                  fontStyle: FontStyle.italic, fontSize: 12),
                                            ),
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              setState(() {
                                                _selectedSpecies = variety;
                                                _updateRecommendation();
                                              });
                                            },
                                          );
                                        }).toList(),
                                      );
                                    }

                                    // Especie sin variedades → ListTile seleccionable directo
                                    return ListTile(
                                      leading: species.imageUrl != null
                                          ? CircleAvatar(
                                              backgroundImage: NetworkImage(species.imageUrl!),
                                            )
                                          : const CircleAvatar(
                                              child: Icon(Icons.local_florist)),
                                      title: Text(species.commonName),
                                      subtitle: Text(
                                        species.scientificName,
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _selectedSpecies = species;
                                          _updateRecommendation();
                                        });
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
